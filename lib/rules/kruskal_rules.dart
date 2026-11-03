import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

/// Reglas de edición para Kruskal.
///
/// Kruskal trabaja con grafos NO dirigidos y ponderados. No se permiten
/// aristas dirigidas ni lazos; las aristas repetidas ya las rechaza GraphRules.
class KruskalRules extends GraphRules {
  @override
  String? checkEdgeEndpoints(Graph graph, String fromId, String toId) {
    final message = super.checkEdgeEndpoints(graph, fromId, toId);
    if (message != null) return message;
    if (fromId == toId) return "Self loops aren't allowed in Kruskal";
    return null;
  }

  @override
  String? checkAddEdge(Graph graph, String fromId, String toId, bool directed) {
    final message = super.checkAddEdge(graph, fromId, toId, directed);
    if (message != null) return message;
    if (directed) {
      return "Directed edges aren't allowed in Kruskal: choose Non-directed";
    }
    return null;
  }

  @override
  List<String> validateGraph(Graph graph) {
    for (final edge in graph.edges.values) {
      if (edge.directed) {
        return ["Directed edges aren't allowed in Kruskal"];
      }
      if (edge.isLoop()) {
        return ["Self loops aren't allowed in Kruskal"];
      }
    }
    return [];
  }
}
