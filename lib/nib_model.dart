import 'dart:math';
import 'package:flutter/material.dart';

/// Simulates a direction-and-orientation-sensitive fountain pen nib.
///
/// Stroke width depends only on:
///  - the direction the pen is currently moving (dx/dy of the segment)
///  - the configured nib orientation angle, which rotates which movement
///    directions read as thick vs. thin
///  - a smoothing factor that prevents abrupt width jumps between samples
///
/// This class never reads pressure, force, or any stylus pressure API.
/// Pressure has zero influence on the resulting width.
class NibModel {
  NibModel({
    this.thinWidth = 2.0,
    this.thickWidth = 14.0,
    this.nibAngle = 0.0, // degrees, expected range 0-180
    this.smoothing = 0.6, // 0 = no smoothing, close to 1 = heavy smoothing
  });

  double thinWidth;
  double thickWidth;
  double nibAngle;
  double smoothing;

  // --- Internal smoothing state, reset at the start of each stroke --------

  double? _lastWidth;

  // --- Debug telemetry, populated by widthForSegment for the overlay ------

  double lastMovementAngleRadians = 0.0;
  double lastNibAngleRadians = 0.0;
  double lastRawWidth = 0.0;
  double lastSmoothedWidth = 0.0;

  /// Must be called whenever a new stroke begins so smoothing does not
  /// carry width state over from a previous, unrelated stroke.
  void resetStrokeState() {
    _lastWidth = null;
  }

  /// Computes the width for the segment between [previous] and [current].
  ///
  /// This never reads pressure of any kind. Width is derived purely from
  /// movement direction, the configured nib angle, and smoothing.
  double widthForSegment(Offset previous, Offset current) {
    final double dx = current.dx - previous.dx;
    final double dy = current.dy - previous.dy;

    // No meaningful movement: hold the last width so nothing jumps.
    if (dx == 0 && dy == 0) {
      final held = _lastWidth ?? _mediumWidth();
      _lastWidth = held;
      return held;
    }

    final double movementAngle = atan2(dy, dx);
    final double nibAngleRadians = nibAngle * pi / 180.0;

    // Rotate the movement direction into the nib's own reference frame.
    // This is what makes changing the nib angle rotate which directions
    // read as thick or thin.
    final double effectiveAngle = movementAngle - nibAngleRadians;

    // Smooth, threshold-free mapping from direction to a 0..1 factor.
    //   sin(+90 deg) ==  1  -> "down" in nib space   -> thick
    //   sin(-90 deg) == -1  -> "up" in nib space      -> thin
    //   sin(0)/(180) ==  0  -> horizontal in nib space -> medium
    final double factor = (sin(effectiveAngle) + 1.0) / 2.0;

    final double rawWidth = thinWidth + (thickWidth - thinWidth) * factor;

    // Exponential smoothing against the previous width so there are never
    // visible jumps, even when direction changes sharply between samples.
    final double previousWidth = _lastWidth ?? rawWidth;
    final double smoothingClamped = smoothing.clamp(0.0, 0.95);
    final double smoothedWidth = previousWidth +
        (rawWidth - previousWidth) * (1.0 - smoothingClamped);

    _lastWidth = smoothedWidth;

    // Store telemetry for the debug overlay.
    lastMovementAngleRadians = movementAngle;
    lastNibAngleRadians = nibAngleRadians;
    lastRawWidth = rawWidth;
    lastSmoothedWidth = smoothedWidth;

    return smoothedWidth;
  }

  double _mediumWidth() => (thinWidth + thickWidth) / 2.0;
}