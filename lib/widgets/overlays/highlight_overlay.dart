import 'dart:ui';

import 'package:graph_maker_app_2/widgets/overlays/canvas_overlay.dart';

import '../../models/edge.dart';

class HighlightOverlay extends CanvasOverlay{
  final Set<String> highlightedEdges;
  final Color highlightColor;
  final bool ringPathNodes;

  const HighlightOverlay(this.highlightedEdges, this.highlightColor, {this.ringPathNodes = false});

  @override
  Color? pathNodeColor(String nodeId, Map<String, Edge> edges) {
    if (!ringPathNodes) return null;
    final bool onPath = edges.values.any((e) =>
        highlightedEdges.contains(e.id) && (e.sourceNodeId == nodeId || e.targetNodeId == nodeId));
    return onPath ? highlightColor : null;
  }

  @override
  Color? edgeColor(Edge edge) {
    if(!highlightedEdges.contains(edge.id)) {
      return super.edgeColor(edge);
    }
    return highlightColor;
  }

  @override
  double? edgeStroke(Edge edge) {
    if(!highlightedEdges.contains(edge.id)) {
      return super.edgeStroke(edge);
    }
    return 8;
  }
}