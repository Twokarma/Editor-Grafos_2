import 'dart:math';
import 'dart:ui' show PointMode;

import 'package:flutter/cupertino.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';
import 'package:graph_maker_app_2/widgets/canvas_drawing.dart';
import 'package:graph_maker_app_2/widgets/overlays/canvas_overlay.dart';

import '../models/edge.dart';
import '../models/graph.dart';
import '../models/node.dart';
import '../theme/app_colors.dart';

class GraphPainter extends CustomPainter{
  final Map<String, Node> nodes;
  final Map<String, Edge> edges;
  final String dragSourceId;
  final Offset? dragCurrentPosition;
  final String? movingNodeId;
  final Offset? movingNodePosition;
  final CanvasOverlay canvasOverlay;
  final AppViewport viewport;
  final bool showGrid;

  GraphPainter({
    required this.nodes,
    required this.edges,
    required this.dragSourceId,
    required this.dragCurrentPosition,
    this.movingNodeId,
    this.movingNodePosition,
    this.canvasOverlay = const DefaultOverlay(),
    required this.viewport,
    this.showGrid = true,
  });

  Offset _positionOf(Node node) {
    if (node.id == movingNodeId && movingNodePosition != null) {
      return movingNodePosition!;
    }
    return Offset(node.x, node.y);
  }

  static const double _parallelEdgeOffset = 7.5;
  static const double _labelGap = 8;
  static const double _movingRingWidth = 4.5;

  static const double _gridSpacing = 24;
  static const double _gridMinScreenSpacing = 14;
  static const double _gridDotSize = 2.4;

  void _paintGrid(Canvas canvas, Size size) {
    double spacing = _gridSpacing;
    while (spacing * viewport.scale < _gridMinScreenSpacing) {
      spacing *= 2;
    }
    final Rect visible = viewport.visibleWorldRect(size);
    final double startX = (visible.left / spacing).floorToDouble() * spacing + spacing / 2;
    final double startY = (visible.top / spacing).floorToDouble() * spacing + spacing / 2;
    final List<Offset> points = [];
    for (double y = startY; y <= visible.bottom + spacing; y += spacing) {
      for (double x = startX; x <= visible.right + spacing; x += spacing) {
        points.add(viewport.toScreen(Offset(x, y)));
      }
    }
    canvas.drawPoints(
      PointMode.points,
      points,
      Paint()
        ..color = AppColors.gridColor
        ..strokeWidth = _gridDotSize
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    if (showGrid) _paintGrid(canvas, size);

    canvas.save();
    canvas.translate(viewport.offset.dx, viewport.offset.dy);
    canvas.scale(viewport.scale);

    final paint = Paint()
      ..color = AppColors.previewEdge
      ..strokeWidth = 5;

    edges.forEach((id, edge){
      Node? sourceNode = nodes[edge.sourceNodeId];
      Node? targetNode = nodes[edge.targetNodeId];
      if (sourceNode == null || targetNode == null) return;

      if (edge.isLoop()) {
        final pos = _positionOf(sourceNode);
        final edgeColor = canvasOverlay.edgeColor(edge) ?? AppColors.selfLoopEdge;
        final stroke = canvasOverlay.edgeStroke(edge) ?? 5.0;
        Draw.drawSelfLoop(canvas, pos, sourceNode.radius, edgeColor, stroke);

        final loopCenter = Offset(pos.dx + Graph.selfLoopCenterDistance(sourceNode.radius), pos.dy);
        final label = TextPainter(
          text: TextSpan(
              text: "${edge.weight.toString()}${canvasOverlay.edgeLabelSuffix(edge)}",
              style: TextStyle(
                color: edgeColor,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )
          ),
          textDirection: TextDirection.ltr,
        );
        label.layout();
        if (canvasOverlay.showsEdgeWeights) label.paint(canvas, Offset(loopCenter.dx - label.width / 2, loopCenter.dy + Graph.selfLoopRadius + 4));
        return;
      }

      final sourcePos = _positionOf(sourceNode);
      final targetPos = _positionOf(targetNode);

      final dx = targetPos.dx - sourcePos.dx;
      final dy = targetPos.dy - sourcePos.dy;
      final distance = sqrt(dx * dx + dy * dy);
      if (distance == 0) return;

      final ux = dx / distance;
      final uy = dy / distance;
      final edgeColor = canvasOverlay.edgeColor(edge) ?? (dx >= 0 ? AppColors.leftRightEdge : AppColors.rightLeftEdge);
      final stroke = canvasOverlay.edgeStroke(edge) ?? 5.0;

      final perpX = -uy;
      final perpY = ux;
      final hasMirror = edges.values.any((e) =>
      e.sourceNodeId == edge.targetNodeId && e.targetNodeId == edge.sourceNodeId);
      final lineOffset = hasMirror ? _parallelEdgeOffset : 0.0;

      final offsetSourcePos = Offset(sourcePos.dx + perpX * lineOffset, sourcePos.dy + perpY * lineOffset);
      final offsetTargetPos = Offset(targetPos.dx + perpX * lineOffset, targetPos.dy + perpY * lineOffset);

      Draw.drawDirectedEdge(canvas, offsetSourcePos, offsetTargetPos, targetNode.radius, ux, uy, edgeColor, edge.directed, stroke);

      final midX = (offsetSourcePos.dx + offsetTargetPos.dx) / 2 + perpX * Draw.labelOffset;
      final midY = (offsetSourcePos.dy + offsetTargetPos.dy) / 2 + perpY * Draw.labelOffset;

      //String h = holgura.containsKey(edge.id)? " h = ${holgura[edge.id]}" : "";
      final label = TextPainter(
        text: TextSpan(
            text: "${edge.weight}${canvasOverlay.edgeLabelSuffix(edge)}",
            style: TextStyle(
              color: edgeColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      if (canvasOverlay.showsEdgeWeights) label.paint(canvas, Offset(midX - label.width / 2, midY - label.height / 2));
    });

    canvasOverlay.paintAfterEdges(OverlayPaintContext(canvas: canvas, nodes: nodes, positionOf: _positionOf, edges: edges));

    if(dragSourceId != "" && dragSourceId != "tooClose" && dragCurrentPosition != null) {
      final dragSource = nodes[dragSourceId];
      if (dragSource != null) {
        canvas.drawLine(_positionOf(dragSource), dragCurrentPosition!, paint);
      }
    }

    nodes.forEach((id, node){
      final pos = _positionOf(node);
      final pathColor = canvasOverlay.pathNodeColor(id, edges);
      final nodeColor = pathColor ?? Color(node.color);
      canvas.drawCircle(pos, node.radius, Paint()..color = nodeColor);
      final ringColor = pathColor ?? (id == movingNodeId ? nodeColor : null);
      if (ringColor != null) {
        final ring = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = _movingRingWidth;
        canvas.drawCircle(pos, node.radius + _movingRingWidth / 2, ring..color = AppColors.canvasBackground);
        canvas.drawCircle(pos, node.radius + _movingRingWidth * 1.5, ring..color = ringColor);
      }

      final labelColor = nodeColor.computeLuminance() > 0.179 ? AppColors.darkNodeLabel : AppColors.lightNodeLabel;
      final label = TextPainter(
        text: TextSpan(
            text: node.name,
            style: TextStyle(
              color: labelColor,
              fontSize: 15,
            )
        ),
        textDirection: TextDirection.ltr,
      );
      label.layout();
      Offset namePos = canvasOverlay.namePosition(node) + Offset(pos.dx-10, pos.dy-10);
      label.paint(canvas, namePos);
    });

    canvasOverlay.paintAfterNodes(OverlayPaintContext(canvas: canvas, nodes: nodes, positionOf: _positionOf, edges: edges));

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant GraphPainter oldDelegate) {
    return true;
  }
}
