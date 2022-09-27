from typing import Optional


class VyOSApiException(Exception):
    def __init__(self, status_code: int, error: str = None, data: Optional[dict] = None):
        self._status_code = status_code
        self._error = error
        self._data = data
        super().__init__(self._error)

    @property
    def status_code(self):
        return self._status_code

    @property
    def error(self):
        return self._error

    @property
    def data(self):
        return self._data


class MetadataException(Exception):
    pass