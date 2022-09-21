import logging
import tempfile

import requests
from google.cloud import pubsub_v1
from configuration import configuration
from utils import parse_gce_notification, download_gcs_file
from vyos_api import get_local_api_client


_CLIENT_ID = __name__


logging.basicConfig(format='conf_reloader:%(levelname)s:%(message)s', level=logging.INFO)
l = logging.getLogger(__name__)


def callback(message: pubsub_v1.subscriber.message.Message) -> None:
    """Message handler logic."""
    api_client = get_local_api_client(_CLIENT_ID)

    # TODO: handle re-transmissions/duplicates
    l.debug("New pubsub message received: %s", str(message))

    # Retrieve the expected parameters
    try:
        event_type, bucket_id, object_id = parse_gce_notification(message)
    except ValueError as e:
        l.error("Error occurred: %s", str(e))
        return
    finally:
        message.ack()

    # Only handle OBJECT_FINALIZE messages event types.
    if event_type != "OBJECT_FINALIZE":
        l.debug("Skipping this message as its type is different from OBJECT_FINALIZE.")
        return

    # Before acknowledging the message, we first perform a backup of the current configuration,
    # then we try to apply the new desired state.
    with tempfile.NamedTemporaryFile() as tmp:
        try:
            l.info("Fetching new configuration file from gs://%s/%s", bucket_id, object_id)
            download_gcs_file(project_id=configuration.project_id,
                              bucket_id=bucket_id,
                              object_id=object_id,
                              file_obj=tmp)
            tmp.flush()
            l.info("New configuration loaded to %s", tmp.name)
        except:
            l.exception("Failed to download the configuration file from bucket.")
            return
        finally:
            message.ack()

        # Attempt to load the new downloaded configuration.
        try:
            api_client.load_configuration_from_file(file_path=tmp.name)
        except Exception as e:
            l.exception("Failed to apply configuration. Error: %s", str(e))
            return
        finally:
            message.ack()


def main() -> None:
    """Entry point of the application."""
    l.info("Starting conf_reloader daemon.")

    # Subscribe to the pubsub topic where configuration file changes happen
    subscriber = pubsub_v1.SubscriberClient()
    subscription_path = subscriber.subscription_path(configuration.project_id, configuration.pubsub_subscription_path)
    streaming_pull_future = subscriber.subscribe(subscription_path, callback=callback)
    l.info(f"Listening for messages on {subscription_path}.")

    # Wait for new configuration being pushed.
    with subscriber:
        try:
            # The following line will wait indefinitely until a message/exception occurs.
            streaming_pull_future.result()
        except TimeoutError:
            streaming_pull_future.cancel()  # Trigger the shutdown.
            streaming_pull_future.result()  # Block until the shutdown is complete.


if __name__ == '__main__':
    main()
