import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';

void main() {
  int nodes(GraphProvider p) => p.graphGetter().nodes.length;

  test('redo restores what undo removed', () {
    final p = GraphProvider();
    p.addNode(100, 100);
    p.addNode(300, 300);
    expect(nodes(p), 2);
    expect(p.canRedo, isFalse);

    p.undo();
    expect(nodes(p), 1);
    expect(p.canRedo, isTrue);

    p.redo();
    expect(nodes(p), 2);
    expect(p.canRedo, isFalse);
    expect(p.canUndo, isTrue);
  });

  test('a new action clears the redo stack', () {
    final p = GraphProvider();
    p.addNode(100, 100);
    p.undo();
    expect(p.canRedo, isTrue);

    p.addNode(300, 300);
    expect(p.canRedo, isFalse);
  });

  test('an empty graph never counts as unsaved', () {
    final p = GraphProvider();
    expect(p.hasUnsavedChanges, isFalse);
    p.addNode(100, 100);
    expect(p.hasUnsavedChanges, isTrue);
    p.clearGraph();
    expect(p.hasUnsavedChanges, isFalse);
  });

  test('redo history is capped at 20 steps', () {
    final p = GraphProvider();
    for (var i = 0; i < 25; i++) {
      p.addNode(100.0 + i * 120, 100);
    }
    var undos = 0;
    while (p.canUndo) {
      p.undo();
      undos++;
    }
    expect(undos, 20);

    var redos = 0;
    while (p.canRedo) {
      p.redo();
      redos++;
    }
    expect(redos, 20);
    expect(nodes(p), 25);
  });
}
