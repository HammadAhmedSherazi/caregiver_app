import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Paints [child] shifted upward while reducing layout height by [overlap].
class VerticalOverlap extends SingleChildRenderObjectWidget {
  const VerticalOverlap({
    super.key,
    required this.overlap,
    required super.child,
  });

  final double overlap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderVerticalOverlap(overlap);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderVerticalOverlap renderObject,
  ) {
    renderObject.overlap = overlap;
  }
}

class RenderVerticalOverlap extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  RenderVerticalOverlap(double overlap) : _overlap = overlap;

  double _overlap;

  double get overlap => _overlap;

  set overlap(double value) {
    if (_overlap == value) {
      return;
    }
    _overlap = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }

    child.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(
        child.size.width,
        math.max(0, child.size.height - _overlap),
      ),
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) {
      return;
    }

    context.paintChild(child, offset - Offset(0, _overlap));
  }

  @override
  void applyPaintTransform(covariant RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, -_overlap, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) {
      return false;
    }

    return result.addWithPaintTransform(
      transform: Matrix4.translationValues(0, -_overlap, 0),
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        return child.hitTest(result, position: transformed);
      },
    );
  }
}
