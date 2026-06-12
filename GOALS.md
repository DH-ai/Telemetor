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

## Goal 1 — Frontend rebuild (CURRENT)

Today `lib/main.dart` is a 707-line prototype: placeholder widgets, one hardcoded chart,
a 2 s polling loop, dead code. Rebuild the Flutter side properly. Backend (`Backend/serverImp.py`
+ `Backend/rocket.csv`) is the test harness — do not rewrite it in this goal.

**Test gate**: `python Backend/serverImp.py` + `flutter run -d linux` → live dashboard
shows all CSV channels graphing in real time; add/remove/resize graphs; light/dark mode;
`flutter analyze` clean; `flutter test` passes.

### Milestones

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
