import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../charts/altitude_chart.dart';
import '../data/data_queue.dart';
import '../theme/app_colors.dart';

final Logger _logger = Logger();

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.appBarBackground,
        centerTitle: true,
        title: Text(title),
      ),
      body: const _HomeBody(),
      backgroundColor: AppColors.scaffoldBackground,
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody();

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      AspectRatio(
        aspectRatio: 3 / 10,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.panelBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.panelBackground, width: 2),
          ),
          margin: const EdgeInsets.all(10),
          alignment: Alignment.centerLeft,
          constraints: const BoxConstraints(minWidth: 200, minHeight: 600),
          child: const SidePanel(),
        ),
      ),
      Expanded(
        child: Container(
          color: AppColors.chartBackground,
          margin: const EdgeInsets.all(40),
          child: const ChartGrid(),
        ),
      ),
    ]);
  }
}

class SidePanel extends StatelessWidget {
  const SidePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 200, minHeight: 200),
      child: const Text(
        'Hello World',
        style: TextStyle(color: AppColors.accent),
      ),
    );
  }
}

/// Main chart area: Altitude, Temperature, Velocity, Acceleration and
/// Gyroscope tiles. Only Temperature plots live data in this prototype.
class ChartGrid extends StatefulWidget {
  const ChartGrid({super.key});

  @override
  State<ChartGrid> createState() => _ChartGridState();
}

class _ChartGridState extends State<ChartGrid> {
  final StreamController<List<int>> _streamController =
      StreamController<List<int>>();
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Prototype plumbing: polls the global queue every 2 seconds and pushes
    // parsed integers to the chart stream. Replaced by event-driven push in
    // G1-M2.
    _pollTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _drainDataQueue(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Expanded(
        flex: 2,
        child: Row(
          children: <Widget>[
            const Expanded(
              child: AspectRatio(aspectRatio: 16 / 15, child: AltitudeTile()),
            ),
            Expanded(
              child: AspectRatio(
                aspectRatio: 16 / 15,
                child: TemperatureTile(dataStream: _streamController.stream),
              ),
            ),
            const Expanded(
              child: AspectRatio(aspectRatio: 16 / 15, child: VelocityTile()),
            ),
          ],
        ),
      ),
      const Expanded(
        flex: 3,
        child: Row(
          children: <Widget>[
            Expanded(
              child: AspectRatio(aspectRatio: 16 / 13, child: GyroscopeTile()),
            ),
            Expanded(
              child:
                  AspectRatio(aspectRatio: 16 / 13, child: AccelerationTile()),
            ),
          ],
        ),
      ),
    ]);
  }

  void _drainDataQueue() {
    if (dataQueue.isEmpty) return;
    final raw = dataQueue.removeFirst();
    final values = <int>[];
    for (final match in RegExp(r'\b(\d|\d{2})\b').allMatches(raw)) {
      try {
        values.add(int.parse(match.group(1)!));
      } catch (e) {
        _logger.e('Error in parsing $e');
      }
    }
    _streamController.add(values);
  }
}

class AltitudeTile extends StatelessWidget {
  const AltitudeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      child: Container(
        margin: const EdgeInsets.all(10),
        color: Colors.black,
      ),
    );
  }
}

class TemperatureTile extends StatelessWidget {
  const TemperatureTile({super.key, required this.dataStream});

  final Stream<List<int>> dataStream;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: SizedBox(
        height: 200,
        width: 200,
        child: AltitudeChart(dataStream: dataStream),
      ),
    );
  }
}

class VelocityTile extends StatelessWidget {
  const VelocityTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(height: 200, width: 200),
    );
  }
}

class AccelerationTile extends StatelessWidget {
  const AccelerationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(height: 200, width: 200),
    );
  }
}

class GyroscopeTile extends StatelessWidget {
  const GyroscopeTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      color: Colors.black,
      child: const SizedBox(
        height: 200,
        width: 200,
        child: Text('Gyroscope'),
      ),
    );
  }
}
