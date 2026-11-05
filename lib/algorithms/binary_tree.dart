import 'dart:math';
import 'dart:ui';

import '../models/edge.dart';
import '../models/graph.dart';
import '../models/node.dart';

class TreeNode {
  final String label;
  final double value;
  final String? nodeId;
  TreeNode? left;
  TreeNode? right;

  TreeNode(this.value, {this.nodeId, this.left, this.right}) : label = BinaryTree.formatValue(value);
}

class TreeResult {
  final TreeNode? root;
  final String? error;

  const TreeResult.ok(this.root) : error = null;
  const TreeResult.fail(this.error) : root = null;

  bool get isOk => error == null;
}

enum Traversal {
  pre('Preorden', 'Pre'),
  inorder('Inorden', 'In'),
  post('Postorden', 'Post');

  const Traversal(this.label, this.short);
  final String label;
  final String short;
}

enum TreePair {
  postIn('Postorden + Inorden', Traversal.inorder),
  postPre('Postorden + Preorden', Traversal.pre);

  const TreePair(this.label, this.other);
  final String label;
  final Traversal other;
}

class BinaryTree {
  BinaryTree._();

  static const int maxRandomNodes = 15;
  static const int maxRandomValue = 99;
  static const double maxRadius = 30;
  static const double minRadius = 16;
  static const double _gap = 6;
  static const double _sideMargin = 12;

  static double? parseValue(String text) {
    final double? value = double.tryParse(text.trim());
    if (value == null || value.isNaN || value.isInfinite) return null;
    return value;
  }

  static String formatValue(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) return value.toInt().toString();
    return value.toString();
  }

  static String? searchRuleViolation(Graph graph) {
    final Map<String, double> values = {};
    for (final Node node in graph.nodes.values) {
      final double? value = parseValue(node.name);
      if (value == null) return 'El nodo "${node.name}" no tiene un valor numérico: tócalo para cambiarlo';
      values[node.id] = value;
    }
    final Map<String, List<String>> children = _children(graph);
    final Set<String> hasParent = graph.edges.values.map((e) => e.targetNodeId).toSet();
    final Set<String> visited = {};

    String? walk(String id, double? low, double? high) {
      if (!visited.add(id)) return null;
      final double v = values[id]!;
      final String name = formatValue(v);
      if (low != null && !(v > low)) {
        return '$name está a la derecha de ${formatValue(low)}, así que debe ser mayor que ${formatValue(low)}';
      }
      if (high != null && !(v <= high)) {
        return '$name está a la izquierda de ${formatValue(high)}, así que debe ser menor o igual que ${formatValue(high)}';
      }
      final List<String> kids = children[id]!;
      final List<String> lefts = kids.where((k) => values[k]! <= v).toList();
      final List<String> rights = kids.where((k) => values[k]! > v).toList();
      if (lefts.length > 1) return '$name ya tiene un hijo izquierdo (los valores ≤ $name van a la izquierda)';
      if (rights.length > 1) return '$name ya tiene un hijo derecho (los valores > $name van a la derecha)';
      for (final String k in lefts) {
        final String? error = walk(k, low, v);
        if (error != null) return error;
      }
      for (final String k in rights) {
        final String? error = walk(k, v, high);
        if (error != null) return error;
      }
      return null;
    }

    for (final String id in graph.nodes.keys) {
      if (hasParent.contains(id)) continue;
      final String? error = walk(id, null, null);
      if (error != null) return error;
    }
    return null;
  }

  static ({double? low, double? high}) _bounds(Graph graph, String id) {
    double? low;
    double? high;
    String current = id;
    final Set<String> seen = {id};
    while (true) {
      final List<Edge> up = graph.findEdgesTo(current);
      if (up.isEmpty) break;
      final String parent = up.first.sourceNodeId;
      if (!seen.add(parent)) break;
      final double? pv = parseValue(graph.nodes[parent]!.name);
      final double? cv = parseValue(graph.nodes[current]!.name);
      if (pv != null && cv != null) {
        if (cv <= pv) {
          high = high == null ? pv : min(high, pv);
        } else {
          low = low == null ? pv : max(low, pv);
        }
      }
      current = parent;
    }
    return (low: low, high: high);
  }

  static String? _subtreeFits(Graph graph, String id, double? low, double? high, Set<String> seen) {
    if (!seen.add(id)) return null;
    final Node node = graph.nodes[id]!;
    final double? v = parseValue(node.name);
    if (v == null) return 'Primero dale un valor numérico a "${node.name}"';
    final String name = formatValue(v);
    if (low != null && !(v > low)) {
      return '$name quedaría a la derecha de ${formatValue(low)}, pero debe ser mayor que ${formatValue(low)}';
    }
    if (high != null && !(v <= high)) {
      return '$name quedaría a la izquierda de ${formatValue(high)}, pero debe ser menor o igual que ${formatValue(high)}';
    }
    for (final Edge edge in graph.findEdgesFrom(id)) {
      final String? error = _subtreeFits(graph, edge.targetNodeId, low, high, seen);
      if (error != null) return error;
    }
    return null;
  }

  static String? checkPlacement(Graph graph, String parentId, String childId) {
    final Node parent = graph.nodes[parentId]!;
    final double? pv = parseValue(parent.name);
    if (pv == null) return 'Primero dale un valor numérico a "${parent.name}"';
    final double? cv = parseValue(graph.nodes[childId]!.name);
    if (cv == null) return 'Primero dale un valor numérico a "${graph.nodes[childId]!.name}"';

    final String p = formatValue(pv);
    final bool goesLeft = cv <= pv;
    for (final Edge edge in graph.findEdgesFrom(parentId)) {
      final double? other = parseValue(graph.nodes[edge.targetNodeId]!.name);
      if (other == null) continue;
      if ((other <= pv) == goesLeft) {
        return goesLeft
            ? '$p ya tiene hijo izquierdo (ahí van los valores ≤ $p)'
            : '$p ya tiene hijo derecho (ahí van los valores > $p)';
      }
    }

    final bounds = _bounds(graph, parentId);
    final double? low = goesLeft ? bounds.low : pv;
    final double? high = goesLeft ? pv : bounds.high;
    return _subtreeFits(graph, childId, low, high, {});
  }

  static String? checkValueChange(Graph graph, String nodeId, double value) {
    final String name = formatValue(value);
    final bounds = _bounds(graph, nodeId);
    if (bounds.low != null && !(value > bounds.low!)) {
      return '$name está a la derecha de ${formatValue(bounds.low!)}: debe ser mayor que ${formatValue(bounds.low!)}';
    }
    if (bounds.high != null && !(value <= bounds.high!)) {
      return '$name está a la izquierda de ${formatValue(bounds.high!)}: debe ser menor o igual que ${formatValue(bounds.high!)}';
    }

    final List<String> kids = graph.findEdgesFrom(nodeId).map((e) => e.targetNodeId).toList();
    final List<double?> kidValues = kids.map((k) => parseValue(graph.nodes[k]!.name)).toList();
    if (kids.length == 2 && kidValues[0] != null && kidValues[1] != null &&
        (kidValues[0]! <= value) == (kidValues[1]! <= value)) {
      return 'Con el valor $name sus dos hijos quedarían del mismo lado';
    }
    for (int i = 0; i < kids.length; i++) {
      final double? kv = kidValues[i];
      if (kv == null) continue;
      final bool left = kv <= value;
      final String? error = _subtreeFits(graph, kids[i], left ? bounds.low : value, left ? value : bounds.high, {});
      if (error != null) return error;
    }
    return null;
  }

  static Map<String, List<String>> _children(Graph graph) {
    final Map<String, List<String>> children = {for (final id in graph.nodes.keys) id: []};
    for (final Edge edge in graph.edges.values) {
      children[edge.sourceNodeId]?.add(edge.targetNodeId);
    }
    return children;
  }

  static TreeResult fromGraph(Graph graph) {
    final Map<String, Node> nodes = graph.nodes;
    if (nodes.isEmpty) return const TreeResult.ok(null);

    final Map<String, int> parents = {for (final id in nodes.keys) id: 0};
    for (final Edge edge in graph.edges.values) {
      if (edge.isLoop()) return TreeResult.fail('${_name(graph, edge.sourceNodeId)} no puede ser su propio hijo');
      if (!edge.directed) return const TreeResult.fail('Las aristas deben ir del padre al hijo');
      parents[edge.targetNodeId] = parents[edge.targetNodeId]! + 1;
    }
    final Map<String, List<String>> children = _children(graph);
    for (final String id in nodes.keys) {
      if (parents[id]! > 1) return TreeResult.fail('${_name(graph, id)} tiene más de un padre');
      if (children[id]!.length > 2) return TreeResult.fail('${_name(graph, id)} tiene más de dos hijos');
    }

    final List<String> roots = nodes.keys.where((id) => parents[id] == 0).toList();
    if (roots.isEmpty) return const TreeResult.fail('No hay raíz: el grafo tiene un ciclo');

    final String? ruleError = searchRuleViolation(graph);
    if (ruleError != null) return TreeResult.fail(ruleError);

    if (roots.length > 1) {
      final String list = roots.map((id) => _name(graph, id)).join(', ');
      return TreeResult.fail('Hay más de una raíz ($list): une todo en un solo árbol');
    }

    final Set<String> visited = {};
    TreeNode build(String id) {
      visited.add(id);
      final TreeNode treeNode = TreeNode(parseValue(nodes[id]!.name)!, nodeId: id);
      for (final String kidId in children[id]!) {
        final TreeNode kid = build(kidId);
        if (kid.value <= treeNode.value) {
          treeNode.left = kid;
        } else {
          treeNode.right = kid;
        }
      }
      return treeNode;
    }

    final TreeNode root = build(roots.first);
    if (visited.length != nodes.length) return const TreeResult.fail('Hay nodos que no cuelgan de la raíz (forman un ciclo)');
    return TreeResult.ok(root);
  }

  static String _name(Graph graph, String id) => graph.nodes[id]?.name ?? id;

  static List<TreeNode> traverse(TreeNode? root, Traversal order) {
    final List<TreeNode> out = [];
    void walk(TreeNode? node) {
      if (node == null) return;
      if (order == Traversal.pre) out.add(node);
      walk(node.left);
      if (order == Traversal.inorder) out.add(node);
      walk(node.right);
      if (order == Traversal.post) out.add(node);
    }
    walk(root);
    return out;
  }

  static List<String> labels(TreeNode? root, Traversal order) =>
      traverse(root, order).map((n) => n.label).toList();

  static int count(TreeNode? root) => root == null ? 0 : 1 + count(root.left) + count(root.right);

  static int depth(TreeNode? root) {
    if (root == null) return -1;
    return 1 + max(depth(root.left), depth(root.right));
  }

  static List<String> parseList(String text) =>
      text.split(RegExp(r'[,;\s]+')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  static TreeResult fromTraversals(List<String> postText, List<String> otherText, TreePair pair) {
    final String otherName = pair.other.label.toLowerCase();
    if (postText.isEmpty) return const TreeResult.fail('Escribe el postorden');
    if (otherText.isEmpty) return TreeResult.fail('Escribe el $otherName');

    final List<double> post = [];
    for (final String s in postText) {
      final double? v = parseValue(s);
      if (v == null) return TreeResult.fail('"$s" no es un número (los decimales van con punto: 3.5)');
      post.add(v);
    }
    final List<double> other = [];
    for (final String s in otherText) {
      final double? v = parseValue(s);
      if (v == null) return TreeResult.fail('"$s" no es un número (los decimales van con punto: 3.5)');
      other.add(v);
    }

    if (post.length != other.length) {
      return TreeResult.fail('Los recorridos tienen distinta cantidad de elementos (${post.length} y ${other.length})');
    }
    final double? dupPost = _firstDuplicate(post);
    if (dupPost != null) {
      return TreeResult.fail('${formatValue(dupPost)} aparece repetido en el postorden: con valores repetidos el árbol no es único');
    }
    final double? dupOther = _firstDuplicate(other);
    if (dupOther != null) {
      return TreeResult.fail('${formatValue(dupOther)} aparece repetido en el $otherName: con valores repetidos el árbol no es único');
    }
    final Set<double> otherSet = other.toSet();
    for (final double v in post) {
      if (!otherSet.contains(v)) return TreeResult.fail('${formatValue(v)} está en el postorden pero no en el $otherName');
    }
    if (pair == TreePair.postIn) {
      for (int i = 1; i < other.length; i++) {
        if (other[i] <= other[i - 1]) {
          return TreeResult.fail(
              'El inorden de un árbol binario de búsqueda va de menor a mayor '
              '(${formatValue(other[i - 1])} está antes que ${formatValue(other[i])})');
        }
      }
    }

    int index = post.length - 1;
    TreeNode? build(double? low, double? high) {
      if (index < 0) return null;
      final double v = post[index];
      if ((low != null && !(v > low)) || (high != null && !(v <= high))) return null;
      index--;
      final TreeNode node = TreeNode(v);
      node.right = build(v, high);
      node.left = build(low, v);
      return node;
    }

    final TreeNode? root = build(null, null);
    if (root == null || index >= 0) {
      return const TreeResult.fail('El postorden no corresponde a ningún árbol binario de búsqueda');
    }
    if (!_sameList(labels(root, pair.other), other.map(formatValue).toList())) {
      return TreeResult.fail('El $otherName no corresponde al mismo árbol que el postorden');
    }
    return TreeResult.ok(root);
  }

  static double? _firstDuplicate(List<double> list) {
    final Set<double> seen = {};
    for (final double v in list) {
      if (!seen.add(v)) return v;
    }
    return null;
  }

  static bool _sameList(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static TreeNode insert(TreeNode? root, double value) {
    final TreeNode node = TreeNode(value);
    if (root == null) return node;
    TreeNode current = root;
    while (true) {
      if (value <= current.value) {
        if (current.left == null) {
          current.left = node;
          return root;
        }
        current = current.left!;
      } else {
        if (current.right == null) {
          current.right = node;
          return root;
        }
        current = current.right!;
      }
    }
  }

  /// Inserts [valuesText] one by one, in order, into [root] following the
  /// search rule (≤ goes left, > goes right). [root] is modified in place.
  static TreeResult insertAll(TreeNode? root, List<String> valuesText) {
    if (valuesText.isEmpty) return const TreeResult.fail('Escribe un valor para insertar');
    final List<double> values = [];
    for (final String s in valuesText) {
      final double? v = parseValue(s);
      if (v == null) return TreeResult.fail('"$s" no es un número (los decimales van con punto: 3.5)');
      values.add(v);
    }
    TreeNode? current = root;
    for (final double v in values) {
      current = insert(current, v);
    }
    return TreeResult.ok(current);
  }

  static TreeNode random(int n, [Random? rng]) {
    final Random r = rng ?? Random();
    final int size = n.clamp(1, maxRandomValue);
    final List<int> values = List.generate(maxRandomValue, (i) => i + 1)..shuffle(r);
    TreeNode? root;
    for (final int v in values.take(size)) {
      root = insert(root, v.toDouble());
    }
    return root!;
  }

  static double radiusFor(int n, double width) {
    if (n <= 1) return maxRadius;
    final double r = (width - 2 * _sideMargin - (n - 1) * _gap) / (2 * n);
    return r.clamp(minRadius, maxRadius);
  }

  static int maxNodesFor(double width) {
    final double usable = width - 2 * (minRadius + _sideMargin);
    return max(1, (usable / (2 * minRadius + _gap)).floor() + 1);
  }

  static Graph toGraph(TreeNode root, Size area, {double top = 24, double bottom = 24}) {
    final List<TreeNode> inorder = traverse(root, Traversal.inorder);
    final int n = inorder.length;
    final int treeDepth = depth(root);

    final double r = radiusFor(n, area.width);
    final double minDx = 2 * r + _gap;
    final double usableW = area.width - 2 * (r + _sideMargin);
    final double dx = n > 1 ? max(minDx, min(usableW / (n - 1), 110)) : 0;
    final double treeWidth = dx * (n - 1);
    final double startX = max(r + _sideMargin, (area.width - treeWidth) / 2);

    final double usableH = area.height - top - bottom - 2 * r;
    final double dy = treeDepth > 0 ? (usableH / treeDepth).clamp(r * 1.6, 100.0) : 0;
    final double startY = top + r;

    final Graph graph = Graph()..radius = r;
    final Map<TreeNode, int> column = {for (int i = 0; i < n; i++) inorder[i]: i};

    void place(TreeNode node, int level) {
      final String id = 'n${column[node]}';
      graph.nodes[id] = Node(id, node.label, startX + column[node]! * dx, startY + level * dy, r);
      for (final TreeNode? child in [node.left, node.right]) {
        if (child == null) continue;
        place(child, level + 1);
        graph.addEdge(id, 'n${column[child]}', 0, directed: true);
      }
    }

    place(root, 0);
    graph.currentNode = n;
    return graph;
  }
}
