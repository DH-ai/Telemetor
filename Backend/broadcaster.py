"""Fan-out of telemetry rows to any number of consumers.

Each subscriber gets its own bounded queue carrying the full stream, which
fixes the old shared-queue bug where concurrent clients raced for items.
Slow subscribers lose their *oldest* rows rather than stalling everyone.
"""
import logging
import threading
from queue import Empty, Full, Queue

logger = logging.getLogger(__name__)


class Broadcaster:
    def __init__(self, max_queue_size: int = 10_000):
        self._lock = threading.Lock()
        self._queues: dict[int, Queue] = {}
        self._listeners: list = []
        self._next_id = 0
        self._max_queue_size = max_queue_size
        self.published_count = 0

    def subscribe(self) -> tuple[int, Queue]:
        """Registers a consumer; returns (subscriber_id, its queue)."""
        with self._lock:
            sid = self._next_id
            self._next_id += 1
            queue: Queue = Queue(maxsize=self._max_queue_size)
            self._queues[sid] = queue
        logger.info("subscriber %d added", sid)
        return sid, queue

    def unsubscribe(self, sid: int) -> None:
        with self._lock:
            self._queues.pop(sid, None)
        logger.info("subscriber %d removed", sid)

    def add_listener(self, callback) -> None:
        """Registers a synchronous callback invoked for every published item
        (used by e.g. the REST API's ring buffer)."""
        with self._lock:
            self._listeners.append(callback)

    @property
    def subscriber_count(self) -> int:
        with self._lock:
            return len(self._queues)

    def publish(self, item) -> None:
        with self._lock:
            queues = list(self._queues.values())
            listeners = list(self._listeners)
        self.published_count += 1
        for queue in queues:
            try:
                queue.put_nowait(item)
            except Full:
                # Drop the oldest item to make room; a lagging consumer
                # should not block the stream or other consumers.
                try:
                    queue.get_nowait()
                except Empty:
                    pass
                try:
                    queue.put_nowait(item)
                except Full:
                    logger.debug("dropping row for a saturated subscriber")
        for callback in listeners:
            try:
                callback(item)
            except Exception:
                logger.exception("broadcast listener failed")
