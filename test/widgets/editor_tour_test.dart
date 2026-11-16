import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/screens/graph_screen.dart';
import 'package:graph_maker_app_2/screens/kruskal_screen.dart';
import 'package:graph_maker_app_2/widgets/canvas/zoom_controls.dart';
import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:graph_maker_app_2/widgets/nav/side_nav.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/screens/sort_screen.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_overlay.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<GraphProvider> _pump(WidgetTester tester, Widget screen, Size size) async {
  SharedPreferences.setMockInitialValues({});
  TourMemory.resetForTest();
  AppTour.resetForTest();
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final provider = GraphProvider();
  await tester.pumpWidget(
    ChangeNotifierProvider<GraphProvider>.value(
      value: provider,
      child: MaterialApp(home: screen),
    ),
  );
  await _settle(tester);
  return provider;
}

Future<void> _settle(WidgetTester tester, [int frames = 25]) async {
  for (int i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Rect? _highlight(WidgetTester tester) {
  final CustomPaint? scrim = tester
      .widgetList<CustomPaint>(find.byType(CustomPaint))
      .where((c) => c.painter?.runtimeType.toString() == '_ScrimPainter')
      .firstOrNull;
  return (scrim?.painter as dynamic)?.hole as Rect?;
}

void _expectHighlightAround(WidgetTester tester, Finder target, String step) {
  final Rect? hole = _highlight(tester);
  final Rect rect = tester.getRect(target);
  expect(hole, isNotNull, reason: '$step has a highlight');
  expect(hole!.inflate(1).contains(rect.topLeft) && hole.inflate(1).contains(rect.bottomRight), isTrue,
      reason: '$step highlights $rect, not $hole');
  expect(hole.width * hole.height < rect.width * rect.height * 1.6, isTrue,
      reason: '$step highlight $hole is much bigger than its target $rect');
}

String? _bubbleTitle(WidgetTester tester) {
  final List<String?> texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
  final int skip = texts.indexOf('Saltar recorrido');
  return skip < 0 || skip + 1 >= texts.length ? null : texts[skip + 1];
}

Future<void> _startFromInvite(WidgetTester tester) async {
  expect(find.textContaining('¿Primera vez en'), findsOneWidget);
  await tester.tap(find.text('Ver recorrido'));
  await _settle(tester);
  expect(AppTour.isActive, isTrue);
}

Future<void> _next(WidgetTester tester) async {
  await tester.tap(find.text('Siguiente').last);
  await _settle(tester, 15);
}

Future<List<String>> _walk(WidgetTester tester, {void Function(String title)? onStep}) async {
  final List<String> titles = [];
  for (int i = 0; i < 40; i++) {
    final String title = _bubbleTitle(tester) ?? '?';
    titles.add(title);
    onStep?.call(title);
    if (find.text('Terminar').evaluate().isNotEmpty) break;
    await _next(tester);
  }
  await tester.tap(find.text('Terminar'));
  await _settle(tester);
  return titles;
}

void main() {
  testWidgets('web: every chapter is shown and Opciones opens for its own steps', (tester) async {
    await _pump(tester, const SortScreen(kind: SortKind.selection), const Size(1280, 900));
    expect(find.text('Guardar'), findsNothing);
    await _startFromInvite(tester);

    final List<String> titles = await _walk(tester, onStep: (title) {
      if (title == 'Guardar' || title == 'Abrir') {
        expect(find.text(title), findsNWidgets(2), reason: 'the real $title button is visible next to the bubble');
      }
    });
    expect(titles, containsAllInOrder(['Bienvenido a Selection', 'Los bolos', 'Funciones', 'Mezclar', 'Colores', 'Opciones', 'Guardar', 'Abrir', 'Manual', 'Ayuda']));
    expect(AppTour.isActive, isFalse);
    expect(find.text('Guardar'), findsNothing, reason: 'Opciones is closed again');
    expect(find.text('Mezclar'), findsOneWidget, reason: 'Funciones is open again');
  });

  testWidgets('web: each step highlights its own target, not the previous one', (tester) async {
    await _pump(tester, const KruskalScreen(), const Size(1280, 900));
    await _startFromInvite(tester);
    final Map<String, Finder> targets = {
      'Bienvenido a Kruskal': find.byType(SideNav),
      'El lienzo': find.byType(GraphWidget),
      'Mover un nodo': find.byType(GraphWidget),
      'Controles de zoom': find.byType(ZoomControls),
      'Árbol mínimo': find.ancestor(of: find.text('Árbol mínimo'), matching: find.byType(PillButton)),
      'Ver pasos': find.ancestor(of: find.text('Ver pasos'), matching: find.byType(PillButton)),
    };
    final Set<String> checked = {};
    await _walk(tester, onStep: (title) {
      final Finder? target = targets[title];
      if (target == null) return;
      _expectHighlightAround(tester, target.first, title);
      checked.add(title);
    });
    expect(checked, targets.keys.toSet());
  });

  testWidgets('mobile: each step highlights its own target, including the zoom controls', (tester) async {
    await _pump(tester, const GraphScreen(), const Size(390, 844));
    await _startFromInvite(tester);
    final Map<String, Finder> targets = {
      'Controles de zoom': find.byType(ZoomControls),
      'Matriz M[x]': find.ancestor(of: find.text('Matriz M[x]'), matching: find.byType(PillButton)),
    };
    final Set<String> checked = {};
    await _walk(tester, onStep: (title) {
      final Finder? target = targets[title];
      if (target == null) return;
      _expectHighlightAround(tester, target.first, title);
      checked.add(title);
    });
    expect(checked, targets.keys.toSet());
  });

  testWidgets('"Saltar capítulo" jumps to the next chapter', (tester) async {
    await _pump(tester, const SortScreen(kind: SortKind.insertion), const Size(1280, 900));
    await _startFromInvite(tester);
    await _next(tester);
    await _next(tester);
    expect(_bubbleTitle(tester), 'Funciones');
    await tester.tap(find.text('Saltar «Funciones»'));
    await _settle(tester);
    expect(_bubbleTitle(tester), 'Opciones');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
  });

  testWidgets('Esc closes the tour and the arrow keys move between steps', (tester) async {
    await _pump(tester, const SortScreen(kind: SortKind.merge), const Size(1280, 900));
    await _startFromInvite(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await _settle(tester, 15);
    expect(_bubbleTitle(tester), 'Los bolos');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await _settle(tester, 15);
    expect(_bubbleTitle(tester), 'Bienvenido a Merge');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    expect(AppTour.isActive, isFalse);
  });

  testWidgets('mobile: the canvas step lets a real tap through and moves on by itself', (tester) async {
    final provider = await _pump(tester, const GraphScreen(), const Size(390, 844));
    await _startFromInvite(tester);
    await _next(tester);
    expect(_bubbleTitle(tester), 'El lienzo');
    expect(find.textContaining('Ahora tú: crea un nodo'), findsOneWidget);

    await tester.tapAt(const Offset(195, 150));
    await _settle(tester, 30);
    expect(provider.graphGetter().nodes.length, 1);
    expect(_bubbleTitle(tester), 'Crear una arista');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
  });

  testWidgets('mobile: taps outside the highlight never reach the canvas', (tester) async {
    final provider = await _pump(tester, const GraphScreen(), const Size(390, 844));
    await _startFromInvite(tester);
    await tester.tapAt(const Offset(195, 300));
    await _settle(tester, 10);
    expect(provider.graphGetter().nodes, isEmpty);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
  });

  testWidgets('mobile: options hidden in the ⋯ menu are merged into one step', (tester) async {
    await _pump(tester, const GraphScreen(), const Size(390, 844));
    await _startFromInvite(tester);
    final List<String> titles = await _walk(tester, onStep: (title) {
      if (title == 'Más opciones') {
        expect(find.textContaining('Guardar: '), findsOneWidget);
        expect(find.textContaining('Abrir: '), findsOneWidget);
      }
    });
    expect(titles, containsAllInOrder(['Bienvenido a Graph Maker', 'El lienzo', 'Controles de zoom', 'Funciones', 'Matriz M[x]', 'Opciones', 'Deshacer', 'Rehacer', 'Más opciones']));
    expect(AppTour.isActive, isFalse);
  });

  testWidgets('the tour closes itself when its screen is closed', (tester) async {
    SharedPreferences.setMockInitialValues({});
    TourMemory.resetForTest();
    AppTour.resetForTest();
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final GlobalKey<NavigatorState> navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GraphProvider(),
        child: MaterialApp(navigatorKey: navigator, home: const Scaffold(body: Text('Inicio'))),
      ),
    );
    navigator.currentState!.push(MaterialPageRoute(builder: (_) => const SortScreen(kind: SortKind.selection)));
    await _settle(tester);
    await _startFromInvite(tester);
    navigator.currentState!.pop();
    await _settle(tester);
    expect(AppTour.isActive, isFalse);
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Saltar recorrido'), findsNothing);
  });

  testWidgets('"Ahora no" hides the invite and remembers it', (tester) async {
    await _pump(tester, const SortScreen(kind: SortKind.shell), const Size(1280, 900));
    await tester.tap(find.byTooltip('Ahora no'));
    await _settle(tester, 5);
    expect(find.textContaining('¿Primera vez en'), findsNothing);
    expect(await TourMemory.isSeen('shell'), isTrue);
  });
}
