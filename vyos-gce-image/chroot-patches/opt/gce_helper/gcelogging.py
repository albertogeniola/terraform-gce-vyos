import logging
import google.cloud.logging
from google.cloud.logging.handlers import CloudLoggingHandler


log_client = google.cloud.logging.Client()
handler = CloudLoggingHandler(log_client, name="VYOS_GCE_HELPER")
    

# Setup the logging client
def get_logger(logger_name:str, level = logging.INFO):
    cloud_logger = logging.getLogger(logger_name)
    cloud_logger.setLevel(logging.INFO)
    cloud_logger.addHandler(handler)
