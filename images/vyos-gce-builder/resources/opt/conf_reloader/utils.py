from typing import Optional, Tuple
from google.cloud import storage

import requests
from typing.io import TextIO

_METADATA_HOST="http://metadata.google.internal"


def get_metadata(metadata_path: str,
                 alt: str = None,
                 wait_for_changes: Optional[bool] = None,
                 timeout_sec: Optional[int] = None):
    """Fetches metadata from metadata server"""
    params = {}
    if wait_for_changes is not None:
        params["wait_for_change"] = wait_for_changes
    if timeout_sec is not None:
        params["timeout_sec"] = timeout_sec
    if alt is not None:
        params["alt"] = alt
    resp = requests.get(url=f"{_METADATA_HOST}{metadata_path}",
                        params=params,
                        headers={"Metadata-Flavor": "Google"},
                        timeout=timeout_sec)
    return resp.text


def download_gcs_file(project_id: str, bucket_id:str, object_id: str, file_obj: TextIO):
    """Downloads a file from GCS."""
    storage_client = storage.Client(project_id)
    bucket = storage_client.get_bucket(bucket_id)
    blob = bucket.blob(object_id)
    blob.download_to_file(file_obj=file_obj)


def parse_gce_notification(message) -> Tuple[str, str, str]:
    """Parse a GCS notification event."""
    event_type = message.attributes.get("eventType")
    bucket_id = message.attributes.get("bucketId")
    object_id = message.attributes.get("objectId")

    if event_type is None:
        raise ValueError(f"Invalid pubsub message: {message}. No event_type was found within its attributes.")
    if bucket_id is None:
        raise ValueError(f"Invalid pubsub message: {message}. No bucket_id was found within its attributes.")
    if object_id is None:
        raise ValueError(f"Invalid pubsub message: {message}. No object_id was found within its attributes.")

    return event_type, bucket_id, object_id
