import 'dart:collection';

/// Global buffer between the network layer and the UI.
///
/// The network layer pushes raw data-row strings here and the UI polls it.
/// This is prototype plumbing: G1-M2 replaces it with an event-driven
/// TelemetryHub.
final Queue<String> dataQueue = Queue<String>();
