import re
import socket
import threading
import time

import pytest

from broadcaster import Broadcaster
from socket_server import TelemetryServer

FRAME_PATTERN = re.compile(r'(.*?)::ACK\((\d+)\)', re.DOTALL)
ROW_PATTERN = re.compile(r'\[(.*?)\]')

HEADERS = ['B', 'C']
TYPES = ['A']


class AckClient:
    """Minimal client speaking the frozen TCP+ACK protocol."""

    def __init__(self, port):
        self.sock = socket.create_connection(('127.0.0.1', port), timeout=5)
        self.sock.settimeout(5)
        self.buffer = ''
        self.header_message = None
        self.frames = []  # list of (ack_number, row_count)

    def _recv(self) -> str:
        data = self.sock.recv(4096)
        if not data:
            raise ConnectionError('server closed')
        return data.decode('utf-8')

    def handshake(self):
        assert self._recv() == 'ACK-CONNECT'
        self.sock.sendall(b'ACK-CONNECT')
        assert self._recv() == 'ACK-EXCHANGE'
        self.sock.sendall(b'ACK-EXCHANGE')
        self.header_message = self._recv()
        assert self.header_message.startswith('HEADERS')
        self.sock.sendall(b'ACK-COMPLETE')

    def read_frame(self, send_ack=True):
        """Reads one complete frame; returns the list of parsed rows."""
        while True:
            match = FRAME_PATTERN.search(self.buffer)
            if match:
                break
            self.buffer += self._recv()
        self.buffer = self.buffer[match.end():]
        payload, ack_number = match.group(1), int(match.group(2))
        inner = payload.strip()[1:-1]  # strip the outer list brackets
        rows = ROW_PATTERN.findall(inner)
        self.frames.append((ack_number, len(rows)))
        if send_ack:
            self.ack(ack_number)
        return rows

    def ack(self, number):
        self.sock.sendall(f'::ACK({number})'.encode())

    def close(self):
        self.sock.close()


@pytest.fixture
def server():
    broadcaster = Broadcaster()
    srv = TelemetryServer('127.0.0.1', 0, broadcaster,
                          headers=HEADERS, types=TYPES)
    srv.start()
    yield srv, broadcaster
    srv.stop()


def wait_for(predicate, timeout=5.0):
    deadline = time.monotonic() + timeout
    while time.monotonic() < deadline:
        if predicate():
            return True
        time.sleep(0.01)
    return False


def test_handshake_and_header_format(server):
    srv, _ = server
    client = AckClient(srv.bound_port)
    client.handshake()
    assert client.header_message == "HEADERS['B', 'C']:TYPES['A']"
    client.close()


def test_rows_stream_with_sequential_acks(server):
    srv, broadcaster = server
    client = AckClient(srv.bound_port)
    client.handshake()
    assert wait_for(lambda: broadcaster.subscriber_count == 1)

    for i in range(3):
        broadcaster.publish([str(i), 'x'])
        rows = client.read_frame()
        assert rows == [f"'{i}', 'x'"]

    acks = [number for number, _ in client.frames]
    assert acks == [0, 1, 2]
    client.close()


def test_rows_queued_during_ack_roundtrip_are_batched(server):
    srv, broadcaster = server
    client = AckClient(srv.bound_port)
    client.handshake()
    assert wait_for(lambda: broadcaster.subscriber_count == 1)

    broadcaster.publish(['0'])
    client.read_frame(send_ack=False)  # hold the ACK back

    for i in range(1, 10):
        broadcaster.publish([str(i)])
    assert wait_for(lambda: srv.broadcaster.published_count == 10)
    client.ack(client.frames[-1][0])  # release the server

    received = sum(count for _, count in client.frames)
    while received < 10:
        received += len(client.read_frame())

    assert received == 10
    # The rows that piled up during the round-trip came as one frame.
    assert max(count for _, count in client.frames) > 1
    client.close()


def test_two_clients_both_receive_the_full_stream(server):
    srv, broadcaster = server
    first = AckClient(srv.bound_port)
    second = AckClient(srv.bound_port)
    first.handshake()
    second.handshake()
    assert wait_for(lambda: broadcaster.subscriber_count == 2)
    assert srv.client_count == 2

    for i in range(5):
        broadcaster.publish([str(i)])

    def collect(client):
        rows = []
        while len(rows) < 5:
            rows.extend(client.read_frame())
        return rows

    expected = [f"'{i}'" for i in range(5)]
    assert collect(first) == expected
    assert collect(second) == expected
    first.close()
    second.close()


def test_disconnected_client_is_cleaned_up(server):
    srv, broadcaster = server
    client = AckClient(srv.bound_port)
    client.handshake()
    assert wait_for(lambda: broadcaster.subscriber_count == 1)

    client.close()
    broadcaster.publish(['1'])  # wakes the sender, which then notices

    assert wait_for(lambda: srv.client_count == 0)
    assert wait_for(lambda: broadcaster.subscriber_count == 0)


def test_stop_joins_all_threads_and_frees_the_port():
    broadcaster = Broadcaster()
    srv = TelemetryServer('127.0.0.1', 0, broadcaster,
                          headers=HEADERS, types=TYPES)
    srv.start()
    port = srv.bound_port
    client = AckClient(port)
    client.handshake()
    assert wait_for(lambda: srv.client_count == 1)

    srv.stop()

    assert threading.active_count() < 10  # no orphan daemons piling up
    with pytest.raises((ConnectionRefusedError, socket.timeout, OSError)):
        socket.create_connection(('127.0.0.1', port), timeout=0.5)
    client.close()
