import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/telemetry_channel.dart';
import '../models/telemetry_sample.dart';

/// Central distribution point for live telemetry.
///
/// The network layer pushes parsed rows in; widgets subscribe to one
/// broadcast stream per channel and/or watch a latest-value notifier.
/// Everything is event-driven: no polling, no shared queues.
class TelemetryHub {
  TelemetryHub({DateTime Function()? clock}) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;

  final List<TelemetryChannel> _channels = [];
  final Map<String, StreamController<TelemetrySample>> _controllers = {};
  final Map<String, ValueNotifier<TelemetrySample?>> _latest = {};

  /// Channels grouped by wire type tag, preserving declaration order.
  final Map<String, List<TelemetryChannel>> _channelsByType = {};

  /// Notifies listeners when the channel set changes (header packet arrives).
  final ValueNotifier<List<TelemetryChannel>> channelsNotifier =
      ValueNotifier(const []);

  List<TelemetryChannel> get channels => List.unmodifiable(_channels);

  /// Declares the channel set, typically from the stream's header packet.
  /// Existing per-channel streams for channels that survive are kept alive.
  void configure(List<TelemetryChannel> channels) {
    final newNames = channels.map((c) => c.name).toSet();
    for (final old in _channels) {
      if (!newNames.contains(old.name)) {
        _controllers.remove(old.name)?.close();
        _latest.remove(old.name)?.dispose();
      }
    }
    _channels
      ..clear()
      ..addAll(channels);
    _channelsByType.clear();
    for (final channel in channels) {
      _channelsByType.putIfAbsent(channel.type, () => []).add(channel);
    }
    channelsNotifier.value = List.unmodifiable(_channels);
  }

  /// Ingests one parsed data row.
  ///
  /// [typeTag] selects the channel group the values belong to (rows on the
  /// wire start with their group tag, e.g. "b'F'"). When it matches no
  /// known group and exactly one group exists, that group is used, since a
  /// single-group stream's first column is data rather than a tag.
  /// Values that fail numeric parsing (e.g. "b'ROV'") are skipped.
  void ingestRow(String typeTag, List<String> values, {DateTime? timestamp}) {
    var group = _channelsByType[typeTag];
    if (group == null && _channelsByType.length == 1) {
      group = _channelsByType.values.first;
    }
    if (group == null) return;

    final time = timestamp ?? _clock();
    final count = values.length < group.length ? values.length : group.length;
    for (var i = 0; i < count; i++) {
      // Padding columns have empty names; skip them but keep the index
      // alignment between values and channels.
      if (group[i].name.trim().isEmpty) continue;
      final value = double.tryParse(values[i].trim());
      if (value == null) continue;
      _emit(group[i].name, TelemetrySample(timestamp: time, value: value));
    }
  }

  /// Broadcast stream of samples for [channelName].
  /// Safe to call before [configure]; the stream connects once data flows.
  Stream<TelemetrySample> stream(String channelName) =>
      _controllerFor(channelName).stream;

  /// Latest sample on [channelName], null until the first sample arrives.
  ValueNotifier<TelemetrySample?> latest(String channelName) =>
      _latest.putIfAbsent(channelName, () => ValueNotifier(null));

  /// Inject a single sample — used by session replay.
  void injectSample(String channelName, TelemetrySample sample) =>
      _emit(channelName, sample);

  void _emit(String channelName, TelemetrySample sample) {
    _controllerFor(channelName).add(sample);
    latest(channelName).value = sample;
  }

  StreamController<TelemetrySample> _controllerFor(String channelName) =>
      _controllers.putIfAbsent(
          channelName, () => StreamController<TelemetrySample>.broadcast());

  void dispose() {
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
    for (final notifier in _latest.values) {
      notifier.dispose();
    }
    _latest.clear();
    channelsNotifier.dispose();
  }
}
