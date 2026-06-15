# Telemetor

Real-time telemetry visualizer: a Flutter dashboard streaming live data from a
Python test backend over a TCP+ACK protocol (see `Backend/ACK.md`).

The dashboard auto-discovers channels from the stream's header packet, charts
them live (sliding window, LTTB decimation, ≤30 fps repaints), and lets you
add/remove/fullscreen chart tiles at runtime. Material 3 light/dark theme.

## Requirements

- Flutter (stable channel) with Linux desktop support
- Python 3.11+

## Run it

Backend (terminal 1):

```bash
cd Backend
python -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python serverImp.py
```

App (terminal 2):

```bash
flutter pub get
flutter run -d linux
```

The app connects to `127.0.0.1:12345` by default; change host/port at runtime
via the settings (gear) icon. The status bar at the bottom shows connection
state, rows/s, total rows and dropped frames.

## Tests

```bash
flutter analyze
flutter test            # unset http_proxy/https_proxy if a local proxy runs
.venv/bin/python -m pytest Backend/
```

## Project layout

- `lib/src/models/` – `TelemetryChannel`, `TelemetrySample`
- `lib/src/network/` – transport interface, TCP+ACK implementation, wire parser
- `lib/src/data/` – `TelemetryHub` (per-channel broadcast streams), dashboard
  state, stream statistics, ring buffer
- `lib/src/charts/` – reusable `TelemetryChart` (fl_chart + LTTB)
- `lib/src/screens/` – dashboard, dialogs
- `Backend/` – Python socket server, CSV-to-JSON parser, sample flight data
  (`rocket.csv`)

Roadmap and milestone log: see `GOALS.md`.
