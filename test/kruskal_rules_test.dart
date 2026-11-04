import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/rules/kruskal_rules.dart';

void main() {
  final rules = KruskalRules();
  late Graph graph; // nodos n0, n1, n2

  setUp(() {
    graph = Graph();
    graph.addNode(0, 0);
    graph.addNode(200, 0);
    graph.addNode(400, 0);
  });

  test('permite aristas no dirigidas', () {
    expect(rules.checkAddEdge(graph, 'n0', 'n1', false), isNull);
  });

  test('no permite aristas dirigidas', () {
    expect(rules.checkAddEdge(graph, 'n0', 'n1', true), isNotNull);
  });

  test('no permite lazos', () {
    expect(rules.checkEdgeEndpoints(graph, 'n0', 'n0'), isNotNull);
  });

  test('no permite repetir una arista (ni en sentido contrario)', () {
    graph.addEdge('n0', 'n1', 5, directed: false);
    expect(rules.checkEdgeEndpoints(graph, 'n0', 'n1'), isNotNull);
    expect(rules.checkEdgeEndpoints(graph, 'n1', 'n0'), isNotNull);
  });

  test('un grafo no dirigido es válido', () {
    graph.addEdge('n0', 'n1', 5, directed: false);
    graph.addEdge('n1', 'n2', 7, directed: false);
    expect(rules.validateGraph(graph), isEmpty);
  });

  test('validateGraph rechaza aristas dirigidas', () {
    graph.addEdge('n0', 'n1', 5);
    expect(rules.validateGraph(graph), isNotEmpty);
  });
}
