import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/models/bolo.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/canvas/canvas_insets.dart';

class SortCanvas extends StatelessWidget {
  final List<int> values;
  final SortMarks marks;
  final Duration liftDuration;

  const SortCanvas({super.key, required this.values, required this.marks, required this.liftDuration});

  static const double _padding = 24;
  static const double _gap = 8;
  static const double _maxScale = 0.9;
  static const double _minShare = 0.4;
  static const double _lift = 0.12;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets insets = CanvasInsets.maybeOf(context)?.insets ?? EdgeInsets.zero;
    return Stack(
      fit: StackFit.expand,
      children: [
        const RepaintBoundary(child: CustomPaint(painter: _DotGridPainter())),
        Padding(
          padding: insets + const EdgeInsets.all(_padding),
          child: LayoutBuilder(builder: (context, constraints) => _pins(constraints.biggest)),
        ),
      ],
    );
  }

  Widget _pins(Size area) {
    if (values.isEmpty || area.isEmpty) return const SizedBox.shrink();
    final int n = values.length;
    final double slot = (area.width - _gap * (n - 1)) / n;
    final double fullScale = min(_maxScale, min(slot / BoloPainter.anchoBase, area.height / (1 + _lift) / BoloPainter.altoBase));
    final int low = values.reduce(min);
    final int high = values.reduce(max);

    double scaleOf(int value) {
      if (high == low) return fullScale;
      return fullScale * (_minShare + (1 - _minShare) * (value - low) / (high - low));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (int i = 0; i < n; i++) ...[
          if (i > 0) const SizedBox(width: _gap),
          SizedBox(
            width: BoloPainter.anchoBase * fullScale,
            child: Center(
              child: AnimatedSlide(
                offset: Offset(0, marks.isRaised(i) ? -_lift : 0),
                duration: liftDuration,
                curve: Curves.easeOut,
                child: Bolo(
                  escala: max(scaleOf(values[i]), 0.01),
                  color: marks.roleOf(i)?.color ?? AppColors.white,
                  numero: values[i],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  static const double _spacing = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint dot = Paint()..color = AppColors.gridColor;
    for (double y = _spacing / 2; y < size.height; y += _spacing) {
      for (double x = _spacing / 2; x < size.width; x += _spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter oldDelegate) => false;
}
