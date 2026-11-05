import 'dart:math';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/binary_tree.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/models/node.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/rules/tree_rules.dart';

Graph exampleGraph() {
  final g = Graph();
  void node(String id, String value, double x, double y) => g.nodes[id] = Node(id, value, x, y, 30);
  node('a', '7', 300, 40);
  node('b', '4', 150, 140);
  node('c', '8', 400, 140);
  node('d', '2', 80, 240);
  node('e', '5', 220, 240);
  node('f', '9', 500, 240);
  g.addEdge('a', 'b', 0);
  g.addEdge('a', 'c', 0);
  g.addEdge('b', 'd', 0);
  g.addEdge('b', 'e', 0);
  g.addEdge('c', 'f', 0);
  return g;
}

const pre = ['7', '4', '2', '5', '8', '9'];
const ino = ['2', '4', '5', '7', '8', '9'];
const post = ['2', '5', '4', '9', '8', '7'];

void main() {
  group('valores', () {
    test('parse y formato', () {
      expect(BinaryTree.parseValue(' 3.5 '), 3.5);
      expect(BinaryTree.parseValue('-2'), -2);
      expect(BinaryTree.parseValue('A'), isNull);
      expect(BinaryTree.parseValue('NaN'), isNull);
      expect(BinaryTree.formatValue(5.0), '5');
      expect(BinaryTree.formatValue(3.5), '3.5');
      expect(BinaryTree.formatValue(-0.25), '-0.25');
    });
  });

  group('grafo → árbol', () {
    test('lee los tres recorridos del ejemplo', () {
      final result = BinaryTree.fromGraph(exampleGraph());
      expect(result.isOk, isTrue);
      expect(BinaryTree.labels(result.root, Traversal.pre), pre);
      expect(BinaryTree.labels(result.root, Traversal.inorder), ino);
      expect(BinaryTree.labels(result.root, Traversal.post), post);
    });

    test('un grafo vacío no es un error', () {
      final result = BinaryTree.fromGraph(Graph());
      expect(result.isOk, isTrue);
      expect(result.root, isNull);
    });

    test('el lado lo decide el valor, no la posición', () {
      final g = exampleGraph();
      g.nodes['f']!.x = 350;
      final result = BinaryTree.fromGraph(g);
      expect(result.root!.right!.right!.label, '9');
      expect(BinaryTree.labels(result.root, Traversal.inorder), ino);
    });

    test('valor igual al padre va a la izquierda', () {
      final g = Graph();
      g.nodes['a'] = Node('a', '5', 100, 40, 30);
      g.nodes['b'] = Node('b', '5', 200, 140, 30);
      g.addEdge('a', 'b', 0);
      final result = BinaryTree.fromGraph(g);
      expect(result.root!.left!.label, '5');
      expect(result.root!.right, isNull);
    });

    test('regla de todos los ancestros (7 → 4 → 9 no vale)', () {
      final g = Graph();
      g.nodes['a'] = Node('a', '7', 100, 40, 30);
      g.nodes['b'] = Node('b', '4', 50, 140, 30);
      g.nodes['c'] = Node('c', '9', 150, 240, 30);
      g.addEdge('a', 'b', 0);
      g.addEdge('b', 'c', 0);
      expect(BinaryTree.fromGraph(g).error, contains('menor o igual que 7'));
    });

    test('nodos sin valor numérico son un error', () {
      final g = exampleGraph();
      g.nodes['f']!.name = 'F';
      expect(BinaryTree.fromGraph(g).error, contains('"F"'));
    });

    test('más de una raíz es un error', () {
      final g = exampleGraph();
      g.nodes['z'] = Node('z', '1', 700, 40, 30);
      expect(BinaryTree.fromGraph(g).error, contains('más de una raíz'));
    });

    test('un ciclo sin raíz es un error', () {
      final g = Graph();
      g.nodes['a'] = Node('a', '1', 0, 0, 30);
      g.nodes['b'] = Node('b', '2', 100, 100, 30);
      g.addEdge('a', 'b', 0);
      g.addEdge('b', 'a', 0);
      expect(BinaryTree.fromGraph(g).error, contains('ciclo'));
    });
  });

  group('listas → árbol', () {
    test('postorden + inorden reconstruye el ejemplo', () {
      final result = BinaryTree.fromTraversals(post, ino, TreePair.postIn);
      expect(result.isOk, isTrue);
      expect(BinaryTree.labels(result.root, Traversal.pre), pre);
    });

    test('postorden + preorden reconstruye el ejemplo', () {
      final result = BinaryTree.fromTraversals(post, pre, TreePair.postPre);
      expect(result.isOk, isTrue);
      expect(BinaryTree.labels(result.root, Traversal.inorder), ino);
    });

    test('acepta decimales y normaliza 5.0 como 5', () {
      final result = BinaryTree.fromTraversals(['1.5', '8', '5.0'], ['1.5', '5', '8'], TreePair.postIn);
      expect(result.isOk, isTrue);
      expect(BinaryTree.labels(result.root, Traversal.pre), ['5', '1.5', '8']);
    });

    test('errores de validación', () {
      expect(BinaryTree.fromTraversals([], ino, TreePair.postIn).error, contains('postorden'));
      expect(BinaryTree.fromTraversals(post, [], TreePair.postIn).error, contains('inorden'));
      expect(BinaryTree.fromTraversals(post, [], TreePair.postPre).error, contains('preorden'));
      expect(BinaryTree.fromTraversals(['1', 'x'], ['x', '1'], TreePair.postIn).error, contains('no es un número'));
      expect(BinaryTree.fromTraversals(post, ['1'], TreePair.postIn).error, contains('cantidad'));
      expect(BinaryTree.fromTraversals(['1', '1'], ['1', '2'], TreePair.postIn).error, contains('repetido'));
      expect(BinaryTree.fromTraversals(['1', '3'], ['1', '2'], TreePair.postIn).error, contains('no en el inorden'));
      expect(BinaryTree.fromTraversals(['1', '2'], ['2', '1'], TreePair.postIn).error, contains('menor a mayor'));
      expect(BinaryTree.fromTraversals(['3', '1', '2'], ['1', '2', '3'], TreePair.postIn).error,
          contains('ningún árbol binario de búsqueda'));
      expect(BinaryTree.fromTraversals(['1', '3', '2'], ['2', '3', '1'], TreePair.postPre).error,
          contains('no corresponde al mismo árbol'));
    });

    test('ida y vuelta con árboles aleatorios', () {
      final rng = Random(7);
      for (int i = 0; i < 200; i++) {
        final root = BinaryTree.random(1 + rng.nextInt(15), rng);
        final p0 = BinaryTree.labels(root, Traversal.post);
        for (final pair in TreePair.values) {
          final other = BinaryTree.labels(root, pair.other);
          final rebuilt = BinaryTree.fromTraversals(p0, other, pair);
          expect(rebuilt.isOk, isTrue);
          expect(BinaryTree.labels(rebuilt.root, Traversal.pre), BinaryTree.labels(root, Traversal.pre));
        }
      }
    });
  });

  group('aleatorio y árbol → grafo', () {
    test('los árboles aleatorios cumplen la regla y su inorden está ordenado', () {
      final rng = Random(11);
      for (int i = 0; i < 100; i++) {
        final root = BinaryTree.random(1 + rng.nextInt(15), rng);
        final values = BinaryTree.traverse(root, Traversal.inorder).map((n) => n.value).toList();
        expect(values, [...values]..sort());
      }
    });

    test('el grafo dibujado se lee igual y respeta las reglas', () {
      final rng = Random(3);
      final rules = TreeRules();
      for (int i = 0; i < 100; i++) {
        final root = BinaryTree.random(1 + rng.nextInt(15), rng);
        final graph = BinaryTree.toGraph(root, const Size(375, 700), top: 96, bottom: 140);
        expect(rules.validateGraph(graph), isEmpty);
        expect(graph.edges.values.every((e) => e.weight == 0 && e.directed), isTrue);
        final back = BinaryTree.fromGraph(graph);
        expect(BinaryTree.labels(back.root, Traversal.pre), BinaryTree.labels(root, Traversal.pre));
        final nodes = graph.nodes.values.toList();
        for (int a = 0; a < nodes.length; a++) {
          for (int b = a + 1; b < nodes.length; b++) {
            final d = Offset(nodes[a].x - nodes[b].x, nodes[a].y - nodes[b].y).distance;
            expect(d, greaterThan(2 * graph.radius + 3));
          }
        }
      }
    });

    test('un árbol que cabe queda dentro del lienzo', () {
      const size = Size(375, 700);
      final n = BinaryTree.maxNodesFor(size.width);
      final graph = BinaryTree.toGraph(BinaryTree.random(n, Random(1)), size);
      for (final node in graph.nodes.values) {
        expect(node.x - node.radius, greaterThanOrEqualTo(0));
        expect(node.x + node.radius, lessThanOrEqualTo(size.width));
      }
    });
  });

  group('reglas al dibujar', () {
    final rules = TreeRules();

    test('modo con valores y aristas automáticas', () {
      expect(rules.nodesAreValues, isTrue);
      expect(rules.autoEdgeWeight, 0);
      expect(rules.forcesDirected(), isTrue);
    });

    test('el lado según el valor y el lado ocupado', () {
      final g = exampleGraph();
      g.nodes['x'] = Node('x', '1', 600, 340, 30);
      g.nodes['y'] = Node('y', '10', 650, 340, 30);
      expect(rules.checkEdgeEndpoints(g, 'd', 'x'), isNull);
      expect(rules.checkEdgeEndpoints(g, 'f', 'y'), isNull);
      expect(rules.checkEdgeEndpoints(g, 'b', 'x'), contains('ya tiene hijo izquierdo'));
      expect(rules.checkEdgeEndpoints(g, 'c', 'y'), contains('ya tiene hijo derecho'));
    });

    test('respeta a los ancestros', () {
      final g = exampleGraph();
      g.nodes['x'] = Node('x', '6', 600, 340, 30);
      g.nodes['y'] = Node('y', '7.5', 650, 340, 30);
      expect(rules.checkEdgeEndpoints(g, 'e', 'x'), isNull);
      expect(rules.checkEdgeEndpoints(g, 'c', 'y'), isNull);
      g.nodes['z'] = Node('z', '7.5', 700, 340, 30);
      expect(rules.checkEdgeEndpoints(g, 'e', 'z'), contains('menor o igual que 7'));
    });

    test('colgar un subárbol revisa todos sus nodos', () {
      final g = Graph();
      g.nodes['r'] = Node('r', '10', 0, 0, 30);
      g.nodes['a'] = Node('a', '5', 100, 0, 30);
      g.nodes['b'] = Node('b', '20', 200, 0, 30);
      g.addEdge('a', 'b', 0);
      expect(rules.checkEdgeEndpoints(g, 'r', 'a'), contains('20'));
    });

    test('rechaza segundo padre, lazo y ciclo', () {
      final g = exampleGraph();
      expect(rules.checkEdgeEndpoints(g, 'c', 'e'), 'Este nodo ya tiene padre');
      expect(rules.checkEdgeEndpoints(g, 'a', 'a'), isNotNull);
      g.nodes['h'] = Node('h', '100', 0, 0, 30);
      expect(rules.checkEdgeEndpoints(g, 'f', 'h'), isNull);
      g.addEdge('f', 'h', 0);
      expect(rules.checkEdgeEndpoints(g, 'h', 'a'), isNotNull);
    });

    test('cambiar un valor', () {
      final g = exampleGraph();
      expect(rules.checkNodeName(g, null, 'abc'), isNotNull);
      expect(rules.checkNodeName(g, null, '3.5'), isNull);
      expect(rules.checkNodeName(g, 'e', '6'), isNull);
      expect(rules.checkNodeName(g, 'e', '8'), contains('menor o igual que 7'));
      expect(rules.checkNodeName(g, 'b', '1'), contains('mismo lado'));
      expect(rules.normalizeNodeName('5.0'), '5');
    });

    test('el proveedor crea nodos con valor y normaliza', () {
      final provider = GraphProvider(graphRules: rules);
      expect(provider.addNode(100, 100, name: 'x'), isNotNull);
      expect(provider.addNode(100, 100, name: '4.0'), isNull);
      expect(provider.graphGetter().nodes.values.single.name, '4');
    });
  });
}
