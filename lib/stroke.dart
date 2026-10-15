import 'package:flutter/material.dart';

/// A single sampled point along a stroke.
///
/// The [width] is pre-computed by `NibModel` at the moment the point is
/// captured. It is derived purely from movement direction, nib orientation,
/// and smoothing -- pressure is never involved.
class StrokePoint {
  StrokePoint({
    required this.position,
    required this.timestamp,
    required this.width,
  });

  final Offset position;
  final DateTime timestamp;
  final double width;
}

/// A single continuous pen-down-to-pen-up stroke.
class Stroke {
  Stroke({List<StrokePoint>? points}) : points = points ?? <StrokePoint>[];

  final List<StrokePoint> points;
}