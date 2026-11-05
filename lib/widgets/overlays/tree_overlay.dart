import 'dart:math';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';

import 'canvas_overlay.dart';

class TreeOverlay extends CanvasOverlay {
  final Map<String, int> visitOrder;

  const TreeOverlay({this.visitOrder = const {}});

  @override
  bool get showsEdgeWeights => false;

  @override
  void paintAfterNodes(OverlayPaintContext paintCtx) {
    if (visitOrder.isEmpty) return;
    final Paint fill = Paint()..color = AppColors.treeOrderBadge;
    final Paint border = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    visitOrder.forEach((nodeId, position) {
      final node = paintCtx.nodes[nodeId];
      if (node == null) return;
      final Offset center = paintCtx.positionOf(node);
      final double reach = node.radius * cos(pi / 4);
      final Offset badge = center + Offset(reach, -reach);
      const double badgeRadius = 11;

      paintCtx.canvas.drawCircle(badge, badgeRadius, fill);
      paintCtx.canvas.drawCircle(badge, badgeRadius, border);
      final TextPainter text = TextPainter(
        text: TextSpan(
          text: '$position',
          style: const TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(paintCtx.canvas, badge - Offset(text.width / 2, text.height / 2));
    });
  }
}
