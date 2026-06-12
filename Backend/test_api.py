import pytest
from fastapi.testclient import TestClient

from api import SessionInfo, create_app
from broadcaster import Broadcaster
from socket_server import TelemetryServer
from telemetry_store import TelemetryStore


class FakeSource:
    path = '/tmp/rocket.csv'
    rate_hz = 50.0
    row_count = 100
    rows_published = 42


HEADERS = ['alt', 'temp', '', 'lat', 'lon', '']
TYPES = ["b'F'", "b'S'"]


@pytest.fixture
def store():
    store = TelemetryStore(HEADERS, TYPES)
    store.ingest_row(["b'F'", '100.5', '21.0', 'pad'], timestamp=1000.0)
    store.ingest_row(["b'F'", '101.0', '20.5', 'pad'], timestamp=1001.0)
    store.ingest_row(["b'S'", '32.9', '78.1', 'pad'], timestamp=1002.0)
    return store


@pytest.fixture
def client(store):
    broadcaster = Broadcaster()
    server = TelemetryServer('127.0.0.1', 0, broadcaster,
                             headers=HEADERS, types=TYPES)
    server.stats.record_frame(3)
    session = SessionInfo(session_id='test-session', started_at=999.0)
    app = create_app(store, server, FakeSource(), session)
    return TestClient(app)


class TestLatest:
    def test_returns_newest_sample_per_channel(self, client):
        response = client.get('/latest')
        assert response.status_code == 200
        channels = response.json()['channels']
        assert channels['alt'] == {'timestamp': 1001.0, 'value': 101.0}
        assert channels['temp'] == {'timestamp': 1001.0, 'value': 20.5}
        assert channels['lat'] == {'timestamp': 1002.0, 'value': 32.9}
        assert channels['lon'] == {'timestamp': 1002.0, 'value': 78.1}

    def test_empty_store_returns_no_channels(self):
        store = TelemetryStore(HEADERS, TYPES)
        broadcaster = Broadcaster()
        server = TelemetryServer('127.0.0.1', 0, broadcaster,
                                 headers=HEADERS, types=TYPES)
        app = create_app(store, server, FakeSource())
        response = TestClient(app).get('/latest')
        assert response.status_code == 200
        assert response.json() == {'channels': {}}


class TestHistory:
    def test_returns_samples_oldest_first(self, client):
        response = client.get('/history', params={'channel': 'alt'})
        assert response.status_code == 200
        body = response.json()
        assert body['channel'] == 'alt'
        assert body['count'] == 2
        assert body['samples'] == [
            {'timestamp': 1000.0, 'value': 100.5},
            {'timestamp': 1001.0, 'value': 101.0},
        ]

    def test_start_end_filters(self, client):
        response = client.get('/history', params={
            'channel': 'alt', 'start': 1000.5, 'end': 1001.5})
        samples = response.json()['samples']
        assert samples == [{'timestamp': 1001.0, 'value': 101.0}]

    def test_limit_keeps_newest(self, client):
        response = client.get('/history',
                              params={'channel': 'alt', 'limit': 1})
        samples = response.json()['samples']
        assert samples == [{'timestamp': 1001.0, 'value': 101.0}]

    def test_unknown_channel_404s(self, client):
        response = client.get('/history', params={'channel': 'nope'})
        assert response.status_code == 404

    def test_channel_param_is_required(self, client):
        assert client.get('/history').status_code == 422


class TestDevices:
    def test_reports_source_and_client_count(self, client):
        response = client.get('/devices')
        assert response.status_code == 200
        body = response.json()
        assert body['client_count'] == 0
        source, = body['sources']
        assert source['type'] == 'csv-replay'
        assert source['rate_hz'] == 50.0
        assert source['rows_published'] == 42


class TestSession:
    def test_reports_metadata_and_counters(self, client):
        response = client.get('/session')
        assert response.status_code == 200
        body = response.json()
        assert body['session_id'] == 'test-session'
        assert body['started_at'] == 999.0
        assert body['channels'] == ['alt', 'temp', 'lat', 'lon']
        assert body['sample_rate_hz'] == 50.0
        assert body['frames_sent'] == 1
        assert body['rows_sent'] == 3
        assert body['connected_clients'] == 0


def test_openapi_docs_are_served(client):
    assert client.get('/docs').status_code == 200
    assert client.get('/openapi.json').status_code == 200
