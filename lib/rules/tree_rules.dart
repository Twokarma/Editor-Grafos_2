import 'dart:collection';

import 'package:graph_maker_app_2/algorithms/binary_tree.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

import '../models/edge.dart';
import '../models/graph.dart';

class TreeRules extends GraphRules{
  @override
  bool forcesDirected() {
    return true;
  }

  @override
  bool get nodesAreValues => true;

  @override
  double? get autoEdgeWeight => 0;

  @override
  String? checkNodeName(Graph graph, String? nodeId, String name) {
    final double? value = BinaryTree.parseValue(name);
    if (value == null) return "Escribe un número (los decimales van con punto: 3.5)";
    if (nodeId == null) return null;
    return BinaryTree.checkValueChange(graph, nodeId, value);
  }

  @override
  String normalizeNodeName(String name) {
    final double? value = BinaryTree.parseValue(name);
    return value == null ? name : BinaryTree.formatValue(value);
  }

  @override
  String? checkEdgeEndpoints(Graph graph, String fromId, String toId) {
    String? message = super.checkEdgeEndpoints(graph, fromId, toId);
    if (message != null) return message;

    if(fromId == toId) return "Un nodo no puede ser su propio hijo";
    if(graph.findReverseEdge(fromId, toId) != null) return "Ese nodo ya es el padre";
    if(graph.findEdgesTo(toId).isNotEmpty) return "Este nodo ya tiene padre";

    Set<String> visitedNodes = {};
    Queue<String> nodes = Queue();
    nodes.add(toId);
    while(nodes.isNotEmpty){
      String nodeId = nodes.removeFirst();
      if(nodeId == fromId) return "Esta arista formaría un ciclo";
      if(!visitedNodes.add(nodeId)) continue;
      for(Edge edge in graph.findEdgesFrom(nodeId)){
        nodes.add(edge.targetNodeId);
      }
    }

    return BinaryTree.checkPlacement(graph, fromId, toId);
  }

  @override
  List<String> validateGraph(Graph graph) {
    final String? error = BinaryTree.fromGraph(graph).error;
    return error == null ? [] : [error];
  }
}
