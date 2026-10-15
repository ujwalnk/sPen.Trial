import 'package:flutter/material.dart';

import 'nib_model.dart';
import 'stroke.dart';
import 'stroke_painter.dart';

/// Captures pointer input (finger or stylus) and turns it into a list of
/// [Stroke]s whose per-point width comes entirely from [NibModel].
///
/// Uses [Listener] rather than a gesture recognizer so both stylus and
/// finger pointer events are handled identically, and so pressure data is
/// never even consulted.
class DrawingCanvas extends StatefulWidget {
  const DrawingCanvas({
    super.key,
    required this.nibModel,
    required this.showDebugOverlay,
  });

  final NibModel nibModel;
  final bool showDebugOverlay;

  @override
  State<DrawingCanvas> createState() => DrawingCanvasState();
}

class DrawingCanvasState extends State<DrawingCanvas> {
  final List<Stroke> _strokes = [];
  Stroke? _activeStroke;

  /// Removes all strokes from the canvas.
  void clearStrokes() {
    setState(() {
      _strokes.clear();
      _activeStroke = null;
    });
  }

  void _startStroke(PointerDownEvent event) {
    // A fresh stroke should not inherit smoothing state from whatever was
    // drawn before it.
    widget.nibModel.resetStrokeState();

    final point = StrokePoint(
      position: event.localPosition,
      timestamp: DateTime.now(),
      width: widget.nibModel.thinWidth,
    );

    final stroke = Stroke(points: [point]);

    setState(() {
      _activeStroke = stroke;
      _strokes.add(stroke);
    });
  }

  void _extendStroke(PointerMoveEvent event) {
    final stroke = _activeStroke;
    if (stroke == null || stroke.points.isEmpty) return;

    final previousPosition = stroke.points.last.position;
    final currentPosition = event.localPosition;

    // Width is calculated immediately, from direction alone.
    final width = widget.nibModel.widthForSegment(
      previousPosition,
      currentPosition,
    );

    final point = StrokePoint(
      position: currentPosition,
      timestamp: DateTime.now(),
      width: width,
    );

    setState(() {
      stroke.points.add(point);
    });
  }

  void _endStroke(PointerEvent event) {
    setState(() {
      _activeStroke = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _startStroke,
      onPointerMove: _extendStroke,
      onPointerUp: _endStroke,
      onPointerCancel: _endStroke,
      child: CustomPaint(
        painter: StrokePainter(
          strokes: _strokes,
          activeStroke: _activeStroke,
          nibModel: widget.nibModel,
          showDebugOverlay: widget.showDebugOverlay,
        ),
        size: Size.infinite,
      ),
    );
  }
}