# Goal 1 Summary (v2 branch)

All nine milestones G1-M0 through G1-M8 are complete, one commit per
milestone (`G1-M<n>: <summary>`). The TCP+ACK wire protocol
(`Backend/ACK.md`) was kept frozen throughout: the G1-M3 Dart client and the
G1-M7 rewritten server interoperate in both directions, verified live.

## What was done

### Frontend (Flutter, `lib/src/`)

- **G1-M1** split the 707-line prototype `main.dart` into
  `models / network / data / charts / screens / theme` modules and deleted
  dead files (`temp.dart`, `temp-server.dart`, `socket-impl.dart`,
  `csv_parser.dart`).
- **G1-M2** added `TelemetryChannel` / `TelemetrySample` models and
  `TelemetryHub`: one broadcast stream per channel plus latest-value
  `ValueNotifier`s, fed event-driven (the old global queue and 2 s polling
  loop are gone).
- **G1-M3** added the abstract `TelemetryTransport` and `TcpAckTransport`:
  connection state machine, auto-reconnect with exponential backoff
  (1 s → 30 s), connect/handshake timeouts, receive buffering for frames
  split/merged by TCP, error stream, and runtime host/port (settings
  dialog). Sockets are abstracted (`TransportSocket`) for fake-driven tests.
- **G1-M4** added the reusable `TelemetryChart`: multi-series, legend,
  units, sliding time window, auto-scaling axes; internally an 8k-sample
  ring buffer per series, LTTB decimation to ≤2000 points, RepaintBoundary,
  repaints throttled to ≤30 fps.
- **G1-M5** built the dashboard: channels auto-discovered from the header
  packet, seeded one tile per channel, add/remove/fullscreen tiles at
  runtime, single/dual/grid layouts, stat-tile strip (latest values), a
  status bar (connection state, endpoint, rows/s, total rows, dropped
  frames via ACK-gap tracking), and Material 3 light/dark themes (teal
  seed `#1CCC9D`) with a toggle.
- **G1-M6** fixed what the real dataset broke: multi-group headers
  (`b'F'` + `b'S'`) now split evenly across tags, padding columns keep
  column alignment, non-numeric values (e.g. `b'ROV'`) are skipped.

### Backend (Python, `Backend/`)

- **G1-M0** made the server run on Linux: hardcoded `D:/` paths replaced
  with `os.path` relative resolution, `retires` typos fixed, `serial`
  import made lazy, `requirements.txt` pinned (fastapi 0.136.3,
  uvicorn 0.49.0, pytest 9.0.3, httpx 0.28.1).
- **G1-M7** rewrote the backend wire-compatibly: `broadcaster.py`
  (per-client fan-out queues — N clients each get the full stream),
  `csv_source.py` (CSV replay at `--rate` rows/s, interruptible waits),
  `socket_server.py` (same handshake; rows queued during an ACK round-trip
  are batched into one frame, up to 50; `sendall` fixes truncation of large
  frames), and `serverImp.py` as a thin entry point with argparse
  (`--host --port --csv --rate --header-rows --loop --api-port -v`) and
  SIGINT/SIGTERM shutdown that joins every thread.
- **G1-M8** added the REST API on port 8000 (`api.py`,
  `telemetry_store.py`): `/latest`, `/history?channel=&start=&end=&limit=`,
  `/devices`, `/session`, OpenAPI docs at `/docs`. Per-channel ring buffers
  (10k samples) are filled via a broadcaster listener on the data thread;
  uvicorn runs in a thread beside the socket server and shuts down with it.

## What was tested

- **Automated, all green at every commit:**
  - `flutter analyze` — zero issues.
  - `flutter test` — 68 tests: hub routing/fan-out/lifecycle, wire parser,
    transport (fake sockets: handshake, timeout retry, split/merged frames,
    reconnect, disconnect, setEndpoint), ring buffer, LTTB properties,
    chart widget (window pruning, decimation cap, repaint throttling),
    dashboard controller, stream stats, dashboard widget flows incl. theme
    toggle.
  - `pytest Backend/` — 34 tests: broadcaster fan-out/drop-oldest/listeners,
    CSV parsing (incl. real `rocket.csv`), replay lifecycle, the full ACK
    protocol over real sockets (batching, two concurrent clients,
    disconnect cleanup, shutdown/port release), telemetry store mapping,
    and every REST endpoint incl. 404/422 paths.
- **Live end-to-end on Linux desktop (screenshots taken):**
  - `python Backend/serverImp.py` (defaults: `rocket.csv`, 50 Hz) +
    `flutter run -d linux`: all 30 named channels auto-discovered from both
    header groups, charts stream in real time at ~49.6 rows/s, 0 dropped.
  - Two concurrent clients (Flutter app + `tempclient.py`): both receive
    the full stream; `/devices` reported `client_count: 2`.
  - `curl localhost:8000/latest|/history|/devices|/session` return live
    flight data; `/docs` serves.
  - SIGTERM → "server stopped … bye", process exits, ports freed.

## Assumptions made

- **INPUTS defaults** (left unfilled in PROMPT.md): Linux desktop as the
  test platform; theme color teal `#1CCC9D` (the prototype's accent);
  50 Hz sample data rate; no UI to preserve.
- The old random-data simulation (`populate_csv` writing
  `csv-temp/data.csv`) was superseded by replaying `rocket.csv` — the
  server's default stream is now real flight data at 50 Hz
  (`--csv`/`--rate`/`--header-rows` configurable, `--loop` to repeat).
- Multi-group headers are split evenly across type tags (both header rows
  in `rocket.csv` have the same CSV width); the stray trailing `b'C'` row
  is dropped as an unknown group.
- `rocket.csv`'s GPS `type` column (`b'ROV'`) and other non-numeric values
  are not chartable and are skipped per-sample.
- Sample timestamps are client-arrival times (the wire protocol carries no
  timestamps); the REST store stamps rows server-side the same way.
- `flutter test` must run with `http_proxy`/`https_proxy` unset on this
  machine — the local proxy (127.0.0.1:8118) breaks the test harness's
  loopback WebSocket. `flutter analyze`/`flutter test`/`pytest` themselves
  are unaffected otherwise.

## Known limitations / next steps (Goal 2+)

- WebSocket transport (the locked end-state) is not yet implemented; the
  frozen TCP+ACK protocol remains the only transport.
- YAML dashboard config save/load and JSONL session recording are future
  goals (deps `yaml`/`provider` are already in place).
- Chart x-axes show a relative sliding window; flight-time axes would need
  protocol timestamps.
