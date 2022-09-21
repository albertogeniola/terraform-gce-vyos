import os.path
import subprocess
import requests
import pathlib
import uuid
import logging
import json
from typing import List, Dict, Tuple
from exceptions import VyOSApiException


l = logging.getLogger(__name__)
_api_clients = {}

class VyOsAPIClient:
    def __init__(self, key: str, hostname: str, port: int):
        self._key = key
        self._hostname = hostname
        self._port = port

    def set_config_value(self, config_path: Tuple[str], value: str):
        return self._vyos_post(path="/configure", data_dict={"op": "set", "path": config_path, "value": value})

    def set_config_values(self, config_dict: Dict[Tuple[str], str]):
        return self._vyos_post(path="/configure", data_dict=[
                {"op": "set", "path": path, "value": value} for path,value in config_dict.items()
            ])

    def del_config_value(self, config_path: List[str]):
        return self._vyos_post(path="/configure", data_dict={"op": "delete", "path": config_path})

    def _vyos_post(self, path, data_dict):
        url = f"http://{self._hostname}:{self._port}{path}"
        data = {"data": json.dumps(data_dict), "key": self._key}
        l.debug(f"Invoking VyOS POST API call against {url}, data: {data}")
        resp = requests.post(url=url, data=data)
        
        if resp.status_code < 200 or resp.status_code > 299:
            l.error("API call failed with status code %d", resp.status_code)
            # Try parse the response
            try:
                parsed_data = resp.json()
            except Exception:
                l.error("Unable to parse api error from response")
                raise VyOSApiException(status_code=resp.status_code, error=f"Api call returned non-successful status code: {resp.status_code}")
            raise VyOSApiException(status_code=resp.status_code, error=parsed_data["error"], data=parsed_data["data"])
        else: 
            l.debug(f"Response ({resp.status_code}: {resp.content})")

        # Parse the json response
        parsed_data = resp.json()
        if not parsed_data['success']:
            l.error('The API response returned an error: %s', parsed_data["error"])
            raise VyOSApiException(status_code=resp.status_code, error=parsed_data["error"], data=parsed_data["data"])
        return parsed_data['data']

    def load_configuration_from_file(self, file_path: str) -> dict:
        l.info(f"Loading configuration from {file_path}")
        return self._vyos_post(path=f"/config-file", data_dict={"op": "load", "file": file_path})

    def get_config(self, path: List[str] = []) -> dict:
        l.debug(f"Retrieving vyos current configuration")
        return self._vyos_post(path=f"/retrieve", data_dict={"op": "showConfig", "path": path})


def _setup_client(key_name: str, bind_host: str = "localhost", bind_port: int = 8000, api_key: str = None) -> VyOsAPIClient:
    l.info(f"Initializing vyos api configuration. Binding {bind_host}:{bind_port}")
    cur_dir = pathlib.Path(__file__).parent.resolve()
    api_setup_path = os.path.join(cur_dir, "command_helper.sh")
    if api_key is None:
        apikey = uuid.uuid4()
        l.info("Generating new %s API-KEY for local usage: %s", key_name, apikey)
    else:
        apikey=api_key
        l.info("Configuring %s API-KEY for local usage: %s", key_name, apikey)

    res = subprocess.run(args=['/usr/bin/vbash', api_setup_path, bind_host, str(bind_port), str(apikey), key_name], shell=False, capture_output=True)
    if res.returncode != 0:
        raise RuntimeError(f"Client setup failed. Process output:\n {res.stdout}. \n\nProcess err:\n {res.stderr}.")
    return VyOsAPIClient(key=apikey, hostname=bind_host, port=bind_port)


def get_local_api_client(client_id:str) -> VyOsAPIClient:
    """Builds a new API client with appropriate API keys to be used locally"""
    client = _api_clients.get(client_id)
    if client is None:
        client = _setup_client(api_key=client_id)
        _api_clients[client_id] = client
    return client
        
