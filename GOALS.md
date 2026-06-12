# Telemetor v2 Roadmap

Each Goal is a test phase: it ends with something the user can run and verify by hand.
Work happens on branch `v2`. One commit per milestone, message `G<goal>-M<n>: <summary>`.

## Locked technical decisions (do not re-litigate)

- **Transport**: WebSocket is the primary streaming protocol going forward (works on all
  Flutter platforms incl. web, push-based, simple framing). The existing TCP+ACK protocol
  stays supported behind the same transport interface. gRPC rejected (codegen + no
  grpc-web benefit here); MQTT deferred until multi-device fan-in is needed (broker dependency).
- **Config**: YAML for source/parser/dashboard config (comments + readability beat JSON;
  XML rejected). Package: `yaml`.
- **Charts**: keep `fl_chart`. Cap points fed to a chart at ~2000 via ring buffer +
  LTTB (largest-triangle-three-buckets) decimation; raw data kept separately for export.
- **Performance**: event-driven streams (no polling loops), one broadcast stream per
  channel, `RepaintBoundary` per chart, batch UI updates to ≤30 fps repaint, target
  smooth rendering at 50 Hz input.
- **Storage/replay (Goal 3)**: append-only JSONL session files (one timestamped sample
  per line) — replay = read + playback clock. SQLite/drift only if query needs appear.
- **State management**: plain `Stream`/`ValueNotifier` + `provider`. No bloc/riverpod.
- **Backend API**: FastAPI + uvicorn (async, typed, free OpenAPI docs), run in a thread
  beside the socket server. Tests with pytest + httpx. History served from an in-memory
  ring buffer (last N samples per channel) — disk persistence is Goal 3, not here.
- **Wire protocol**: the TCP+ACK protocol is frozen for Goal 1 (the Dart client depends
  on it). Backend efficiency work must stay wire-compatible; protocol redesign is Goal 2.

## Goal 1 — Frontend rebuild + backend cleanup & REST API (CURRENT)

Today `lib/main.dart` is a 707-line prototype: placeholder widgets, one hardcoded chart,
a 2 s polling loop, dead code. The Python backend streams data but has hardcoded Windows
paths (`D:/...` — won't run on Linux), a shared-queue multi-client bug, `retires` typos,
a hard `serial` import, and no REST API. Rebuild the Flutter side properly; make the
backend correct, efficient, and complete its REST API — without changing the wire protocol.

**Test gate**: `python Backend/serverImp.py` + `flutter run -d linux` → live dashboard
shows all CSV channels graphing in real time; add/remove/resize graphs; light/dark mode;
two clients connected at once both receive the full stream; `curl localhost:8000/latest`
returns current values; `flutter analyze` clean; `flutter test` and `pytest Backend/` pass.

### Milestones

- **G1-M0 Backend runs on Linux**: replace hardcoded `D:/...` paths with paths resolved
  relative to `Backend/`; fix `retires`→`retries` typos; make `serial` a lazy/optional
  import; add `Backend/requirements.txt`; verify the server starts and streams on this
  machine. No protocol or structural changes.
- **G1-M1 Restructure**: split `main.dart` into `lib/src/{models,network,data,charts,screens,theme}/`.
  Delete dead code (`temp.dart`, `temp-server.dart`, commented blocks, debug prints).
  Behavior unchanged. `flutter analyze` clean.
- **G1-M2 Data layer**: `TelemetryChannel` (name, type, unit) and `TelemetrySample`
  (timestamp, value) models. `TelemetryHub` that ingests parsed packets and exposes one
  broadcast stream per channel + a latest-value `ValueNotifier`. Replace the global
  `dataQueue` + 2 s polling loop with event-driven push. Unit tests.
- **G1-M3 Network layer**: abstract `TelemetryTransport` interface (connect/disconnect,
  state stream, packet stream). `TcpAckTransport` implements the existing ACK handshake
  (see `Backend/ACK.md`, `Backend/serverImp.py`) with: connection state machine, auto-reconnect
  w/ exponential backoff, timeouts, host/port configurable at runtime (settings dialog),
  proper error surfacing. Unit tests with a fake socket.
- **G1-M4 Chart widget**: one reusable `TelemetryChart` replacing Altitude/Temperature/
  Velocity/Acceleration/Gyroscope stubs. Props: channels (multi-series), title, unit,
  legend, color palette, sliding time window, auto-scaling axes. Internals: ring buffer,
  LTTB decimation to ≤2000 points, `RepaintBoundary`, repaint throttled to ≤30 fps.
  Widget tests.
- **G1-M5 Dashboard**: channels auto-discovered from the stream's header packet; user can
  add/remove chart tiles per channel at runtime (nothing hardcoded). Layouts: single,
  dual, grid, fullscreen-a-chart. Status bar (connection state, packet rate, dropped
  packets). Stat tiles for latest values. Material 3 light/dark theme with toggle.
- **G1-M6 Verify & polish**: run end-to-end against the Python server with `rocket.csv`;
  fix what breaks; perf pass (const ctors, no rebuild storms — verify with DevTools
  rebuild stats if available, otherwise by code review); update `REAMDME.md` → rename to
  `README.md` with run instructions; update `PLAN.md` checkboxes.
- **G1-M7 Backend efficiency & correctness** (wire-compatible — the M3 Dart client must
  keep working unchanged): per-client fan-out queues so N clients each get the full
  stream (fixes the documented shared-queue inconsistency); thread-safe shutdown on
  SIGINT/SIGTERM (close clients, join threads, no orphan daemons); blocking queue gets
  instead of sleep-polling loops; host/port/csv-path/sample-rate via argparse with the
  current values as defaults; replace the per-row stop-and-wait send with batched rows
  per ACK frame (the frame format already supports multiple `[...]` groups); proper log
  levels (packet-level chatter → DEBUG); split `serverImp.py` into modules if it helps,
  keep entry point `python Backend/serverImp.py`. Unit tests for the fan-out and parser.
- **G1-M8 REST API**: `Backend/api.py`, FastAPI on port 8000, fed by an in-memory ring
  buffer (last ~10k samples per channel) that the data thread populates alongside the
  socket stream. Endpoints: `GET /latest` (newest sample per channel), `GET /history?
  channel=&start=&end=&limit=` (from ring buffer), `GET /devices` (connected sources +
  client count), `GET /session` (current session id, start time, channels, sample rate,
  packet/drop counts). JSON responses, OpenAPI docs at `/docs`, pytest+httpx tests for
  every endpoint.

## Goal 2 — Transport & config

`WebSocketTransport` + Python `websockets` server endpoint; YAML config file defining
sources (type, host, port, parser, channels); parser interface in Dart (bytes/text →
samples) with CSV-row parser as first impl. Test gate: same dashboard runs over WebSocket
or TCP purely by editing config.

## Goal 3 — Logging, sessions, replay

Record every live session to JSONL; session browser screen; replay mode driving the same
`TelemetryHub` through a playback clock (play/pause, 0.25–8× speed, seek); CSV export.
Test gate: record a flight, close app, reopen, replay it, export CSV.

## Goal 4 — Multi-source & GPS

Parser plugins selected via YAML (rocket/drone/custom); GPS lat/lon plotted as 2D path
(no map tiles); multiple simultaneous device connections, each its own hub.
Test gate: two servers streaming different schemas visualized at once.

## Goal 5 — Backlog (not scheduled)

Serial/USB/radio transports, anomaly detection, flight prediction, recording database,
multi-user monitoring, cloud sync, ground-station modes.
