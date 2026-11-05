/// Dijkstra sobre un grafo con aristas dirigidas y no dirigidas mezcladas.
///
/// - Arista NO dirigida: se puede recorrer en ambos sentidos.
/// - Arista dirigida: solo de [DijkstraEdge.source] a [DijkstraEdge.target].
///
/// Los pesos deben ser no negativos. Se guarda el paso a paso (qué nodo se
/// fijó en cada vuelta y qué aristas se relajaron) para mostrarlo en pantalla.
class DijkstraEdge {
  final String id;
  final String source;
  final String target;
  final double weight;

  /// true si solo se puede ir de [source] a [target].
  final bool directed;

  const DijkstraEdge(
    this.id,
    this.source,
    this.target,
    this.weight, {
    this.directed = false,
  });
}

/// Intento de mejorar la distancia de [to] pasando por [from].
class DijkstraRelaxation {
  final DijkstraEdge edge;
  final String from;
  final String to;

  /// Distancia que se obtendría yendo por esta arista.
  final double candidate;

  /// Mejor distancia conocida de [to] antes de este intento (infinito si ninguna).
  final double previous;

  /// true si [candidate] mejoró la distancia de [to].
  final bool improved;

  const DijkstraRelaxation({
    required this.edge,
    required this.from,
    required this.to,
    required this.candidate,
    required this.previous,
    required this.improved,
  });
}

/// Una vuelta del algoritmo: se fija el nodo más cercano aún no visitado.
class DijkstraStep {
  final String nodeId;
  final double distance;
  final List<DijkstraRelaxation> relaxations;
  const DijkstraStep(this.nodeId, this.distance, this.relaxations);
}

class DijkstraResult {
  final String sourceId;
  final String targetId;

  /// Distancia mínima desde el origen a cada nodo (infinito si no se alcanza).
  final Map<String, double> distances;

  /// Nodos en el orden en que se fijaron, con sus relajaciones.
  final List<DijkstraStep> steps;

  /// Camino origen -> destino (vacío si el destino no es alcanzable).
  final List<String> pathNodeIds;
  final List<DijkstraEdge> pathEdges;

  const DijkstraResult({
    required this.sourceId,
    required this.targetId,
    required this.distances,
    required this.steps,
    required this.pathNodeIds,
    required this.pathEdges,
  });

  bool get reachable => pathNodeIds.isNotEmpty;
  double get totalDistance => distances[targetId] ?? double.infinity;
}

class DijkstraAlgorithm {
  /// Lanza [ArgumentError] si hay pesos negativos o ids que no existen.
  static DijkstraResult solve({
    required List<String> nodeIds,
    required List<DijkstraEdge> edges,
    required String sourceId,
    required String targetId,
  }) {
    if (!nodeIds.contains(sourceId) || !nodeIds.contains(targetId)) {
      throw ArgumentError('Origin or destination is not in the graph.');
    }
    for (final e in edges) {
      if (e.weight < 0) {
        throw ArgumentError(
          'Dijkstra does not support negative weights (edge with weight ${e.weight}).',
        );
      }
    }

    // Lista de adyacencia: una arista dirigida solo sale de su origen; una no
    // dirigida sale de ambos extremos.
    final adjacency = {for (final id in nodeIds) id: <DijkstraEdge>[]};
    for (final e in edges) {
      if (e.source == e.target) continue; // un lazo nunca acorta un camino
      adjacency[e.source]?.add(e);
      if (!e.directed) adjacency[e.target]?.add(e);
    }

    final dist = {for (final id in nodeIds) id: double.infinity};
    final cameFrom = <String, String>{}; // nodo anterior en el mejor camino
    final cameBy = <String, DijkstraEdge>{}; // arista usada para llegar al nodo
    final visited = <String>{};
    final steps = <DijkstraStep>[];

    dist[sourceId] = 0;

    while (true) {
      // Nodo no visitado con menor distancia.
      String? current;
      for (final id in nodeIds) {
        if (visited.contains(id) || dist[id] == double.infinity) continue;
        if (current == null || dist[id]! < dist[current]!) current = id;
      }
      if (current == null) break; // lo que queda no es alcanzable

      visited.add(current);
      final relaxations = <DijkstraRelaxation>[];

      for (final e in adjacency[current]!) {
        final neighbor = e.source == current ? e.target : e.source;
        if (visited.contains(neighbor)) continue;

        final candidate = dist[current]! + e.weight;
        final previous = dist[neighbor]!;
        final improved = candidate < previous;
        if (improved) {
          dist[neighbor] = candidate;
          cameFrom[neighbor] = current;
          cameBy[neighbor] = e;
        }
        relaxations.add(DijkstraRelaxation(
          edge: e,
          from: current,
          to: neighbor,
          candidate: candidate,
          previous: previous,
          improved: improved,
        ));
      }

      steps.add(DijkstraStep(current, dist[current]!, relaxations));
    }

    // Reconstruir el camino hacia atrás desde el destino.
    var pathNodes = <String>[];
    var pathEdges = <DijkstraEdge>[];
    if (dist[targetId] != double.infinity) {
      var node = targetId;
      pathNodes.add(node);
      while (node != sourceId) {
        pathEdges.add(cameBy[node]!);
        node = cameFrom[node]!;
        pathNodes.add(node);
      }
      pathNodes = pathNodes.reversed.toList();
      pathEdges = pathEdges.reversed.toList();
    }

    return DijkstraResult(
      sourceId: sourceId,
      targetId: targetId,
      distances: dist,
      steps: steps,
      pathNodeIds: pathNodes,
      pathEdges: pathEdges,
    );
  }
}