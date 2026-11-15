import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/node.dart';

import '../../models/edge.dart';

class OverlayPaintContext {
  final Canvas canvas;
  final Map<String, Node> nodes;
  final Offset Function(Node) positionOf;
  final Map<String, Edge> edges;

  OverlayPaintContext({required this.canvas, required this.nodes, required this.positionOf, this.edges = const {}});
}

abstract class CanvasOverlay {

  const CanvasOverlay();

  Color? edgeColor(Edge edge){
    return null;
  }

  double? edgeStroke(Edge edge){
    return null;
  }

  bool get showsEdgeWeights => true;

  String edgeLabelSuffix(Edge edge){
    return "";
  }

  Color? pathNodeColor(String nodeId, Map<String, Edge> edges){
    return null;
  }

  Offset namePosition(Node node){
    return Offset.zero;
  }

  void paintAfterEdges(OverlayPaintContext paintCtx){

  }

  void paintAfterNodes(OverlayPaintContext paintCtx){

  }
}

class DefaultOverlay extends CanvasOverlay {
  const DefaultOverlay();
}