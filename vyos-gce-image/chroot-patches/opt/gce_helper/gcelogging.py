import logging
import google.cloud.logging
from google.cloud.logging.handlers import CloudLoggingHandler


def setup_logging(root_level=logging.INFO, cloud_handler_level=logging.INFO, formatter_string='%(name)s - %(message)s'):
    log_client = google.cloud.logging.Client()
    handler = CloudLoggingHandler(log_client)
    root_logger = logging.getLogger()
    root_logger.setLevel(root_level)
    formatter = logging.Formatter(formatter_string)
    handler.setFormatter(formatter)
    handler.setLevel(cloud_handler_level)
    root_logger.addHandler(handler)
