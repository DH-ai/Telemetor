"""REST API over the live telemetry stream.

FastAPI app served by uvicorn in a thread beside the socket server, fed by
the TelemetryStore ring buffers. Interactive docs at /docs.
"""
import threading
import time
import uuid
from dataclasses import dataclass, field

import uvicorn
from fastapi import FastAPI, HTTPException, Query


@dataclass
class SessionInfo:
    session_id: str = field(default_factory=lambda: uuid.uuid4().hex)
    started_at: float = field(default_factory=time.time)


def create_app(store, server, source, session: SessionInfo | None = None
               ) -> FastAPI:
    """Builds the API around a TelemetryStore, TelemetryServer and
    CsvReplaySource (the latter two are only read for stats/metadata)."""
    session = session or SessionInfo()
    app = FastAPI(
        title='Telemetor API',
        description='Live telemetry from the TCP streaming backend.',
        version='1.0.0')

    @app.get('/latest')
    def latest():
        """Newest sample per channel."""
        return {'channels': store.latest()}

    @app.get('/history')
    def history(
        channel: str,
        start: float | None = Query(None, description='unix timestamp (s)'),
        end: float | None = Query(None, description='unix timestamp (s)'),
        limit: int = Query(1000, ge=0, le=10_000),
    ):
        """Buffered samples for one channel, oldest first."""
        samples = store.history(channel, start=start, end=end, limit=limit)
        if samples is None:
            raise HTTPException(
                status_code=404, detail=f'unknown channel: {channel}')
        return {'channel': channel, 'count': len(samples),
                'samples': samples}

    @app.get('/devices')
    def devices():
        """Connected data sources and stream consumers."""
        return {
            'sources': [{
                'type': 'csv-replay',
                'path': source.path,
                'rate_hz': source.rate_hz,
                'rows_total': source.row_count,
                'rows_published': source.rows_published,
            }],
            'client_count': server.client_count,
        }

    @app.get('/session')
    def session_info():
        """Current session metadata and stream counters."""
        return {
            'session_id': session.session_id,
            'started_at': session.started_at,
            'channels': store.channels,
            'sample_rate_hz': source.rate_hz,
            'frames_sent': server.stats.frames_sent,
            'rows_sent': server.stats.rows_sent,
            'send_failures': server.stats.send_failures,
            'rows_published': source.rows_published,
            'connected_clients': server.client_count,
        }

    return app


class ApiServer:
    """Runs uvicorn in a daemon-free thread with cooperative shutdown."""

    def __init__(self, app: FastAPI, host: str = '127.0.0.1',
                 port: int = 8000):
        config = uvicorn.Config(app, host=host, port=port,
                                log_level='warning')
        self._server = uvicorn.Server(config)
        self._thread = threading.Thread(
            target=self._server.run, name='api-server', daemon=False)

    def start(self) -> None:
        self._thread.start()

    def stop(self) -> None:
        self._server.should_exit = True
        self._thread.join(timeout=10)
