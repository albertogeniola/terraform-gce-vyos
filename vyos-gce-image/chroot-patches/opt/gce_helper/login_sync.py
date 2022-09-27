import logging
import tempfile
import requests
import re
import json
import hashlib
from utils import get_metadata, add_user_to_group
from typing import List, Optional
from vyos_api import get_local_api_client
from requests.exceptions import ReadTimeout
from constants import LOGIN_SYNC_METADATA_TIMEOUT, CFG_GROUP
from datetime import datetime


_CLIENT_ID = "LOGIN_SYNC"

logging.basicConfig(format='login_sync:%(levelname)s:%(message)s', level=logging.INFO)
l = logging.getLogger(__name__)

metadata_instance_key_regex = re.compile('([0-9a-zA-Z_]+):([^ ]+) ([^ ]+) ([^ ]+) ([^ ]+)')
metadata_oslogin_key_regex = re.compile('([^ ]+) ([^ ]+) ([^ ]+)')


class SSHKey:
    def __init__(self, username: str, alg: str, pubkey: str, gcp_username: str, expiration: Optional[datetime] = None):
        self._username = username
        self._alg = alg
        self._pubkey = pubkey
        self._gcp_username = gcp_username
        self._fingerprint = hashlib.md5(pubkey.encode()).hexdigest()
        self._expiration = expiration

    @classmethod
    def parse_from_metadata(cls, metadata_line: str) -> Optional['SSHKey']:
        """Allocates an SSHKey object by parsing the metadata string"""
        match = metadata_instance_key_regex.search(metadata_line)
        if match:
            l.debug("Line matches. Extracting groups.")
            username = match.group(1)
            l.debug("Parsed username: %s", username)
            alg = match.group(2)
            l.debug("Parsed alg: %s", alg)
            pubkey = match.group(3)
            l.debug("Parsed pubkey: %s", pubkey)
            
            google_metadata_str = match.group(5)
            key_metadata = json.loads(google_metadata_str)
            gcp_username = key_metadata["userName"]
            l.debug("Parsed GCP Username: %s", gcp_username)
            expiration = key_metadata["expireOn"]
            expiration = datetime.strptime(expiration, "%Y-%m-%dT%H:%M:%S%z")
            l.debug("Parsed expiration: %s", str(expiration))

            sshkey = SSHKey(username, alg, pubkey, gcp_username, expiration)
            return sshkey
        else:
            l.debug("Regexp does not match for the current line.")
            return None

    @property
    def username(self):
        return self._username

    @property
    def alg(self):
        return self._alg

    @property
    def pubkey(self):
        return self._pubkey
    
    @property
    def gcp_username(self):
        return self._gcp_username
    
    @property
    def fingerprint(self):
        return self._fingerprint

    @property
    def expiration(self) -> Optional[datetime]:
        return self._expiration

    def expired(self):
        return self._expiration is not None and datetime.now() > self._expiration


def get_instance_oslogin_users(wait: bool = True, timeout: int = 60) -> List[SSHKey]:
    """Retrieve the ssh keys from the oslogin instance metadata"""
    res = []
    l.debug("Fetching OS-Login users...")
    # TODO: surf all the users by browsing the page tokens
    raw_data = get_metadata(f"/computeMetadata/v1/oslogin/users", alt="json", wait_for_changes=wait, timeout_sec=timeout, additional_params={"pagesize":"2048"})
    if raw_data is None:
        l.debug("Could not retrieve instance oslogin users.")
        return res
    oslogin_users = json.loads(raw_data)

    # TODO: parse the login profiles.
    for profile in oslogin_users["loginProfiles"]:
        username = None
        # Set the username based on the primary posix account
        for account in profile["posixAccounts"]:
            if account["primary"]:
                l.debug("Selecting username '%s' for login profile %s", account["username"], profile["name"])
                username = account["username"].split("_")[0]
                break
        if username is None:
            l.warning("Could not find a valid username for login profile %s. No SSH Key will be extracted for this user.", profile["name"])
            continue
        # Fetch SSH keys for that username
        for fingerprint, data in profile["sshPublicKeys"].items():
            match = metadata_oslogin_key_regex.search(data['key'])
            if match:
                alg = match.group(1)
                pubkey = match.group(2)
                identifier = match.group(3)
                l.debug("Found SSH key for user %s: %s", username, pubkey)
            res.append(SSHKey(username=username, alg=alg, pubkey=pubkey, gcp_username=username, expiration=None))
    return res


def get_instance_ssh_keys(wait: bool = True, timeout: int = 60) -> List[SSHKey]:
    """Retrieve the ssh keys from the instance metadata"""
    res = []
    instance_ssh_metadata_keys = get_metadata("/computeMetadata/v1/instance/attributes/ssh-keys", alt="text", wait_for_changes=wait, timeout_sec=timeout, error_if_not_found=False)
    if instance_ssh_metadata_keys is None:
        return res
    l.debug("RAW ssh-keys metadata: %s", str(instance_ssh_metadata_keys))
    for line in instance_ssh_metadata_keys.split("\n"):
        l.debug("Processing line %s", line)
        res.append(SSHKey.parse_from_metadata(line))
    l.info("Fetched %d SSH keys from instance metadata.", len(res))
    return res


def is_oslogin_enabled() -> bool:
    """Checks the current status of oslogin at project and instance level"""
    instance_osloginstatus = get_metadata("/computeMetadata/v1/instance/attributes/enable-oslogin", alt="text", wait_for_changes=False, timeout_sec=None, error_if_not_found=False)
    if instance_osloginstatus is None:
        l.debug("Could not retrieve oslogin status from instance.")
    else:
        l.debug("Os Login Status from instance metadata: %s", str(instance_osloginstatus))
        instance_osloginstatus = instance_osloginstatus.upper()=="TRUE"
    
    project_oslogin_metadata = get_metadata("/computeMetadata/v1/project/attributes/enable-oslogin", alt="text", wait_for_changes=False, timeout_sec=None, error_if_not_found=False)
    if project_oslogin_metadata is None:
        l.debug("Could not retrieve oslogin status from project.")
        project_oslogin_metadata = None
    else:    
        l.debug("Os Login Status from project metadata: %s", str(project_oslogin_metadata))
        project_oslogin_metadata = project_oslogin_metadata.upper()=="TRUE"

    return instance_osloginstatus is not None and instance_osloginstatus or instance_osloginstatus is None and project_oslogin_metadata


def main() -> None:
    """Entry point of the utility."""
    l.info("Starting login_sync daemon.")

    # Make sure OSLogin is not set, as VyOS won't work with users managed by OSLogin.
    if is_oslogin_enabled():
        l.error("This instance is being managed via OS-Login. This is not supported at the moment. Please unset os-login from instance metadata or set it to FALSE.")

    api_client = get_local_api_client(_CLIENT_ID)

    while True:
        # Fetch metadata and wait for metadata changes
        try:
            keys = get_instance_ssh_keys(True, LOGIN_SYNC_METADATA_TIMEOUT)
        except requests.exceptions.Timeout:
            # When request times out, it means no update was performed, that is expected.
            l.debug("Timeout occurred when waiting for metadata update.")
            continue

        # TODO: make sure user who is logging can be an admin of the current instance

        # Retrive current api configuration
        current_json_config = api_client.get_config()
        
        # Patch users' keys
        for k in keys:
            # Add the user if does not exist
            config_values={}
            if k.username not in current_json_config["system"]["login"]["user"]:
                l.info("User %s did not exist. It will be allocated.", k.username)
                config_values[("system","login","user")] = k.username
                api_client.set_config_values(config_values)
            else:
                l.debug("User %s did already exist. No need to do anything.", k.username)
                continue


if __name__ == '__main__':
    main()
