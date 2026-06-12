"""CSV replay data source.

Parses a telemetry CSV (N header rows: each row's first column is a type
tag, the rest are channel names) and replays its data rows into a
Broadcaster at a fixed rate, simulating a live feed.
"""
import csv
import logging
import threading
import time

logger = logging.getLogger(__name__)


def parse_csv_file(path: str, header_rows: int) -> tuple[list, list, list]:
    """Returns (headers, types, data_rows).

    `types` is the first cell of each header row (e.g. "b'F'", "b'S'");
    `headers` is the concatenation of every header row minus its tag cell,
    preserving empty padding columns so data rows stay column-aligned.
    Matches the wire format the original server sent.
    """
    with open(path, newline='') as f:
        rows = list(csv.reader(f))
    if len(rows) < header_rows:
        raise ValueError(
            f"{path}: expected at least {header_rows} header rows, "
            f"found {len(rows)}")
    types = [row[0] for row in rows[:header_rows]]
    headers = [cell for row in rows[:header_rows] for cell in row[1:]]
    return headers, types, rows[header_rows:]


class CsvReplaySource:
    """Replays CSV data rows into a Broadcaster at `rate_hz` rows/second."""

    def __init__(self, path: str, header_rows: int = 2, rate_hz: float = 50.0,
                 loop: bool = False):
        self.path = path
        self.header_rows = header_rows
        self.rate_hz = rate_hz
        self.loop = loop
        self.headers, self.types, self._data_rows = parse_csv_file(
            path, header_rows)
        self.rows_published = 0
        self._thread: threading.Thread | None = None
        logger.info("loaded %s: %d channels, %d data rows",
                    path, len(self.headers), len(self._data_rows))

    @property
    def row_count(self) -> int:
        return len(self._data_rows)

    def start(self, broadcaster, shutdown: threading.Event) -> threading.Thread:
        self._thread = threading.Thread(
            target=self._run, args=(broadcaster, shutdown),
            name='csv-replay', daemon=False)
        self._thread.start()
        return self._thread

    def join(self, timeout: float | None = None) -> None:
        if self._thread is not None:
            self._thread.join(timeout)

    def _run(self, broadcaster, shutdown: threading.Event) -> None:
        period = 1.0 / self.rate_hz if self.rate_hz > 0 else 0.0
        while not shutdown.is_set():
            for row in self._data_rows:
                if shutdown.is_set():
                    break
                broadcaster.publish(row)
                self.rows_published += 1
                if period > 0:
                    # Event.wait doubles as an interruptible sleep.
                    if shutdown.wait(period):
                        break
            if not self.loop:
                break
        logger.info("replay finished after %d rows", self.rows_published)
