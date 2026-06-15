import 'package:flutter_test/flutter_test.dart';
import 'package:telemetor/src/data/dashboard_controller.dart';
import 'package:telemetor/src/data/telemetry_hub.dart';
import 'package:telemetor/src/models/telemetry_channel.dart';

void main() {
  late TelemetryHub hub;
  late DashboardController controller;

  setUp(() {
    hub = TelemetryHub();
    controller = DashboardController(hub: hub);
  });

  tearDown(() {
    controller.dispose();
    hub.dispose();
  });

  test('seeds one tile per channel on first discovery', () {
    hub.configure(const [
      TelemetryChannel(name: 'alt', type: 'F'),
      TelemetryChannel(name: 'temp', type: 'F'),
      TelemetryChannel(name: '', type: 'F'), // unnamed filler column
    ]);

    expect(controller.tiles.length, 2);
    expect(controller.tiles[0].channelNames, ['alt']);
    expect(controller.tiles[1].channelNames, ['temp']);
    expect(controller.availableChannels, ['alt', 'temp']);
  });

  test('does not reseed after the user clears tiles', () {
    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
    controller.removeTile(controller.tiles.single.id);
    expect(controller.tiles, isEmpty);

    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
    expect(controller.tiles, isEmpty);
  });

  test('addTile and removeTile manage the tile list', () {
    hub.configure(const [
      TelemetryChannel(name: 'alt', type: 'F'),
      TelemetryChannel(name: 'temp', type: 'F'),
    ]);
    final initialCount = controller.tiles.length;

    controller.addTile(['alt', 'temp']);
    expect(controller.tiles.length, initialCount + 1);
    expect(controller.tiles.last.channelNames, ['alt', 'temp']);
    expect(controller.tiles.last.title, 'alt / temp');

    controller.removeTile(controller.tiles.last.id);
    expect(controller.tiles.length, initialCount);
  });

  test('prunes tiles whose channels vanish on reconfigure', () {
    hub.configure(const [
      TelemetryChannel(name: 'alt', type: 'F'),
      TelemetryChannel(name: 'temp', type: 'F'),
    ]);
    expect(controller.tiles.length, 2);

    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);

    expect(controller.tiles.length, 1);
    expect(controller.tiles.single.channelNames, ['alt']);
  });

  test('layout switching notifies listeners', () {
    var notified = 0;
    controller.addListener(() => notified++);

    controller.setLayout(DashboardLayout.dual);
    expect(controller.layout, DashboardLayout.dual);
    expect(notified, 1);

    controller.setLayout(DashboardLayout.dual); // no-op
    expect(notified, 1);
  });

  test('fullscreen enter/exit and removal of the fullscreen tile', () {
    hub.configure(const [TelemetryChannel(name: 'alt', type: 'F')]);
    final tile = controller.tiles.single;

    controller.enterFullscreen(tile.id);
    expect(controller.fullscreenTile?.id, tile.id);

    controller.exitFullscreen();
    expect(controller.fullscreenTile, isNull);

    controller.enterFullscreen(tile.id);
    controller.removeTile(tile.id);
    expect(controller.fullscreenTile, isNull);
  });
}
