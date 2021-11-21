import os.path
import subprocess
import requests
import pathlib
import uuid
import logging


l = logging.getLogger(__name__)


class VyOsAPIClient:
    def __init__(self, key: str, hostname: str, port: int):
        self._key = key
        self._hostname = hostname
        self._port = port

    def load_configuration_from_file(self, file_path: str) -> dict:
        resp = requests.post(url=f"http://{self._hostname}:{self._port}/config-file",
                             data={"op": "load", "file": file_path, "key": self._key})
        l.debug("LOAD-CONFIG API Response [%d]: %s", resp.status_code, str(resp.content))
        if resp.status_code != 200:
            raise RuntimeError(f"Failed to load configuration file. API Response code {resp.status_code}: {resp.content}")
        return resp.json()


def _setup_client(bind_host: str = "localhost", bind_port: int = 8000, api_key: str = None) -> VyOsAPIClient:
    cur_dir = pathlib.Path(__file__).parent.resolve()
    api_setup_path = os.path.join(cur_dir, "command_helper.sh")
    if api_key is None:
        apikey = uuid.uuid4()
    else:
        apikey=api_key
    res = subprocess.run(args=['/usr/bin/vbash', api_setup_path, bind_host, str(bind_port), str(apikey)], shell=False, capture_output=True)
    if res.returncode != 0:
        raise RuntimeError(f"Client setup failed. Process output:\n {res.stdout}. \n\nProcess err:\n {res.stderr}.")
    return VyOsAPIClient(key=apikey, hostname=bind_host, port=bind_port)

api_client = _setup_client()