import 'package:flutter/widgets.dart';

import '../components/tdl_panel.dart';
import '../tdl_context.dart';
import '../tokens/colors.dart';

/// Placeholder map view with topographic grid and track path.
///
/// A real map provider can replace the painter later without changing the
/// surrounding panel chrome.
class TelemetryMapView extends StatelessWidget {
  const TelemetryMapView({
    super.key,
    this.trackPoints = const [],
    this.fill = false,
  });

  /// Normalised [0,1] track coordinates. Empty shows a demo path.
  final List<Offset> trackPoints;
  final bool fill;

  @override
  Widget build(BuildContext context) {
    final painter = _MapPainter(
      colors: context.tdlColors,
      trackPoints: trackPoints,
    );

    return TDLPanel(
      title: 'System Map',
      padding: EdgeInsets.zero,
      expandChild: fill,
      child: fill
          ? CustomPaint(painter: painter, child: const SizedBox.expand())
          : AspectRatio(
              aspectRatio: 16 / 10,
              child: CustomPaint(painter: painter),
            ),
    );
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.colors, required this.trackPoints});

  final TDLColors colors;
  final List<Offset> trackPoints;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = colors.panel,
    );

    final gridPaint = Paint()
      ..color = colors.borderSecondary
      ..strokeWidth = 1;

    const gridStep = 24.0;
    for (var x = 0.0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (var y = 0.0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = trackPoints.isEmpty ? _demoPath() : trackPoints;
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final p = Offset(
        points[i].dx * size.width,
        points[i].dy * size.height,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }

    final trackPaint = Paint()
      ..color = colors.accent
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, trackPaint);

    final last = points.last;
    final head = Offset(last.dx * size.width, last.dy * size.height);
    canvas.drawCircle(head, 4, Paint()..color = colors.accent);
  }

  List<Offset> _demoPath() {
    return const [
      Offset(0.15, 0.75),
      Offset(0.22, 0.68),
      Offset(0.30, 0.62),
      Offset(0.38, 0.55),
      Offset(0.46, 0.48),
      Offset(0.54, 0.42),
      Offset(0.62, 0.36),
      Offset(0.70, 0.30),
      Offset(0.78, 0.24),
    ];
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) =>
      oldDelegate.trackPoints != trackPoints;
}
