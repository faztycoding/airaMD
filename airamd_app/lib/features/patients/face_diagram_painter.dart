part of 'face_diagram_screen.dart';

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double size;

  _Stroke({required this.points, required this.color, required this.size});
}

// ═══════════════════════════════════════════════════════════════
// Strokes Painter — renders user drawings using perfect_freehand
// ═══════════════════════════════════════════════════════════════
class _StrokesPainter extends CustomPainter {
  final List<_Stroke> strokes;
  final _Stroke? currentStroke;

  _StrokesPainter({required this.strokes, this.currentStroke});

  @override
  void paint(Canvas canvas, Size size) {
    final List<_Stroke> allStrokes = [
      ...strokes,
      if (currentStroke != null) currentStroke!,
    ];

    for (final stroke in allStrokes) {
      if (stroke.points.length < 2) continue;

      final inputPoints = stroke.points
          .map((p) => PointVector(p.dx, p.dy))
          .toList();

      final outlinePoints = getStroke(
        inputPoints,
        options: StrokeOptions(
          size: stroke.size,
          thinning: 0.5,
          smoothing: 0.5,
          streamline: 0.5,
        ),
      );

      if (outlinePoints.isEmpty) continue;

      final path = Path();
      if (outlinePoints.length == 1) {
        path.addOval(Rect.fromCircle(
          center: outlinePoints[0],
          radius: stroke.size / 2,
        ));
      } else {
        path.moveTo(outlinePoints[0].dx, outlinePoints[0].dy);
        for (int i = 1; i < outlinePoints.length - 1; i++) {
          final p0 = outlinePoints[i];
          final p1 = outlinePoints[i + 1];
          path.quadraticBezierTo(
            p0.dx, p0.dy,
            (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2,
          );
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = stroke.color
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(_StrokesPainter old) => true;
}
