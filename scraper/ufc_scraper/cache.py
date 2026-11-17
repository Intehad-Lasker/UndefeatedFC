"""On-disk page cache so re-running the scraper does not re-download pages."""

import hashlib
from collections.abc import Callable
from pathlib import Path

from ufc_scraper.fetcher import PageSource


class CachedFetcher:
    """Wraps another PageSource and keeps every page it fetches on disk.

    Pages for finished events and fighters rarely change, so a second run reads
    them from disk. `refresh` names URLs that must always be re-fetched, such as
    the list of completed events, which grows every week.
    """

    def __init__(
        self,
        source: PageSource,
        cache_dir: Path,
        *,
        refresh: Callable[[str], bool] = lambda url: False,
    ) -> None:
        self._source = source
        self._cache_dir = Path(cache_dir)
        self._refresh = refresh

    def get(self, url: str) -> str:
        path = self.path_for(url)
        if path.exists() and not self._refresh(url):
            return path.read_text(encoding="utf-8")

        body = self._source.get(url)
        path.parent.mkdir(parents=True, exist_ok=True)
        partial = path.with_suffix(".partial")
        partial.write_text(body, encoding="utf-8")
        partial.replace(path)  # atomic, so an interrupted run never leaves half a page
        return body

    def path_for(self, url: str) -> Path:
        digest = hashlib.sha256(url.encode()).hexdigest()
        return self._cache_dir / digest[:2] / f"{digest}.html"
