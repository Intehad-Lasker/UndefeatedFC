"""Polite HTTP access to UFCStats: one request at a time, spaced out, with retries."""

import time
from collections.abc import Callable

import requests

DEFAULT_USER_AGENT = "ufc-scraper/0.1"
RETRYABLE_STATUSES = frozenset({429, 500, 502, 503, 504})


class FetchError(RuntimeError):
    """Raised when a page cannot be fetched."""


class Fetcher:
    """Fetches pages at most once every `min_interval` seconds.

    Transient failures (connection errors, 429 and 5xx responses) are retried with
    exponential backoff; anything else fails immediately. The session, clock and
    sleep function are injectable so tests run instantly and offline.
    """

    def __init__(
        self,
        session: requests.Session | None = None,
        *,
        min_interval: float = 1.0,
        max_retries: int = 3,
        backoff: float = 2.0,
        timeout: float = 20.0,
        user_agent: str = DEFAULT_USER_AGENT,
        clock: Callable[[], float] = time.monotonic,
        sleep: Callable[[float], None] = time.sleep,
    ) -> None:
        self._session = session or requests.Session()
        self._session.headers["User-Agent"] = user_agent
        self._min_interval = min_interval
        self._max_retries = max_retries
        self._backoff = backoff
        self._timeout = timeout
        self._clock = clock
        self._sleep = sleep
        self._last_request_at: float | None = None

    def get(self, url: str) -> str:
        last_error: Exception | None = None

        for attempt in range(self._max_retries + 1):
            self._wait_for_turn()
            try:
                response = self._session.get(url, timeout=self._timeout)
            except requests.RequestException as error:
                last_error = error
            else:
                if response.status_code == 200:
                    return response.text
                if response.status_code not in RETRYABLE_STATUSES:
                    raise FetchError(f"{url} returned HTTP {response.status_code}")
                last_error = FetchError(f"{url} returned HTTP {response.status_code}")

            if attempt < self._max_retries:
                self._sleep(self._backoff**attempt)

        attempts = self._max_retries + 1
        raise FetchError(f"giving up on {url} after {attempts} attempts") from last_error

    def _wait_for_turn(self) -> None:
        if self._last_request_at is not None:
            remaining = self._min_interval - (self._clock() - self._last_request_at)
            if remaining > 0:
                self._sleep(remaining)
        self._last_request_at = self._clock()
