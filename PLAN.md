# Telemetor Plan

This plan follows `GOALS.md` and `SUMMARY.md`. Goal 1 is complete; the remaining work starts with Goal 2.

## Done

- [x] Goal 1: Frontend rebuild + backend cleanup + REST API
  - [x] Linux backend startup and path cleanup
  - [x] Flutter app refactor into `lib/src/`
  - [x] Event-driven data layer with per-channel streams
  - [x] TCP+ACK transport abstraction and reconnect logic
  - [x] Reusable chart widget with decimation and throttling
  - [x] Runtime dashboard layout, theme toggle, and channel discovery
  - [x] Backend fan-out, batching, shutdown, and CLI cleanup
  - [x] REST API with latest/history/devices/session endpoints
  - [x] Full test and live-end-to-end verification

## Next

- [ ] Goal 2: Transport and config
  - [ ] Add `WebSocketTransport` on the Flutter side
  - [ ] Add a Python WebSocket server endpoint
  - [ ] Introduce YAML config for sources, parsers, and channels
  - [ ] Add a parser interface with CSV-row parsing as the first implementation
  - [ ] Verify the dashboard can switch between TCP and WebSocket by config only

- [ ] Goal 3: Logging, sessions, and replay
  - [ ] Record live sessions to JSONL
  - [ ] Add a session browser screen
  - [ ] Implement replay mode with play/pause, speed control, and seek
  - [ ] Reuse `TelemetryHub` for playback through a clocked data source
  - [ ] Add CSV export for recorded sessions

- [ ] Goal 4: Multi-source and GPS
  - [ ] Add YAML-selected parser plugins for different source types
  - [ ] Plot GPS latitude and longitude as a 2D path
  - [ ] Support multiple simultaneous device connections
  - [ ] Give each source its own hub and visualization state

- [ ] Goal 5: Backlog
  - [ ] Serial, USB, and radio transports
  - [ ] Anomaly detection
  - [ ] Flight prediction
  - [ ] Recording database
  - [ ] Multi-user monitoring
  - [ ] Cloud sync
  - [ ] Ground-station modes

- [ ] Goal 6: Core platform and execution engine
  - [ ] Model each ingestion flow as a DAG
  - [ ] Add a worker pool with bounded queues and aggregation
  - [ ] Define plugin APIs for parsers, transforms, and exporters
  - [ ] Add a parser API with structured validation and errors
  - [ ] Add a memory manager for zero-copy and shared buffers
  - [ ] Add scheduling for backpressure, retries, and cancellation
  - [ ] Rewrite hot paths in Rust where throughput matters

- [ ] Goal 7: SQL, inspection, and dataset diff features
  - [ ] Add SQL-style filtering for telemetry datasets
  - [ ] Add dataset diff views for comparing runs and captures
  - [ ] Add custom scripts through the API for data inspection
  - [ ] Add test and validation runs over recorded or live data
  - [ ] Visualize query, diff, and anomaly output

- [ ] Goal 8: Documentation and domain packs
  - [ ] Create a `/docs` surface for architecture and workflows
  - [ ] Add ML engineer templates for training and model telemetry
  - [ ] Add manufacturing templates for PLC and sensor workflows
  - [ ] Add goal-specific sample configs and dashboards
  - [ ] Add example workflows for compare, inspect, and debug tasks

## Notes

- The TCP+ACK wire protocol stays frozen until Goal 2 changes it.
- Keep future work aligned with the current test gate in `GOALS.md`.
