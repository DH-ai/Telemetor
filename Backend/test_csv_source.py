import os
import threading

import pytest

from broadcaster import Broadcaster
from csv_source import CsvReplaySource, parse_csv_file

BACKEND_DIR = os.path.dirname(os.path.abspath(__file__))
ROCKET_CSV = os.path.join(BACKEND_DIR, 'rocket.csv')


@pytest.fixture
def simple_csv(tmp_path):
    path = tmp_path / 'data.csv'
    path.write_text('A,B,C\n1,2,3\n4,5,6\n7,8,9\n')
    return str(path)


class TestParseCsvFile:
    def test_single_header_row(self, simple_csv):
        headers, types, rows = parse_csv_file(simple_csv, header_rows=1)
        assert types == ['A']
        assert headers == ['B', 'C']
        assert rows == [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']]

    def test_rocket_csv_two_header_groups(self):
        headers, types, rows = parse_csv_file(ROCKET_CSV, header_rows=2)
        assert types == ["b'F'", "b'S'"]
        # Both header rows have the same CSV width, so the name list splits
        # evenly in half - that is what the Dart client relies on.
        assert len(headers) % 2 == 0
        assert ' time' in headers and 'lat(deg)' in headers
        # Padding columns survive so data rows stay aligned.
        assert '' in headers
        assert len(rows) == 4958
        # All rows are tagged; the file ends with one stray b'C' row that
        # clients drop as an unknown group.
        tags = {row[0] for row in rows}
        assert tags == {"b'F'", "b'S'", "b'C'"}

    def test_too_few_rows_raises(self, tmp_path):
        path = tmp_path / 'short.csv'
        path.write_text('A,B\n')
        with pytest.raises(ValueError):
            parse_csv_file(str(path), header_rows=2)


class TestCsvReplaySource:
    def test_publishes_every_row_in_order(self, simple_csv):
        source = CsvReplaySource(simple_csv, header_rows=1, rate_hz=0)
        broadcaster = Broadcaster()
        _, queue = broadcaster.subscribe()
        shutdown = threading.Event()

        source.start(broadcaster, shutdown)
        source.join(timeout=5)

        rows = [queue.get_nowait() for _ in range(queue.qsize())]
        assert rows == [['1', '2', '3'], ['4', '5', '6'], ['7', '8', '9']]
        assert source.rows_published == 3

    def test_shutdown_stops_replay_early(self, simple_csv):
        source = CsvReplaySource(simple_csv, header_rows=1, rate_hz=2)
        broadcaster = Broadcaster()
        shutdown = threading.Event()

        thread = source.start(broadcaster, shutdown)
        shutdown.set()
        thread.join(timeout=5)

        assert not thread.is_alive()
        assert source.rows_published < 3

    def test_loop_mode_repeats_until_shutdown(self, simple_csv):
        source = CsvReplaySource(simple_csv, header_rows=1, rate_hz=0,
                                 loop=True)
        broadcaster = Broadcaster()
        shutdown = threading.Event()

        thread = source.start(broadcaster, shutdown)
        # Give it a moment to loop a few times, then stop it.
        for _ in range(100):
            if source.rows_published > 9:
                break
            threading.Event().wait(0.01)
        shutdown.set()
        thread.join(timeout=5)

        assert not thread.is_alive()
        assert source.rows_published > 9
