import 'package:flutter/foundation.dart';

import 'telemetry_hub.dart';

enum DashboardLayout { single, dual, grid }

/// Configuration of one chart tile on the dashboard.
@immutable
class ChartTileConfig {
  const ChartTileConfig({required this.id, required this.channelNames});

  final int id;
  final List<String> channelNames;

  String get title => channelNames.join(' / ');
}

/// Holds the dashboard's runtime state: which chart tiles exist, the
/// layout, and the fullscreen selection. Tiles are seeded automatically
/// from the first header packet and can be added/removed at runtime.
class DashboardController extends ChangeNotifier {
  DashboardController({required this.hub}) {
    hub.channelsNotifier.addListener(_onChannelsChanged);
    _onChannelsChanged();
  }

  final TelemetryHub hub;

  final List<ChartTileConfig> _tiles = [];
  DashboardLayout _layout = DashboardLayout.grid;
  int? _fullscreenTileId;
  int _nextTileId = 0;
  bool _seeded = false;

  List<ChartTileConfig> get tiles => List.unmodifiable(_tiles);

  DashboardLayout get layout => _layout;

  ChartTileConfig? get fullscreenTile {
    if (_fullscreenTileId == null) return null;
    for (final tile in _tiles) {
      if (tile.id == _fullscreenTileId) return tile;
    }
    return null;
  }

  /// Channel names that can be charted (named channels only).
  List<String> get availableChannels => [
        for (final channel in hub.channels)
          if (channel.name.trim().isNotEmpty) channel.name,
      ];

  void _onChannelsChanged() {
    final available = availableChannels.toSet();
    if (available.isEmpty) return;

    // Drop tiles that reference channels gone after a reconfigure.
    _tiles.removeWhere(
        (tile) => tile.channelNames.any((name) => !available.contains(name)));

    // Seed one tile per channel on first discovery so the dashboard is
    // immediately useful; afterwards the tile set is the user's.
    if (!_seeded && _tiles.isEmpty) {
      for (final name in availableChannels) {
        _tiles.add(ChartTileConfig(id: _nextTileId++, channelNames: [name]));
      }
      _seeded = true;
    }
    notifyListeners();
  }

  void addTile(List<String> channelNames) {
    if (channelNames.isEmpty) return;
    _tiles.add(ChartTileConfig(
        id: _nextTileId++, channelNames: List.of(channelNames)));
    notifyListeners();
  }

  void removeTile(int id) {
    _tiles.removeWhere((tile) => tile.id == id);
    if (_fullscreenTileId == id) _fullscreenTileId = null;
    notifyListeners();
  }

  void setLayout(DashboardLayout layout) {
    if (_layout == layout) return;
    _layout = layout;
    notifyListeners();
  }

  void enterFullscreen(int tileId) {
    _fullscreenTileId = tileId;
    notifyListeners();
  }

  void exitFullscreen() {
    if (_fullscreenTileId == null) return;
    _fullscreenTileId = null;
    notifyListeners();
  }

  @override
  void dispose() {
    hub.channelsNotifier.removeListener(_onChannelsChanged);
    super.dispose();
  }
}
