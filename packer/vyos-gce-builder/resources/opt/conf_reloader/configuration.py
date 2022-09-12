import requests

from utils import get_metadata


class Configuration:
    def __init__(self,
                 project_id: str,
                 pubsub_subscription: str):
        """Constructor."""
        self._project_id = project_id
        self._pubsub_subscription_path = pubsub_subscription

    @property
    def project_id(self):
        """Project-id where this daemon is running on."""
        return self._project_id

    @property
    def pubsub_subscription_path(self):
        """Pubsub topic where to listen for configuration updates."""
        return self._pubsub_subscription_path

    @staticmethod
    def load_from_metadata() -> 'Configuration':
        """Loads the configuration from instance metadata"""
        project_id = str(get_metadata(metadata_path="/computeMetadata/v1/project/project-id", alt="text"))
        pubsub_subscription = str(get_metadata(metadata_path="/computeMetadata/v1/instance/attributes/pubsub-subscription", alt="text"))

        return Configuration(project_id=project_id,
                             pubsub_subscription=pubsub_subscription)

    def __repr__(self):
        return self.__dict__


configuration = Configuration.load_from_metadata()
