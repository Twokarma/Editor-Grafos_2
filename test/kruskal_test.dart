import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/kruskal.dart';

KruskalResult solve(
  int n,
  List<List<num>> edges, {
  KruskalGoal goal = KruskalGoal.minimum,
}) {
  return KruskalAlgorithm.solve(
    nodeIds: [for (var i = 0; i < n; i++) 'n$i'],
    edges: [
      for (var k = 0; k < edges.length; k++)
        KruskalEdge('e$k', 'n${edges[k][0].toInt()}', 'n${edges[k][1].toInt()}',
            edges[k][2].toDouble()),
    ],
    goal: goal,
  );
}

void main() {
  // Grafo clásico de 7 nodos (A..G = 0..6).
  final classic = <List<num>>[
    [0, 1, 7], [0, 3, 5], [1, 2, 8], [1, 3, 9], [1, 4, 7],
    [2, 4, 5], [3, 4, 15], [3, 5, 6], [4, 5, 8], [4, 6, 9], [5, 6, 11],
  ];

  group('Kruskal', () {
    test('árbol mínimo del grafo clásico = 39', () {
      final r = solve(7, classic);
      expect(r.totalWeight, 39);
      expect(r.treeEdges, hasLength(6));
      expect(r.isConnected, isTrue);
      expect(r.components, 1);
    });

    test('árbol máximo del grafo clásico = 59', () {
      final r = solve(7, classic, goal: KruskalGoal.maximum);
      expect(r.totalWeight, 59);
      expect(r.treeEdges, hasLength(6));
    });

    test('las aristas se consideran en orden de peso', () {
      final r = solve(7, classic);
      final weights = [for (final s in r.steps) s.edge.weight];
      final sorted = [...weights]..sort();
      expect(weights, sorted);
      final max = solve(7, classic, goal: KruskalGoal.maximum);
      final w2 = [for (final s in max.steps) s.edge.weight];
      expect(w2, [...w2]..sort((a, b) => b.compareTo(a)));
    });

    test('cada arista tiene una decisión y el árbol coincide con las aceptadas', () {
      final r = solve(7, classic);
      expect(r.steps, hasLength(classic.length));
      final accepted = [
        for (final s in r.steps)
          if (s.decision == KruskalDecision.accepted) s.edge.id
      ];
      expect(accepted, [for (final e in r.treeEdges) e.id]);
      // Después de la última aceptada ya no hay más que "no hizo falta".
      expect(r.steps.last.componentsAfter, 1);
    });

    test('rechaza las aristas que cierran un ciclo', () {
      // Triángulo: la más pesada queda fuera.
      final r = solve(3, [
        [0, 1, 1],
        [1, 2, 2],
        [0, 2, 3],
      ]);
      expect(r.totalWeight, 3);
      expect(r.steps[2].decision, KruskalDecision.skipped); // árbol ya completo
      final r2 = solve(4, [
        [0, 1, 1],
        [1, 2, 2],
        [0, 2, 3],
        [2, 3, 10],
      ]);
      expect(r2.steps[2].decision, KruskalDecision.rejectedCycle);
      expect(r2.totalWeight, 13);
    });

    test('grafo no conexo: bosque de expansión', () {
      final r = solve(5, [
        [0, 1, 4],
        [1, 2, 1],
        [3, 4, 2],
      ]);
      expect(r.isConnected, isFalse);
      expect(r.components, 2);
      expect(r.treeEdges, hasLength(3));
      expect(r.totalWeight, 7);
    });

    test('nodos aislados cuentan como componentes', () {
      final r = solve(4, [
        [0, 1, 2],
      ]);
      expect(r.components, 3);
      expect(r.totalWeight, 2);
    });

    test('pesos negativos y empates', () {
      final r = solve(3, [
        [0, 1, -5],
        [1, 2, -5],
        [0, 2, -5],
      ]);
      expect(r.totalWeight, -10);
      // Empate: gana el orden original (e0 y e1 entran, e2 sobra).
      expect([for (final e in r.treeEdges) e.id], ['e0', 'e1']);
    });

    test('un solo nodo o sin aristas', () {
      final r = solve(1, []);
      expect(r.treeEdges, isEmpty);
      expect(r.totalWeight, 0);
      expect(r.isConnected, isTrue);
      final r0 = solve(0, []);
      expect(r0.steps, isEmpty);
    });

    test('un lazo nunca entra al árbol', () {
      final r = solve(2, [
        [0, 0, 1],
        [0, 1, 5],
      ]);
      expect(r.steps.first.decision, KruskalDecision.rejectedCycle);
      expect(r.totalWeight, 5);
    });

    test('valida la entrada', () {
      expect(
        () => KruskalAlgorithm.solve(
          nodeIds: const ['a', 'a'],
          edges: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => KruskalAlgorithm.solve(
          nodeIds: const ['a'],
          edges: const [KruskalEdge('e', 'a', 'b', 1)],
        ),
        throwsArgumentError,
      );
      expect(
        () => KruskalAlgorithm.solve(
          nodeIds: const ['a', 'b'],
          edges: const [KruskalEdge('e', 'a', 'b', double.nan)],
        ),
        throwsArgumentError,
      );
    });
  });
}
