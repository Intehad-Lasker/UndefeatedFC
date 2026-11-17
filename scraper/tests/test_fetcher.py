from dataclasses import dataclass, field

import pytest
import requests

from ufc_scraper.fetcher import Fetcher, FetchError


@dataclass
class Response:
    status_code: int
    text: str = ""


@dataclass
class FakeSession:
    """Plays back queued responses (or exceptions) and records requested URLs."""

    replies: list
    headers: dict = field(default_factory=dict)
    urls: list = field(default_factory=list)

    def get(self, url, timeout):
        self.urls.append(url)
        reply = self.replies.pop(0)
        if isinstance(reply, Exception):
            raise reply
        return reply


class FakeClock:
    def __init__(self):
        self.now = 0.0
        self.sleeps = []

    def __call__(self):
        return self.now

    def sleep(self, seconds):
        self.sleeps.append(seconds)
        self.now += seconds


def make_fetcher(replies, **options):
    clock = FakeClock()
    session = FakeSession(replies)
    fetcher = Fetcher(session, clock=clock, sleep=clock.sleep, **options)
    return fetcher, session, clock


def test_returns_the_page_body():
    fetcher, session, _ = make_fetcher([Response(200, "<html>ok</html>")])

    assert fetcher.get("http://example.test/a") == "<html>ok</html>"
    assert session.urls == ["http://example.test/a"]


def test_sends_a_user_agent():
    _, session, _ = make_fetcher([], user_agent="test-agent")

    assert session.headers["User-Agent"] == "test-agent"


def test_spaces_requests_by_the_minimum_interval():
    fetcher, _, clock = make_fetcher([Response(200), Response(200)], min_interval=1.5)

    fetcher.get("http://example.test/a")
    clock.now += 0.5
    fetcher.get("http://example.test/b")

    assert clock.sleeps == [1.0]


def test_does_not_wait_when_enough_time_has_passed():
    fetcher, _, clock = make_fetcher([Response(200), Response(200)], min_interval=1.0)

    fetcher.get("http://example.test/a")
    clock.now += 5
    fetcher.get("http://example.test/b")

    assert clock.sleeps == []


def test_retries_server_errors_with_exponential_backoff():
    replies = [Response(503), Response(502), Response(200, "finally")]
    fetcher, session, clock = make_fetcher(replies, min_interval=0, backoff=2.0)

    assert fetcher.get("http://example.test/a") == "finally"
    assert len(session.urls) == 3
    assert clock.sleeps == [1.0, 2.0]


def test_retries_connection_errors():
    replies = [requests.ConnectionError("reset"), Response(200, "ok")]
    fetcher, _, _ = make_fetcher(replies, min_interval=0)

    assert fetcher.get("http://example.test/a") == "ok"


def test_does_not_retry_client_errors():
    fetcher, session, _ = make_fetcher([Response(404)], min_interval=0)

    with pytest.raises(FetchError, match="HTTP 404"):
        fetcher.get("http://example.test/missing")
    assert len(session.urls) == 1


def test_gives_up_after_the_last_retry():
    fetcher, session, _ = make_fetcher([Response(503)] * 3, min_interval=0, max_retries=2)

    with pytest.raises(FetchError, match="after 3 attempts"):
        fetcher.get("http://example.test/a")
    assert len(session.urls) == 3
