"""TCP telemetry server speaking the frozen ACK protocol (see ACK.md).

Handshake (server-initiated):
    server -> ACK-CONNECT,  client -> ACK-CONNECT
    server -> ACK-EXCHANGE, client -> ACK-EXCHANGE
    server -> HEADERS[...]:TYPES[...], client -> ACK-COMPLETE
Streaming: frames "<batch>::ACK(n)" where <batch> is the str() of a list of
row lists (one or more "[...]" groups); the client answers "::ACK(n)".

Each client runs in its own thread with its own fan-out queue, so every
client receives the full stream. Rows that pile up while a client's ACK
round-trip is in flight are batched into the next frame.
"""
import logging
import socket
import threading
from queue import Empty

logger = logging.getLogger(__name__)

HANDSHAKE_RETRY_LIMIT = 10
SEND_RETRY_LIMIT = 5
CLIENT_SOCKET_TIMEOUT = 5.0
QUEUE_POLL_TIMEOUT = 0.5
MAX_ROWS_PER_FRAME = 50


class SessionStats:
    """Counters exposed to the REST API."""

    def __init__(self):
        self.frames_sent = 0
        self.rows_sent = 0
        self.send_failures = 0
        self._lock = threading.Lock()

    def record_frame(self, row_count: int) -> None:
        with self._lock:
            self.frames_sent += 1
            self.rows_sent += row_count

    def record_failure(self) -> None:
        with self._lock:
            self.send_failures += 1


class ClientSession:
    def __init__(self, sock: socket.socket, address, server: 'TelemetryServer'):
        self.socket = sock
        self.address = address
        self.server = server
        self.thread = threading.Thread(
            target=self._run, name=f'client-{address}', daemon=False)

    def start(self) -> None:
        self.thread.start()

    def _recv_text(self) -> str:
        data = self.socket.recv(1024)
        if not data:
            raise ConnectionError('client closed the connection')
        return data.decode('utf-8')

    def _run(self) -> None:
        logger.info("handling client %s", self.address)
        try:
            self.socket.settimeout(CLIENT_SOCKET_TIMEOUT)
            if self._handshake():
                self._stream()
        except (ConnectionError, OSError) as e:
            logger.info("client %s disconnected: %s", self.address, e)
        except Exception:
            logger.exception("client %s failed", self.address)
        finally:
            self.server.remove_session(self)
            try:
                self.socket.close()
            except OSError:
                pass
            logger.info("client %s closed", self.address)

    def _handshake(self) -> bool:
        self.socket.sendall(b'ACK-CONNECT')
        retries = 0
        while not self.server.shutdown.is_set():
            if retries > HANDSHAKE_RETRY_LIMIT:
                logger.error("client %s: handshake retry limit reached",
                             self.address)
                return False
            try:
                message = self._recv_text()
            except socket.timeout:
                retries += 1
                continue
            logger.debug("client %s sent %r", self.address, message)

            if message == 'ACK-CONNECT':
                self.socket.sendall(b'ACK-EXCHANGE')
            elif message == 'ACK-EXCHANGE':
                header = 'HEADERS{}:TYPES{}'.format(
                    self.server.headers, self.server.types)
                self.socket.sendall(header.encode('utf-8'))
            elif message == 'ACK-COMPLETE':
                logger.info("client %s: handshake complete, streaming",
                            self.address)
                return True
            else:
                logger.warning("client %s: unexpected handshake message %r",
                               self.address, message)
                retries += 1
        return False

    def _stream(self) -> None:
        sid, queue = self.server.broadcaster.subscribe()
        ack_number = 0
        try:
            while not self.server.shutdown.is_set():
                batch = self._next_batch(queue)
                if batch is None:
                    continue
                if not self._send_frame(batch, ack_number):
                    return
                ack_number += 1
        finally:
            self.server.broadcaster.unsubscribe(sid)

    def _next_batch(self, queue) -> list | None:
        """Blocks for the next row, then drains whatever else is queued
        (up to MAX_ROWS_PER_FRAME) into one frame."""
        try:
            batch = [queue.get(timeout=QUEUE_POLL_TIMEOUT)]
        except Empty:
            return None
        while len(batch) < MAX_ROWS_PER_FRAME:
            try:
                batch.append(queue.get_nowait())
            except Empty:
                break
        return batch

    def _send_frame(self, batch: list, ack_number: int) -> bool:
        frame = f'{batch}::ACK({ack_number})'.encode('utf-8')
        expected_ack = f'::ACK({ack_number})'
        for attempt in range(1, SEND_RETRY_LIMIT + 1):
            self.socket.sendall(frame)
            logger.debug("client %s: sent frame %d (%d rows)",
                         self.address, ack_number, len(batch))
            try:
                reply = self._recv_text().strip()
            except socket.timeout:
                logger.warning("client %s: ACK %d timed out (attempt %d)",
                               self.address, ack_number, attempt)
                continue
            if reply == expected_ack:
                self.server.stats.record_frame(len(batch))
                return True
            logger.warning("client %s: expected %s, got %r",
                           self.address, expected_ack, reply)
        self.server.stats.record_failure()
        logger.error("client %s: giving up on frame %d", self.address,
                     ack_number)
        return False


class TelemetryServer:
    def __init__(self, host: str, port: int, broadcaster, headers, types,
                 shutdown: threading.Event | None = None):
        self.host = host
        self.port = port
        self.broadcaster = broadcaster
        self.headers = headers
        self.types = types
        self.shutdown = shutdown or threading.Event()
        self.stats = SessionStats()
        self._server_socket: socket.socket | None = None
        self._accept_thread: threading.Thread | None = None
        self._sessions: list[ClientSession] = []
        self._sessions_lock = threading.Lock()

    @property
    def client_count(self) -> int:
        with self._sessions_lock:
            return len(self._sessions)

    @property
    def bound_port(self) -> int:
        """Actual port (useful when constructed with port 0 in tests)."""
        assert self._server_socket is not None
        return self._server_socket.getsockname()[1]

    def start(self) -> None:
        self._server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self._server_socket.setsockopt(
            socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self._server_socket.bind((self.host, self.port))
        self._server_socket.listen()
        self._server_socket.settimeout(QUEUE_POLL_TIMEOUT)
        logger.info("server listening on %s:%d", self.host, self.bound_port)
        self._accept_thread = threading.Thread(
            target=self._accept_loop, name='accept-loop', daemon=False)
        self._accept_thread.start()

    def _accept_loop(self) -> None:
        while not self.shutdown.is_set():
            try:
                client_socket, address = self._server_socket.accept()
            except socket.timeout:
                continue
            except OSError:
                break  # socket closed during shutdown
            logger.info("connection established with %s", address)
            session = ClientSession(client_socket, address, self)
            with self._sessions_lock:
                self._sessions.append(session)
            session.start()
        logger.debug("accept loop exited")

    def remove_session(self, session: ClientSession) -> None:
        with self._sessions_lock:
            if session in self._sessions:
                self._sessions.remove(session)

    def stop(self) -> None:
        """Thread-safe shutdown: stop accepting, close clients, join threads."""
        self.shutdown.set()
        if self._server_socket is not None:
            try:
                self._server_socket.close()
            except OSError:
                pass
        if self._accept_thread is not None:
            self._accept_thread.join(timeout=5)
        with self._sessions_lock:
            sessions = list(self._sessions)
        for session in sessions:
            try:
                session.socket.shutdown(socket.SHUT_RDWR)
            except OSError:
                pass
            try:
                session.socket.close()
            except OSError:
                pass
        for session in sessions:
            session.thread.join(timeout=5)
        logger.info("server stopped")
