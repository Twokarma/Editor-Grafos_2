import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/screens/sort_screen.dart';
import 'package:provider/provider.dart';

Future<void> _pumpScreen(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => GraphProvider(),
      child: const MaterialApp(home: SortScreen(kind: SortKind.selection)),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('Resolver becomes Detener while sorting and Detener stops it', (tester) async {
    await _pumpScreen(tester, const Size(1280, 900));
    expect(find.text('Resolver'), findsOneWidget);

    await tester.tap(find.text('Resolver'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Detener'), findsOneWidget);
    expect(find.text('Resolver'), findsNothing);

    await tester.tap(find.text('Detener'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Resolver'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('a full run finishes and the timer stops', (tester) async {
    await _pumpScreen(tester, const Size(1280, 900));
    await tester.tap(find.text('×5'));
    await tester.pump();
    await tester.tap(find.text('Resolver'));
    await tester.pump();
    expect(find.text('Detener'), findsOneWidget);
    for (int i = 0; i < 200 && find.text('Detener').evaluate().isNotEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Resolver'), findsOneWidget);
    final String finished = tester.widget<Text>(find.textContaining(RegExp(r'^\d\d:\d\d\.\d$')).first).data!;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.widget<Text>(find.textContaining(RegExp(r'^\d\d:\d\d\.\d$')).first).data, finished);
  });

  testWidgets('phone width shows the timer in the sheet header', (tester) async {
    await _pumpScreen(tester, const Size(390, 844));
    expect(find.textContaining(RegExp(r'^\d\d:\d\d\.\d$')), findsOneWidget);
    expect(find.text('Resolver'), findsOneWidget);
  });
}
