import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/dijkstra.dart';

DijkstraEdge d(String id, String s, String t, double w) => DijkstraEdge(id, s, t, w, directed: true);

void main() {
  group('Dijkstra maximize', () {
    test('finds the longest path in a directed acyclic graph', () {
      // A→B 1, A→C 5, B→D 10, C→D 2, B→C 1
      final r = DijkstraAlgorithm.solve(
        nodeIds: ['A', 'B', 'C', 'D'],
        edges: [d('1', 'A', 'B', 1), d('2', 'A', 'C', 5), d('3', 'B', 'D', 10), d('4', 'C', 'D', 2), d('5', 'B', 'C', 1)],
        sourceId: 'A',
        targetId: 'D',
        maximize: true,
      );
      expect(r.maximize, isTrue);
      expect(r.totalDistance, 11);
      expect(r.pathNodeIds, ['A', 'B', 'D']);
      // Minimizing the same graph still gives the shortest path.
      final min = DijkstraAlgorithm.solve(
        nodeIds: ['A', 'B', 'C', 'D'],
        edges: [d('1', 'A', 'B', 1), d('2', 'A', 'C', 5), d('3', 'B', 'D', 10), d('4', 'C', 'D', 2), d('5', 'B', 'C', 1)],
        sourceId: 'A',
        targetId: 'D',
      );
      expect(min.totalDistance, 4);
      expect(min.pathNodeIds, ['A', 'B', 'C', 'D']);
    });

    test('fixes nodes in topological order and allows negative weights', () {
      final r = DijkstraAlgorithm.solve(
        nodeIds: ['A', 'B', 'C'],
        edges: [d('1', 'A', 'B', -2), d('2', 'B', 'C', 3), d('3', 'A', 'C', 0)],
        sourceId: 'A',
        targetId: 'C',
        maximize: true,
      );
      expect(r.steps.map((s) => s.nodeId), ['A', 'B', 'C']);
      expect(r.totalDistance, 1);
    });

    test('unreachable target gives no path', () {
      final r = DijkstraAlgorithm.solve(
        nodeIds: ['A', 'B', 'C'],
        edges: [d('1', 'A', 'B', 2), d('2', 'C', 'A', 1)],
        sourceId: 'A',
        targetId: 'C',
        maximize: true,
      );
      expect(r.reachable, isFalse);
      expect(r.totalDistance, double.negativeInfinity);
    });

    test('rejects cycles, loops and non-directed edges reachable from the origin', () {
      DijkstraResult run(List<DijkstraEdge> edges) => DijkstraAlgorithm.solve(
            nodeIds: ['A', 'B', 'C'],
            edges: edges,
            sourceId: 'A',
            targetId: 'C',
            maximize: true,
            names: {'A': 'A', 'B': 'B', 'C': 'C'},
          );
      expect(() => run([d('1', 'A', 'B', 1), d('2', 'B', 'A', 1), d('3', 'B', 'C', 1)]), throwsArgumentError);
      expect(() => run([d('1', 'A', 'B', 1), d('2', 'B', 'B', 1)]), throwsArgumentError);
      expect(() => run([const DijkstraEdge('1', 'A', 'B', 1)]), throwsArgumentError);
    });

    test('ignores cycles that cannot be reached from the origin', () {
      final r = DijkstraAlgorithm.solve(
        nodeIds: ['A', 'B', 'X', 'Y'],
        edges: [d('1', 'A', 'B', 4), d('2', 'X', 'Y', 1), d('3', 'Y', 'X', 1)],
        sourceId: 'A',
        targetId: 'B',
        maximize: true,
      );
      expect(r.totalDistance, 4);
    });
  });
}
