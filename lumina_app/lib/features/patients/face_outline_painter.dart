import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// Professional medical-grade face outline painter for clinical diagrams.
/// Modeled after MEKO Hospital dermatology consultation face templates.
enum _FaceView { front, side, lipZone }

class FaceOutlinePainter extends CustomPainter {
  final String view; // 'FRONT', 'SIDE', 'LIP_ZONE'

  FaceOutlinePainter({required this.view});

  @override
  void paint(Canvas canvas, Size size) {
    final v = view == 'SIDE'
        ? _FaceView.side
        : view == 'LIP_ZONE'
            ? _FaceView.lipZone
            : _FaceView.front;

    switch (v) {
      case _FaceView.front:
        _drawFrontFace(canvas, size);
        break;
      case _FaceView.side:
        _drawSideFace(canvas, size);
        break;
      case _FaceView.lipZone:
        _drawLipZone(canvas, size);
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  // FRONT FACE — Professional medical illustration
  // ═══════════════════════════════════════════════════════════
  void _drawFrontFace(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.40;
    final fw = size.width * 0.34; // face half-width
    final fh = size.height * 0.38; // face half-height

    final thin = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final medium = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final light = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = const Color(0xFFFAF5F0).withOpacity(0.25)
      ..style = PaintingStyle.fill;

    // ─── Hair / Hairline ───
    final hairPath = Path();
    hairPath.moveTo(cx - fw * 0.85, cy - fh * 0.48);
    hairPath.cubicTo(
      cx - fw * 0.75, cy - fh * 0.92,
      cx - fw * 0.20, cy - fh * 1.08,
      cx, cy - fh * 1.02,
    );
    hairPath.cubicTo(
      cx + fw * 0.20, cy - fh * 1.08,
      cx + fw * 0.75, cy - fh * 0.92,
      cx + fw * 0.85, cy - fh * 0.48,
    );
    // Hair strands
    final hairStrand = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    for (double t = -0.6; t <= 0.6; t += 0.2) {
      final sx = cx + fw * t;
      final hp = Path()
        ..moveTo(sx, cy - fh * 0.95)
        ..cubicTo(sx + fw * 0.05, cy - fh * 0.80, sx - fw * 0.03, cy - fh * 0.65, sx + fw * 0.02, cy - fh * 0.55);
      canvas.drawPath(hp, hairStrand);
    }
    canvas.drawPath(hairPath, medium);

    // ─── Face Contour (jawline) ───
    final facePath = Path();
    // Start from left temple
    facePath.moveTo(cx - fw * 0.85, cy - fh * 0.48);
    // Left cheek curve
    facePath.cubicTo(
      cx - fw * 0.92, cy - fh * 0.15,
      cx - fw * 0.90, cy + fh * 0.15,
      cx - fw * 0.72, cy + fh * 0.45,
    );
    // Left jaw to chin
    facePath.cubicTo(
      cx - fw * 0.55, cy + fh * 0.72,
      cx - fw * 0.25, cy + fh * 0.92,
      cx, cy + fh * 0.95,
    );
    // Chin to right jaw
    facePath.cubicTo(
      cx + fw * 0.25, cy + fh * 0.92,
      cx + fw * 0.55, cy + fh * 0.72,
      cx + fw * 0.72, cy + fh * 0.45,
    );
    // Right cheek to right temple
    facePath.cubicTo(
      cx + fw * 0.90, cy + fh * 0.15,
      cx + fw * 0.92, cy - fh * 0.15,
      cx + fw * 0.85, cy - fh * 0.48,
    );
    canvas.drawPath(facePath, fill);
    canvas.drawPath(facePath, medium);

    // ─── Ears ───
    _drawFrontEar(canvas, cx - fw * 0.88, cy + fh * 0.02, fw * 0.12, fh * 0.18, thin, isLeft: true);
    _drawFrontEar(canvas, cx + fw * 0.88, cy + fh * 0.02, fw * 0.12, fh * 0.18, thin, isLeft: false);

    // ─── Eyebrows ───
    _drawEyebrow(canvas, cx - fw * 0.38, cy - fh * 0.22, fw * 0.32, true, medium);
    _drawEyebrow(canvas, cx + fw * 0.38, cy - fh * 0.22, fw * 0.32, false, medium);

    // ─── Eyes ───
    _drawFrontEye(canvas, cx - fw * 0.33, cy - fh * 0.10, fw * 0.22, fh * 0.065, thin, light);
    _drawFrontEye(canvas, cx + fw * 0.33, cy - fh * 0.10, fw * 0.22, fh * 0.065, thin, light);

    // ─── Nose ───
    _drawFrontNose(canvas, cx, cy + fh * 0.12, fw, fh, thin, light);

    // ─── Lips ───
    _drawFrontLips(canvas, cx, cy + fh * 0.38, fw * 0.28, fh * 0.06, medium, thin, fill);

    // ─── Nasolabial folds (subtle) ───
    final nlf = Path()
      ..moveTo(cx - fw * 0.22, cy + fh * 0.18)
      ..cubicTo(cx - fw * 0.24, cy + fh * 0.28, cx - fw * 0.22, cy + fh * 0.33, cx - fw * 0.18, cy + fh * 0.42);
    canvas.drawPath(nlf, light);
    final nlf2 = Path()
      ..moveTo(cx + fw * 0.22, cy + fh * 0.18)
      ..cubicTo(cx + fw * 0.24, cy + fh * 0.28, cx + fw * 0.22, cy + fh * 0.33, cx + fw * 0.18, cy + fh * 0.42);
    canvas.drawPath(nlf2, light);

    // ─── Neck ───
    final neckTop = cy + fh * 0.95;
    final nw = fw * 0.32;
    final neckL = Path()
      ..moveTo(cx - fw * 0.28, neckTop)
      ..cubicTo(cx - nw - fw * 0.02, neckTop + fh * 0.08, cx - nw, neckTop + fh * 0.18, cx - nw + fw * 0.02, neckTop + fh * 0.30);
    final neckR = Path()
      ..moveTo(cx + fw * 0.28, neckTop)
      ..cubicTo(cx + nw + fw * 0.02, neckTop + fh * 0.08, cx + nw, neckTop + fh * 0.18, cx + nw - fw * 0.02, neckTop + fh * 0.30);
    canvas.drawPath(neckL, thin);
    canvas.drawPath(neckR, thin);

    _drawLabel(canvas, Offset(cx, cy + fh * 1.15), 'airaMD — Front View');
  }

  void _drawFrontEar(Canvas canvas, double cx, double cy, double w, double h, Paint paint, {required bool isLeft}) {
    final dir = isLeft ? -1.0 : 1.0;
    final ear = Path()
      ..moveTo(cx, cy - h * 0.8)
      ..cubicTo(cx + dir * w * 0.9, cy - h * 0.7, cx + dir * w * 1.1, cy - h * 0.1, cx + dir * w * 0.9, cy + h * 0.3)
      ..cubicTo(cx + dir * w * 0.7, cy + h * 0.7, cx + dir * w * 0.3, cy + h * 0.9, cx, cy + h * 0.8);
    canvas.drawPath(ear, paint);
    // Inner ear detail
    final inner = Path()
      ..moveTo(cx + dir * w * 0.15, cy - h * 0.4)
      ..cubicTo(cx + dir * w * 0.55, cy - h * 0.3, cx + dir * w * 0.6, cy + h * 0.1, cx + dir * w * 0.35, cy + h * 0.4);
    final ip = Paint()
      ..color = paint.color.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(inner, ip);
  }

  void _drawEyebrow(Canvas canvas, double cx, double cy, double w, bool isLeft, Paint paint) {
    final browPaint = Paint()
      ..color = paint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    if (isLeft) {
      final p = Path()
        ..moveTo(cx - w * 0.5, cy + w * 0.06)
        ..cubicTo(cx - w * 0.25, cy - w * 0.12, cx + w * 0.15, cy - w * 0.14, cx + w * 0.5, cy + w * 0.02);
      canvas.drawPath(p, browPaint);
    } else {
      final p = Path()
        ..moveTo(cx + w * 0.5, cy + w * 0.06)
        ..cubicTo(cx + w * 0.25, cy - w * 0.12, cx - w * 0.15, cy - w * 0.14, cx - w * 0.5, cy + w * 0.02);
      canvas.drawPath(p, browPaint);
    }
  }

  void _drawFrontEye(Canvas canvas, double cx, double cy, double w, double h, Paint paint, Paint light) {
    // Upper eyelid
    final upper = Path()
      ..moveTo(cx - w, cy)
      ..cubicTo(cx - w * 0.5, cy - h * 1.6, cx + w * 0.5, cy - h * 1.6, cx + w, cy);
    // Lower eyelid
    final lower = Path()
      ..moveTo(cx - w, cy)
      ..cubicTo(cx - w * 0.5, cy + h * 1.2, cx + w * 0.5, cy + h * 1.2, cx + w, cy);
    canvas.drawPath(upper, paint);
    canvas.drawPath(lower, paint);

    // Double eyelid crease
    final crease = Path()
      ..moveTo(cx - w * 0.85, cy - h * 0.8)
      ..cubicTo(cx - w * 0.4, cy - h * 2.4, cx + w * 0.4, cy - h * 2.4, cx + w * 0.85, cy - h * 0.8);
    canvas.drawPath(crease, light);

    // Iris
    final irisR = h * 0.9;
    canvas.drawCircle(Offset(cx, cy - h * 0.1), irisR, paint);
    // Pupil
    final pupilPaint = Paint()
      ..color = paint.color.withOpacity(0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy - h * 0.1), irisR * 0.45, pupilPaint);
    // Iris light reflection
    final reflPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx + irisR * 0.3, cy - h * 0.1 - irisR * 0.3), irisR * 0.18, reflPaint);

    // Eyelashes (subtle)
    final lashPaint = Paint()
      ..color = paint.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..strokeCap = StrokeCap.round;
    for (double t = -0.6; t <= 0.6; t += 0.3) {
      final lx = cx + w * t;
      final ly = cy - h * 1.3 + (t.abs() * h * 0.7);
      canvas.drawLine(Offset(lx, ly), Offset(lx, ly - h * 0.5), lashPaint);
    }
  }

  void _drawFrontNose(Canvas canvas, double cx, double cy, double fw, double fh, Paint paint, Paint light) {
    // Nose bridge (subtle lines)
    final bridgeL = Path()
      ..moveTo(cx - fw * 0.06, cy - fh * 0.20)
      ..cubicTo(cx - fw * 0.07, cy - fh * 0.10, cx - fw * 0.08, cy - fh * 0.02, cx - fw * 0.10, cy + fh * 0.02);
    final bridgeR = Path()
      ..moveTo(cx + fw * 0.06, cy - fh * 0.20)
      ..cubicTo(cx + fw * 0.07, cy - fh * 0.10, cx + fw * 0.08, cy - fh * 0.02, cx + fw * 0.10, cy + fh * 0.02);
    canvas.drawPath(bridgeL, light);
    canvas.drawPath(bridgeR, light);

    // Nose tip / ball
    final noseTip = Path()
      ..moveTo(cx - fw * 0.10, cy + fh * 0.02)
      ..cubicTo(cx - fw * 0.14, cy + fh * 0.04, cx - fw * 0.13, cy + fh * 0.07, cx - fw * 0.08, cy + fh * 0.07);
    canvas.drawPath(noseTip, paint);
    final noseTip2 = Path()
      ..moveTo(cx + fw * 0.10, cy + fh * 0.02)
      ..cubicTo(cx + fw * 0.14, cy + fh * 0.04, cx + fw * 0.13, cy + fh * 0.07, cx + fw * 0.08, cy + fh * 0.07);
    canvas.drawPath(noseTip2, paint);

    // Nostrils
    final nostrilL = Path()
      ..moveTo(cx - fw * 0.03, cy + fh * 0.06)
      ..cubicTo(cx - fw * 0.08, cy + fh * 0.065, cx - fw * 0.09, cy + fh * 0.045, cx - fw * 0.06, cy + fh * 0.035);
    final nostrilR = Path()
      ..moveTo(cx + fw * 0.03, cy + fh * 0.06)
      ..cubicTo(cx + fw * 0.08, cy + fh * 0.065, cx + fw * 0.09, cy + fh * 0.045, cx + fw * 0.06, cy + fh * 0.035);
    canvas.drawPath(nostrilL, paint);
    canvas.drawPath(nostrilR, paint);

    // Nose bottom line
    final noseBottom = Path()
      ..moveTo(cx - fw * 0.08, cy + fh * 0.07)
      ..cubicTo(cx - fw * 0.03, cy + fh * 0.08, cx + fw * 0.03, cy + fh * 0.08, cx + fw * 0.08, cy + fh * 0.07);
    canvas.drawPath(noseBottom, light);
  }

  void _drawFrontLips(Canvas canvas, double cx, double cy, double w, double h, Paint med, Paint thin, Paint fill) {
    // Upper lip with cupid's bow
    final upperLip = Path()
      ..moveTo(cx - w, cy)
      ..cubicTo(cx - w * 0.7, cy - h * 0.3, cx - w * 0.35, cy - h * 0.5, cx - w * 0.08, cy - h * 1.0)
      ..cubicTo(cx - w * 0.03, cy - h * 1.3, cx + w * 0.03, cy - h * 1.3, cx + w * 0.08, cy - h * 1.0)
      ..cubicTo(cx + w * 0.35, cy - h * 0.5, cx + w * 0.7, cy - h * 0.3, cx + w, cy);

    // Lower lip
    final lowerLip = Path()
      ..moveTo(cx - w, cy)
      ..cubicTo(cx - w * 0.6, cy + h * 1.8, cx + w * 0.6, cy + h * 1.8, cx + w, cy);

    // Fill
    final lipFill = Paint()
      ..color = const Color(0xFFE8D5C8).withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final fullLip = Path()..addPath(upperLip, Offset.zero)..addPath(lowerLip, Offset.zero)..close();
    canvas.drawPath(fullLip, lipFill);

    canvas.drawPath(upperLip, med);
    canvas.drawPath(lowerLip, med);

    // Lip line (mouth crease)
    final lipLine = Path()
      ..moveTo(cx - w * 0.92, cy + h * 0.1)
      ..cubicTo(cx - w * 0.4, cy - h * 0.15, cx + w * 0.4, cy - h * 0.15, cx + w * 0.92, cy + h * 0.1);
    canvas.drawPath(lipLine, thin);

    // Philtrum
    final phil = Paint()
      ..color = thin.color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    canvas.drawLine(Offset(cx - w * 0.06, cy - h * 2.8), Offset(cx - w * 0.07, cy - h * 1.1), phil);
    canvas.drawLine(Offset(cx + w * 0.06, cy - h * 2.8), Offset(cx + w * 0.07, cy - h * 1.1), phil);
  }

  // ═══════════════════════════════════════════════════════════
  // SIDE FACE — Professional medical illustration
  // ═══════════════════════════════════════════════════════════
  void _drawSideFace(Canvas canvas, Size size) {
    final cx = size.width * 0.48;
    final cy = size.height * 0.40;
    final fw = size.width * 0.32;
    final fh = size.height * 0.38;

    final thin = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final medium = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final light = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = const Color(0xFFFAF5F0).withOpacity(0.2)
      ..style = PaintingStyle.fill;

    // ─── Head profile contour ───
    final profile = Path();
    // Start at top of forehead
    final topX = cx - fw * 0.05;
    final topY = cy - fh * 0.92;

    // Hair top
    profile.moveTo(topX - fw * 0.45, topY + fh * 0.05);
    profile.cubicTo(
      topX - fw * 0.40, topY - fh * 0.12,
      topX + fw * 0.10, topY - fh * 0.15,
      topX + fw * 0.20, topY,
    );

    // Forehead
    profile.cubicTo(
      topX + fw * 0.28, topY + fh * 0.08,
      topX + fw * 0.30, topY + fh * 0.18,
      topX + fw * 0.25, topY + fh * 0.28,
    );

    // Brow ridge
    profile.cubicTo(
      topX + fw * 0.32, topY + fh * 0.32,
      topX + fw * 0.35, topY + fh * 0.35,
      topX + fw * 0.28, topY + fh * 0.42,
    );

    // Nose bridge
    profile.cubicTo(
      topX + fw * 0.22, topY + fh * 0.48,
      topX + fw * 0.24, topY + fh * 0.52,
      topX + fw * 0.40, topY + fh * 0.58,
    );

    // Nose tip
    profile.cubicTo(
      topX + fw * 0.46, topY + fh * 0.60,
      topX + fw * 0.46, topY + fh * 0.64,
      topX + fw * 0.38, topY + fh * 0.66,
    );

    // Upper lip
    profile.cubicTo(
      topX + fw * 0.30, topY + fh * 0.68,
      topX + fw * 0.32, topY + fh * 0.70,
      topX + fw * 0.34, topY + fh * 0.72,
    );

    // Lower lip
    profile.cubicTo(
      topX + fw * 0.36, topY + fh * 0.76,
      topX + fw * 0.34, topY + fh * 0.80,
      topX + fw * 0.28, topY + fh * 0.82,
    );

    // Chin
    profile.cubicTo(
      topX + fw * 0.22, topY + fh * 0.88,
      topX + fw * 0.15, topY + fh * 0.95,
      topX + fw * 0.05, topY + fh * 1.02,
    );

    // Under chin to neck front
    profile.cubicTo(
      topX - fw * 0.08, topY + fh * 1.08,
      topX - fw * 0.12, topY + fh * 1.15,
      topX - fw * 0.10, topY + fh * 1.30,
    );

    canvas.drawPath(profile, fill);
    canvas.drawPath(profile, medium);

    // ─── Back of head ───
    final back = Path();
    back.moveTo(topX - fw * 0.45, topY + fh * 0.05);
    back.cubicTo(
      topX - fw * 0.75, topY + fh * 0.15,
      topX - fw * 0.80, topY + fh * 0.50,
      topX - fw * 0.70, topY + fh * 0.75,
    );
    // Back of neck
    back.cubicTo(
      topX - fw * 0.55, topY + fh * 0.95,
      topX - fw * 0.40, topY + fh * 1.10,
      topX - fw * 0.35, topY + fh * 1.30,
    );
    canvas.drawPath(back, medium);

    // ─── Hair ───
    final hairStrand = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;
    for (double t = 0; t < 5; t++) {
      final hp = Path()
        ..moveTo(topX - fw * (0.10 + t * 0.07), topY - fh * 0.06 + t * fh * 0.04)
        ..cubicTo(
          topX - fw * (0.25 + t * 0.06), topY + fh * (0.10 + t * 0.08),
          topX - fw * (0.35 + t * 0.05), topY + fh * (0.20 + t * 0.10),
          topX - fw * (0.40 + t * 0.04), topY + fh * (0.30 + t * 0.10),
        );
      canvas.drawPath(hp, hairStrand);
    }

    // ─── Eye (side view) ───
    final eyeX = topX + fw * 0.18;
    final eyeY = topY + fh * 0.40;
    final ew = fw * 0.12;
    final eh = fh * 0.03;
    // Almond shape
    final sideEye = Path()
      ..moveTo(eyeX - ew, eyeY)
      ..cubicTo(eyeX - ew * 0.3, eyeY - eh * 2.0, eyeX + ew * 0.3, eyeY - eh * 2.0, eyeX + ew, eyeY)
      ..cubicTo(eyeX + ew * 0.3, eyeY + eh * 1.2, eyeX - ew * 0.3, eyeY + eh * 1.2, eyeX - ew, eyeY);
    canvas.drawPath(sideEye, thin);
    // Eyelash
    final lashP = Paint()
      ..color = thin.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(eyeX + ew, eyeY), Offset(eyeX + ew + fw * 0.02, eyeY - eh * 0.5), lashP);

    // Eyebrow
    final browP = Path()
      ..moveTo(eyeX - ew * 0.5, eyeY - eh * 4.5)
      ..cubicTo(eyeX, eyeY - eh * 6.0, eyeX + ew * 0.8, eyeY - eh * 5.0, eyeX + ew * 1.2, eyeY - eh * 3.5);
    canvas.drawPath(browP, medium);

    // ─── Ear ───
    final earX = topX - fw * 0.38;
    final earY = topY + fh * 0.50;
    final earW = fw * 0.14;
    final earH = fh * 0.14;
    final ear = Path()
      ..moveTo(earX, earY - earH)
      ..cubicTo(earX - earW * 1.5, earY - earH * 0.6, earX - earW * 1.5, earY + earH * 0.6, earX - earW * 0.3, earY + earH)
      ..cubicTo(earX - earW * 0.1, earY + earH * 1.1, earX + earW * 0.1, earY + earH * 0.8, earX + earW * 0.1, earY + earH * 0.5);
    canvas.drawPath(ear, thin);
    // Inner ear
    final innerEar = Path()
      ..moveTo(earX - earW * 0.2, earY - earH * 0.5)
      ..cubicTo(earX - earW * 0.9, earY - earH * 0.2, earX - earW * 0.8, earY + earH * 0.3, earX - earW * 0.2, earY + earH * 0.5);
    canvas.drawPath(innerEar, light);

    // ─── Nostril detail ───
    final nostril = Path()
      ..moveTo(topX + fw * 0.38, topY + fh * 0.66)
      ..cubicTo(topX + fw * 0.34, topY + fh * 0.67, topX + fw * 0.32, topY + fh * 0.65, topX + fw * 0.33, topY + fh * 0.63);
    canvas.drawPath(nostril, thin);

    _drawLabel(canvas, Offset(size.width / 2, cy + fh * 1.10), 'airaMD — Side View');
  }

  // ═══════════════════════════════════════════════════════════
  // LIP ZONE — Professional medical illustration (zoomed)
  // ═══════════════════════════════════════════════════════════
  void _drawLipZone(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final lw = size.width * 0.30; // lip half-width
    final lh = size.height * 0.08; // lip half-height

    final thin = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final medium = Paint()
      ..color = const Color(0xFFB5A090)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final light = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    final lipFill = Paint()
      ..color = const Color(0xFFEDD8CC).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // ─── Nose base (above lips) ───
    // Nose tip
    final noseTip = Path()
      ..moveTo(cx - lw * 0.25, cy - lh * 4.5)
      ..cubicTo(cx - lw * 0.30, cy - lh * 4.8, cx - lw * 0.15, cy - lh * 5.5, cx, cy - lh * 5.2)
      ..cubicTo(cx + lw * 0.15, cy - lh * 5.5, cx + lw * 0.30, cy - lh * 4.8, cx + lw * 0.25, cy - lh * 4.5);
    canvas.drawPath(noseTip, thin);

    // Nostrils
    final nostrilL = Path()
      ..moveTo(cx - lw * 0.05, cy - lh * 4.2)
      ..cubicTo(cx - lw * 0.18, cy - lh * 4.0, cx - lw * 0.25, cy - lh * 4.3, cx - lw * 0.18, cy - lh * 4.5);
    final nostrilR = Path()
      ..moveTo(cx + lw * 0.05, cy - lh * 4.2)
      ..cubicTo(cx + lw * 0.18, cy - lh * 4.0, cx + lw * 0.25, cy - lh * 4.3, cx + lw * 0.18, cy - lh * 4.5);
    canvas.drawPath(nostrilL, thin);
    canvas.drawPath(nostrilR, thin);

    // Nose base line
    final noseBase = Path()
      ..moveTo(cx - lw * 0.25, cy - lh * 4.5)
      ..cubicTo(cx - lw * 0.10, cy - lh * 4.2, cx + lw * 0.10, cy - lh * 4.2, cx + lw * 0.25, cy - lh * 4.5);
    canvas.drawPath(noseBase, light);

    // ─── Philtrum ───
    final philL = Path()
      ..moveTo(cx - lw * 0.08, cy - lh * 4.0)
      ..cubicTo(cx - lw * 0.09, cy - lh * 3.0, cx - lw * 0.10, cy - lh * 2.0, cx - lw * 0.10, cy - lh * 1.2);
    final philR = Path()
      ..moveTo(cx + lw * 0.08, cy - lh * 4.0)
      ..cubicTo(cx + lw * 0.09, cy - lh * 3.0, cx + lw * 0.10, cy - lh * 2.0, cx + lw * 0.10, cy - lh * 1.2);
    canvas.drawPath(philL, light);
    canvas.drawPath(philR, light);

    // Philtrum groove center
    final philC = Path()
      ..moveTo(cx, cy - lh * 3.8)
      ..lineTo(cx, cy - lh * 1.4);
    final vLight = Paint()
      ..color = const Color(0xFFCDBFB2).withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(philC, vLight);

    // ─── Upper lip (vermilion border) — cupid's bow ───
    final upperOuter = Path()
      ..moveTo(cx - lw, cy)
      ..cubicTo(cx - lw * 0.75, cy - lh * 0.4, cx - lw * 0.45, cy - lh * 0.8, cx - lw * 0.12, cy - lh * 1.3)
      // Cupid's bow peak left
      ..cubicTo(cx - lw * 0.06, cy - lh * 1.5, cx, cy - lh * 1.1, cx, cy - lh * 1.1)
      // Cupid's bow center dip
      ..cubicTo(cx, cy - lh * 1.1, cx + lw * 0.06, cy - lh * 1.5, cx + lw * 0.12, cy - lh * 1.3)
      // Cupid's bow peak right
      ..cubicTo(cx + lw * 0.45, cy - lh * 0.8, cx + lw * 0.75, cy - lh * 0.4, cx + lw, cy);

    // Upper lip inner (mouth line)
    final upperInner = Path()
      ..moveTo(cx - lw * 0.90, cy + lh * 0.15)
      ..cubicTo(cx - lw * 0.5, cy - lh * 0.3, cx + lw * 0.5, cy - lh * 0.3, cx + lw * 0.90, cy + lh * 0.15);

    // Lower lip outer
    final lowerOuter = Path()
      ..moveTo(cx - lw, cy)
      ..cubicTo(cx - lw * 0.65, cy + lh * 2.5, cx + lw * 0.65, cy + lh * 2.5, cx + lw, cy);

    // Lower lip inner
    final lowerInner = Path()
      ..moveTo(cx - lw * 0.90, cy + lh * 0.15)
      ..cubicTo(cx - lw * 0.5, cy + lh * 1.5, cx + lw * 0.5, cy + lh * 1.5, cx + lw * 0.90, cy + lh * 0.15);

    // Fill lips
    final upperFillPath = Path()..addPath(upperOuter, Offset.zero)..addPath(upperInner.shift(Offset.zero), Offset.zero)..close();
    final lowerFillPath = Path()..addPath(lowerOuter, Offset.zero)..addPath(lowerInner.shift(Offset.zero), Offset.zero)..close();
    canvas.drawPath(upperFillPath, lipFill);
    canvas.drawPath(lowerFillPath, lipFill);

    // Draw outlines
    canvas.drawPath(upperOuter, medium);
    canvas.drawPath(lowerOuter, medium);
    canvas.drawPath(upperInner, thin);
    canvas.drawPath(lowerInner, thin);

    // ─── Lip details ───
    // Oral commissures (corners)
    final commL = Path()
      ..moveTo(cx - lw * 1.02, cy + lh * 0.1)
      ..cubicTo(cx - lw * 1.08, cy + lh * 0.3, cx - lw * 1.06, cy + lh * 0.5, cx - lw * 0.98, cy + lh * 0.5);
    final commR = Path()
      ..moveTo(cx + lw * 1.02, cy + lh * 0.1)
      ..cubicTo(cx + lw * 1.08, cy + lh * 0.3, cx + lw * 1.06, cy + lh * 0.5, cx + lw * 0.98, cy + lh * 0.5);
    canvas.drawPath(commL, light);
    canvas.drawPath(commR, light);

    // Lower lip crease
    final lowerCrease = Path()
      ..moveTo(cx - lw * 0.5, cy + lh * 1.6)
      ..cubicTo(cx - lw * 0.2, cy + lh * 1.8, cx + lw * 0.2, cy + lh * 1.8, cx + lw * 0.5, cy + lh * 1.6);
    canvas.drawPath(lowerCrease, light);

    // Vertical lip lines (subtle)
    for (double t = -0.6; t <= 0.6; t += 0.15) {
      final lx = cx + lw * t;
      final vLine = Path()
        ..moveTo(lx, cy - lh * 0.6 + t.abs() * lh * 0.3)
        ..lineTo(lx, cy + lh * 0.6 - t.abs() * lh * 0.2);
      canvas.drawPath(vLine, vLight);
    }

    // ─── Chin area ───
    final chin = Path()
      ..moveTo(cx - lw * 0.55, cy + lh * 3.5)
      ..cubicTo(cx - lw * 0.3, cy + lh * 4.2, cx + lw * 0.3, cy + lh * 4.2, cx + lw * 0.55, cy + lh * 3.5);
    canvas.drawPath(chin, light);

    // Mental crease
    final mentalCrease = Path()
      ..moveTo(cx - lw * 0.35, cy + lh * 3.0)
      ..cubicTo(cx - lw * 0.15, cy + lh * 3.2, cx + lw * 0.15, cy + lh * 3.2, cx + lw * 0.35, cy + lh * 3.0);
    canvas.drawPath(mentalCrease, light);

    // ─── Nasolabial folds ───
    final nlL = Path()
      ..moveTo(cx - lw * 0.30, cy - lh * 3.5)
      ..cubicTo(cx - lw * 0.40, cy - lh * 2.0, cx - lw * 0.60, cy - lh * 0.5, cx - lw * 0.95, cy + lh * 0.2);
    final nlR = Path()
      ..moveTo(cx + lw * 0.30, cy - lh * 3.5)
      ..cubicTo(cx + lw * 0.40, cy - lh * 2.0, cx + lw * 0.60, cy - lh * 0.5, cx + lw * 0.95, cy + lh * 0.2);
    canvas.drawPath(nlL, light);
    canvas.drawPath(nlR, light);

    // ─── Marionette lines ───
    final marL = Path()
      ..moveTo(cx - lw * 0.88, cy + lh * 0.5)
      ..cubicTo(cx - lw * 0.80, cy + lh * 1.5, cx - lw * 0.65, cy + lh * 2.5, cx - lw * 0.55, cy + lh * 3.2);
    final marR = Path()
      ..moveTo(cx + lw * 0.88, cy + lh * 0.5)
      ..cubicTo(cx + lw * 0.80, cy + lh * 1.5, cx + lw * 0.65, cy + lh * 2.5, cx + lw * 0.55, cy + lh * 3.2);
    canvas.drawPath(marL, light);
    canvas.drawPath(marR, light);

    _drawLabel(canvas, Offset(cx, cy + lh * 5.5), 'airaMD — Lip Zone');
  }

  // ═══════════════════════════════════════════════════════════
  void _drawLabel(Canvas canvas, Offset position, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: 11,
          color: const Color(0xFF9A7D6A).withOpacity(0.5),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(position.dx - tp.width / 2, position.dy));
  }

  @override
  bool shouldRepaint(FaceOutlinePainter old) => old.view != view;
}
