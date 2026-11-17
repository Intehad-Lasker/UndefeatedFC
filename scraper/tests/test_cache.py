from ufc_scraper.cache import CachedFetcher


class CountingSource:
    def __init__(self):
        self.calls = []

    def get(self, url):
        self.calls.append(url)
        return f"<html>{url} #{len(self.calls)}</html>"


def test_fetches_once_then_reads_from_disk(tmp_path):
    source = CountingSource()
    cache = CachedFetcher(source, tmp_path)

    first = cache.get("http://example.test/fighter/1")
    second = cache.get("http://example.test/fighter/1")

    assert first == second
    assert source.calls == ["http://example.test/fighter/1"]


def test_survives_a_new_instance(tmp_path):
    CachedFetcher(CountingSource(), tmp_path).get("http://example.test/a")
    source = CountingSource()

    CachedFetcher(source, tmp_path).get("http://example.test/a")

    assert source.calls == []


def test_refetches_urls_marked_for_refresh(tmp_path):
    source = CountingSource()
    cache = CachedFetcher(source, tmp_path, refresh=lambda url: "events" in url)

    cache.get("http://example.test/events")
    latest = cache.get("http://example.test/events")

    assert len(source.calls) == 2
    assert latest.endswith("#2</html>")


def test_different_urls_get_different_files(tmp_path):
    cache = CachedFetcher(CountingSource(), tmp_path)

    assert cache.path_for("http://example.test/a") != cache.path_for("http://example.test/b")


def test_leaves_no_partial_files(tmp_path):
    CachedFetcher(CountingSource(), tmp_path).get("http://example.test/a")

    assert list(tmp_path.rglob("*.partial")) == []
