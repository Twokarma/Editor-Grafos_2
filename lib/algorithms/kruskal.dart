/// Algoritmo de Kruskal: árbol de expansión de costo mínimo (o máximo).
///
/// Dart puro (sin imports de Flutter) para poder probarlo en DartPad.
///
/// Idea: se ordenan las aristas por peso y se recorren de a una. Cada arista
/// se acepta si une dos componentes distintas y se rechaza si cerraría un ciclo
/// (sus dos extremos ya están conectados). Se detiene cuando el árbol está
/// completo (n - 1 aristas) o cuando se acaban las aristas.
///
/// Si el grafo no es conexo no existe un árbol que cubra todos los nodos; el
/// resultado es entonces un bosque de expansión (un árbol por componente).
library;

enum KruskalGoal { minimum, maximum }

enum KruskalDecision {
  /// Une dos componentes distintas: entra al árbol.
  accepted,

  /// Sus extremos ya estaban conectados: cerraría un ciclo.
  rejectedCycle,

  /// El árbol ya estaba completo; no hizo falta mirarla.
  skipped,
}

/// Arista no dirigida entre dos nodos (por id).
class KruskalEdge {
  final String id;
  final String source;
  final String target;
  final double weight;
  const KruskalEdge(this.id, this.source, this.target, this.weight);
}

/// Una arista en el orden en que Kruskal la consideró.
class KruskalStep {
  final KruskalEdge edge;
  final KruskalDecision decision;

  /// Componentes conexas que quedan después de este paso.
  final int componentsAfter;

  /// Peso acumulado del árbol después de este paso.
  final double totalAfter;

  const KruskalStep({
    required this.edge,
    required this.decision,
    required this.componentsAfter,
    required this.totalAfter,
  });
}

class KruskalResult {
  final KruskalGoal goal;
  final int nodeCount;

  /// Todas las aristas, en el orden en que se consideraron.
  final List<KruskalStep> steps;

  /// Aristas del árbol (o bosque), en el orden en que se aceptaron.
  final List<KruskalEdge> treeEdges;

  final double totalWeight;

  /// Componentes conexas del grafo original (1 = conexo).
  final int components;

  const KruskalResult({
    required this.goal,
    required this.nodeCount,
    required this.steps,
    required this.treeEdges,
    required this.totalWeight,
    required this.components,
  });

  /// true si el resultado es un árbol que cubre todos los nodos.
  bool get isConnected => components <= 1;
}

class KruskalAlgorithm {
  static KruskalResult solve({
    required List<String> nodeIds,
    required List<KruskalEdge> edges,
    KruskalGoal goal = KruskalGoal.minimum,
  }) {
    final index = <String, int>{};
    for (var i = 0; i < nodeIds.length; i++) {
      if (index.containsKey(nodeIds[i])) {
        throw ArgumentError('Node id repeated: ${nodeIds[i]}');
      }
      index[nodeIds[i]] = i;
    }
    for (final e in edges) {
      if (!index.containsKey(e.source) || !index.containsKey(e.target)) {
        throw ArgumentError('Edge ${e.id} uses a node that does not exist');
      }
      if (!e.weight.isFinite) {
        throw ArgumentError('Edge ${e.id} has a weight that is not a finite number');
      }
    }

    // Orden por peso (ascendente o descendente); a igual peso, el orden original.
    final order = List<int>.generate(edges.length, (i) => i);
    order.sort((a, b) {
      final wa = edges[a].weight;
      final wb = edges[b].weight;
      final cmp = wa < wb ? -1 : (wa > wb ? 1 : 0);
      final byWeight = goal == KruskalGoal.minimum ? cmp : -cmp;
      return byWeight != 0 ? byWeight : a.compareTo(b);
    });

    // Union-Find con compresión de caminos y unión por rango.
    final parent = List<int>.generate(nodeIds.length, (i) => i);
    final rank = List<int>.filled(nodeIds.length, 0);

    int find(int x) {
      var root = x;
      while (parent[root] != root) {
        root = parent[root];
      }
      while (parent[x] != root) {
        final next = parent[x];
        parent[x] = root;
        x = next;
      }
      return root;
    }

    var components = nodeIds.length;
    final needed = nodeIds.isEmpty ? 0 : nodeIds.length - 1;
    final steps = <KruskalStep>[];
    final tree = <KruskalEdge>[];
    var total = 0.0;

    for (final k in order) {
      final e = edges[k];

      if (tree.length >= needed) {
        steps.add(KruskalStep(
          edge: e,
          decision: KruskalDecision.skipped,
          componentsAfter: components,
          totalAfter: total,
        ));
        continue;
      }

      final ra = find(index[e.source]!);
      final rb = find(index[e.target]!);
      if (ra == rb) {
        steps.add(KruskalStep(
          edge: e,
          decision: KruskalDecision.rejectedCycle,
          componentsAfter: components,
          totalAfter: total,
        ));
        continue;
      }

      if (rank[ra] < rank[rb]) {
        parent[ra] = rb;
      } else if (rank[ra] > rank[rb]) {
        parent[rb] = ra;
      } else {
        parent[rb] = ra;
        rank[ra] += 1;
      }
      components -= 1;
      total += e.weight;
      tree.add(e);
      steps.add(KruskalStep(
        edge: e,
        decision: KruskalDecision.accepted,
        componentsAfter: components,
        totalAfter: total,
      ));
    }

    return KruskalResult(
      goal: goal,
      nodeCount: nodeIds.length,
      steps: steps,
      treeEdges: tree,
      totalWeight: total,
      components: components,
    );
  }
}
