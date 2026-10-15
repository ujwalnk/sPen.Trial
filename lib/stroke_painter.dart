import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:perfect_freehand/perfect_freehand.dart';

import 'nib_model.dart';
import 'stroke.dart';

/// Renders strokes using perfect_freehand's outline algorithm.
///
/// perfect_freehand is only used to generate the smooth outline polygon
/// (spline fitting, corner handling, caps). Every width value it uses comes
/// from widths [NibModel] already computed per point -- this painter never
/// falls back to `Paint.strokeWidth`.
class StrokePainter extends CustomPainter {
  StrokePainter({
    required this.strokes,
    required this.activeStroke,
    required this.nibModel,
    required this.showDebugOverlay,
  });

  final List<Stroke> strokes;
  final Stroke? activeStroke;
  final NibModel nibModel;
  final bool showDebugOverlay;

  final Paint _inkPaint = Paint()
    ..color = const Color(0xFF14213D)
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _paintStroke(canvas, stroke);
    }

    if (showDebugOverlay && activeStroke != null) {
      _paintDebugOverlay(canvas, activeStroke!);
    }
  }

  void _paintStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    if (stroke.points.length == 1) {
      // A single tap with no movement yet: draw a dot at its own width.
      final point = stroke.points.first;
      canvas.drawCircle(point.position, point.width / 2, _inkPaint);
      return;
    }

    final maxWidth = nibModel.thickWidth;

    // perfect_freehand only knows how to turn "pressure" into radius, so we
    // re-express each point's already-computed NibModel width as a
    // normalized pseudo-pressure value in 0..1. The outline shape it
    // produces is still entirely perfect_freehand's own algorithm.
    final inputPoints = stroke.points.map((strokePoint) {
      final normalizedPressure = maxWidth > 0
          ? (strokePoint.width / maxWidth).clamp(0.05, 1.0)
          : 1.0;
      return PointVector(
        strokePoint.position.dx,
        strokePoint.position.dy,
        normalizedPressure,
      );
    }).toList();

    final options = StrokeOptions(
      size: maxWidth,
      thinning: 1.0,
      smoothing: 0.5,
      streamline: 0.35,
      simulatePressure: false,
      start: StrokeEndOptions.start(cap: true, taperEnabled: false),
      end: StrokeEndOptions.end(cap: true, taperEnabled: false),
      isComplete: stroke != activeStroke,
    );

    final outline = getStroke(inputPoints, options: options);
    if (outline.isEmpty) return;

    final path = Path()..addPolygon(outline, true);
    canvas.drawPath(path, _inkPaint);
  }

  void _paintDebugOverlay(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final last = stroke.points.last;
    final origin = last.position;

    final movementVectorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2;
    final nibVectorPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2;

    const vectorLength = 40.0;

    final movementEnd = origin +
        Offset(
              cos(nibModel.lastMovementAngleRadians),
              sin(nibModel.lastMovementAngleRadians),
            ) *
            vectorLength;

    final nibEnd = origin +
        Offset(
              cos(nibModel.lastNibAngleRadians),
              sin(nibModel.lastNibAngleRadians),
            ) *
            vectorLength;

    canvas.drawLine(origin, movementEnd, movementVectorPaint);
    canvas.drawLine(origin, nibEnd, nibVectorPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'w: ${last.width.toStringAsFixed(1)}',
        style: const TextStyle(color: Colors.black, fontSize: 12),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, origin + const Offset(8, -20));
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true;
}