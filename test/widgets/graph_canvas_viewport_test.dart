import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:provider/provider.dart';

Future<GraphProvider> _pumpCanvas(WidgetTester tester) async {
  final provider = GraphProvider();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ChangeNotifierProvider<GraphProvider>.value(
          value: provider,
          child: const GraphWidget(),
        ),
      ),
    ),
  );
  return provider;
}

Future<void> _tapCanvas(WidgetTester tester, Offset position) async {
  await tester.tapAt(position);
  await tester.pump(kDoubleTapTimeout + const Duration(milliseconds: 50));
}

Offset _onlyNode(GraphProvider provider, String id) {
  final node = provider.graphGetter().nodes[id]!;
  return Offset(node.x, node.y);
}

void main() {
  testWidgets('a tap creates a node right under the finger', (tester) async {
    final provider = await _pumpCanvas(tester);
    await _tapCanvas(tester, const Offset(150, 120));
    expect(_onlyNode(provider, 'n0'), const Offset(150, 120));
  });

  testWidgets('dragging empty space pans without creating anything', (tester) async {
    final provider = await _pumpCanvas(tester);
    await tester.dragFrom(const Offset(400, 300), const Offset(-100, -40));
    await tester.pump(kDoubleTapTimeout);
    expect(provider.graphGetter().nodes, isEmpty);
    expect(provider.canUndo, isFalse);

    await _tapCanvas(tester, const Offset(300, 200));
    expect(_onlyNode(provider, 'n0'), const Offset(400, 240));
  });

  testWidgets('after zooming in, a tap still lands under the finger', (tester) async {
    final provider = await _pumpCanvas(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    final TestPointer mouse = TestPointer(1, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(const Offset(400, 300)));
    await tester.sendEventToBinding(mouse.scroll(const Offset(0, -300 * 0.6931471805599453)));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    await _tapCanvas(tester, const Offset(500, 300));
    final Offset world = _onlyNode(provider, 'n0');
    expect(world.dx, closeTo(450, 0.5));
    expect(world.dy, closeTo(300, 0.5));
  });

  testWidgets('a pinch zooms around the fingers and creates nothing', (tester) async {
    final provider = await _pumpCanvas(tester);
    final TestGesture a = await tester.startGesture(const Offset(350, 300), pointer: 1);
    final TestGesture b = await tester.startGesture(const Offset(450, 300), pointer: 2);
    await tester.pump();
    for (int i = 1; i <= 10; i++) {
      await a.moveTo(Offset(350 - 5.0 * i, 300));
      await b.moveTo(Offset(450 + 5.0 * i, 300));
      await tester.pump();
    }
    await a.up();
    await b.up();
    await tester.pump(kDoubleTapTimeout);
    expect(provider.graphGetter().nodes, isEmpty);

    await _tapCanvas(tester, const Offset(400, 300));
    final Offset centre = _onlyNode(provider, 'n0');
    expect(centre.dx, closeTo(400, 0.5));
    expect(centre.dy, closeTo(300, 0.5));

    await _tapCanvas(tester, const Offset(600, 300));
    final Offset right = _onlyNode(provider, 'n1');
    expect(right.dx - centre.dx, closeTo(100, 1));
  });

  testWidgets('a second finger cancels an edge drag', (tester) async {
    final provider = await _pumpCanvas(tester);
    await _tapCanvas(tester, const Offset(150, 150));
    await _tapCanvas(tester, const Offset(450, 150));

    final TestGesture drag = await tester.startGesture(const Offset(150, 150), pointer: 1);
    await drag.moveTo(const Offset(300, 150));
    await tester.pump();
    final TestGesture second = await tester.startGesture(const Offset(300, 400), pointer: 2);
    await tester.pump();
    await drag.moveTo(const Offset(450, 150));
    await tester.pump();
    await drag.up();
    await second.up();
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    expect(provider.graphGetter().edges, isEmpty);
  });

  testWidgets('dragging from one node to another opens the edge dialog', (tester) async {
    await _pumpCanvas(tester);
    await _tapCanvas(tester, const Offset(150, 150));
    await _tapCanvas(tester, const Offset(450, 150));

    await tester.dragFrom(const Offset(150, 150), const Offset(300, 0));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('replacing the whole graph frames it automatically', (tester) async {
    final provider = await _pumpCanvas(tester);
    final Graph far = Graph()..addNode(3000, 3000);
    provider.replaceGraph(far);
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsNothing);

    await _tapCanvas(tester, const Offset(400, 272));
    expect(provider.graphGetter().nodes.length, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('the fit button frames a graph that is off screen', (tester) async {
    final provider = await _pumpCanvas(tester);
    await _tapCanvas(tester, const Offset(100, 100));
    await tester.dragFrom(const Offset(400, 300), const Offset(-2000, 0));
    await tester.pump(kDoubleTapTimeout);

    await tester.tap(find.byTooltip('Ajustar a la vista'));
    await tester.pumpAndSettle();

    await _tapCanvas(tester, const Offset(400, 300));
    expect(provider.graphGetter().nodes.length, 1);
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}
