from telemetry_store import TelemetryStore

HEADERS = ['alt', 'temp', '', 'lat', 'lon', '']
TYPES = ["b'F'", "b'S'"]


def test_channels_skip_padding_columns():
    store = TelemetryStore(HEADERS, TYPES)
    assert store.channels == ['alt', 'temp', 'lat', 'lon']


def test_rows_route_to_their_tag_group():
    store = TelemetryStore(HEADERS, TYPES)
    store.ingest_row(["b'F'", '1.0', '2.0', 'x'], timestamp=1.0)
    store.ingest_row(["b'S'", '3.0', '4.0', 'x'], timestamp=2.0)

    latest = store.latest()
    assert latest['alt']['value'] == 1.0
    assert latest['lat']['value'] == 3.0
    assert 'lon' in latest and latest['lon']['value'] == 4.0


def test_unknown_tag_rows_are_dropped_with_multiple_groups():
    store = TelemetryStore(HEADERS, TYPES)
    store.ingest_row(["b'C'", '9.9'], timestamp=1.0)
    assert store.latest() == {}


def test_single_group_falls_back_for_any_tag():
    store = TelemetryStore(['B', 'C'], ['A'])
    store.ingest_row(['7', '42', '43'], timestamp=1.0)
    latest = store.latest()
    assert latest['B']['value'] == 42.0
    assert latest['C']['value'] == 43.0


def test_non_numeric_values_are_skipped():
    store = TelemetryStore(['v', 'fix', 'alt2'], ["b'S'"])
    store.ingest_row(["b'S'", '0.5', "b'ROV'", '86.0'], timestamp=1.0)
    latest = store.latest()
    assert latest['v']['value'] == 0.5
    assert 'fix' not in latest
    assert latest['alt2']['value'] == 86.0


def test_ring_buffer_caps_history():
    store = TelemetryStore(['B'], ['A'], max_samples=3)
    for i in range(5):
        store.ingest_row(['t', str(i)], timestamp=float(i))

    history = store.history('B', limit=10)
    assert [s['value'] for s in history] == [2.0, 3.0, 4.0]


def test_history_unknown_channel_returns_none():
    store = TelemetryStore(['B'], ['A'])
    assert store.history('nope') is None
