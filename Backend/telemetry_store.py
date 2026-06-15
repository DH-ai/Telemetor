"""In-memory telemetry sample store for the REST API.

Subscribes to the Broadcaster (as a listener on the data thread) and keeps
the last `max_samples` samples per channel in ring buffers. Channel/tag
mapping mirrors the Dart client: header names are split evenly across the
type tags; padding columns (empty names) keep their position but store
nothing.
"""
import threading
import time
from collections import deque


class TelemetryStore:
    def __init__(self, headers: list, types: list, max_samples: int = 10_000):
        self._lock = threading.Lock()
        self._groups: dict[str, list[str]] = {}
        if types and len(headers) % len(types) == 0:
            group_size = len(headers) // len(types)
            for i, tag in enumerate(types):
                self._groups[tag] = headers[i * group_size:(i + 1) * group_size]
        elif types:
            self._groups[types[0]] = list(headers)
        self._samples: dict[str, deque] = {
            name.strip(): deque(maxlen=max_samples)
            for group in self._groups.values() for name in group
            if name.strip()
        }

    @property
    def channels(self) -> list:
        with self._lock:
            return list(self._samples.keys())

    def ingest_row(self, row: list, timestamp: float | None = None) -> None:
        """Broadcaster listener: maps one wire row to channel samples."""
        if not row:
            return
        group = self._groups.get(row[0])
        if group is None:
            if len(self._groups) != 1:
                return  # unknown tag, e.g. rocket.csv's stray b'C' row
            group = next(iter(self._groups.values()))
        now = timestamp if timestamp is not None else time.time()
        values = row[1:]
        with self._lock:
            for name, raw in zip(group, values):
                name = name.strip()
                if not name:
                    continue
                try:
                    value = float(raw)
                except (TypeError, ValueError):
                    continue
                self._samples[name].append((now, value))

    def latest(self) -> dict:
        """Newest sample per channel: {channel: {timestamp, value}}."""
        with self._lock:
            return {
                name: {'timestamp': samples[-1][0], 'value': samples[-1][1]}
                for name, samples in self._samples.items()
                if samples
            }

    def history(self, channel: str, start: float | None = None,
                end: float | None = None, limit: int = 1000) -> list | None:
        """Samples for one channel, oldest first; None if unknown channel."""
        with self._lock:
            samples = self._samples.get(channel)
            if samples is None:
                return None
            snapshot = list(samples)
        if start is not None:
            snapshot = [s for s in snapshot if s[0] >= start]
        if end is not None:
            snapshot = [s for s in snapshot if s[0] <= end]
        if limit is not None and limit >= 0:
            snapshot = snapshot[-limit:]
        return [{'timestamp': ts, 'value': value} for ts, value in snapshot]
