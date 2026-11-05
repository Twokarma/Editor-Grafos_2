import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/graph_rules.dart';

/// Reglas de edición para Dijkstra.
///
/// Dijkstra trabaja con grafos ponderados que pueden mezclar aristas dirigidas
/// y no dirigidas, así que no se restringe el tipo de arista (a diferencia de
/// KruskalRules). Lo único que no admite son pesos negativos. Los lazos se
/// permiten porque el algoritmo simplemente los ignora.
class DijkstraRules extends GraphRules {
  @override
  List<String> validateGraph(Graph graph) {
    for (final edge in graph.edges.values) {
      if (edge.weight < 0) {
        return ["Dijkstra doesn't support negative weights"];
      }
    }
    return [];
  }
}