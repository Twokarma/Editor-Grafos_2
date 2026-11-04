import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

/// Pone el botón en una caja de [width] px que NO lo obliga a ocupar todo el ancho,
/// así se puede comprobar que mantiene su tamaño.
Widget wrap(Widget child, {double width = 400}) => MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: Align(child: child),
          ),
        ),
      ),
    );

Finder _inButton(Finder matching) =>
    find.descendant(of: find.byType(CircleIconButton), matching: matching);

/// La caja con la forma de círculo (la única con ShapeDecoration).
ShapeDecoration decorationOf(WidgetTester t) {
  final box = t.widget<Container>(_inButton(find.byWidgetPredicate(
      (w) => w is Container && w.decoration is ShapeDecoration)));
  return box.decoration! as ShapeDecoration;
}

BorderSide sideOf(WidgetTester t) => (decorationOf(t).shape as CircleBorder).side;

double opacityOf(WidgetTester t) => t.widget<Opacity>(_inButton(find.byType(Opacity)).first).opacity;

void main() {
  group('contenido', () {
    testWidgets('muestra el ícono del color del estilo', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.arrow_back, text: 'Volver al inicio', action: () {})));
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(t.widget<Icon>(find.byIcon(Icons.arrow_back)).color, AppButtonStyle.outline.textColor);
    });

    testWidgets('el ícono mide la mitad del círculo', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', size: 60, action: () {})));
      expect(t.widget<Icon>(find.byIcon(Icons.undo)).size, 30);
    });

    testWidgets('el ícono queda centrado', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', action: () {})));
      final button = t.getCenter(find.byType(CircleIconButton));
      final icon = t.getCenter(find.byIcon(Icons.undo));
      expect(icon.dx, closeTo(button.dx, 1));
      expect(icon.dy, closeTo(button.dy, 1));
    });
  });

  group('texto (tooltip y lectores de pantalla)', () {
    testWidgets('el texto es el tooltip', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.arrow_back, text: 'Volver al inicio', action: () {})));
      expect(find.byTooltip('Volver al inicio'), findsOneWidget);
    });

    testWidgets('mantener presionado muestra el texto', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.arrow_back, text: 'Volver al inicio', action: () {})));
      await t.longPress(find.byType(CircleIconButton));
      await t.pumpAndSettle();
      expect(find.text('Volver al inicio'), findsOneWidget);
    });

    testWidgets('se anuncia como botón con su texto', (t) async {
      final semantics = t.ensureSemantics();
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.arrow_back, text: 'Volver al inicio', action: () {})));
      // Un solo nodo: botón habilitado que lleva el texto del tooltip.
      expect(
        t.getSemantics(find.byType(Pressable)),
        containsSemantics(isButton: true, isEnabled: true, tooltip: 'Volver al inicio'),
      );
      semantics.dispose();
    });
  });

  group('toque', () {
    testWidgets('tocar llama a la acción', (t) async {
      var taps = 0;
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', action: () => taps++)));
      await t.tap(find.byType(CircleIconButton));
      expect(taps, 1);
    });

    testWidgets('tocar el borde del círculo (no el ícono) también cuenta', (t) async {
      var taps = 0;
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', action: () => taps++)));
      final rect = t.getRect(find.byType(CircleIconButton));
      await t.tapAt(Offset(rect.left + 6, rect.center.dy));
      expect(taps, 1);
    });

    testWidgets('deshabilitado: no hace nada y se ve apagado', (t) async {
      await t.pumpWidget(wrap(const CircleIconButton(icon: Icons.undo, text: 'Deshacer')));
      await t.tap(find.byType(CircleIconButton)); // no debe lanzar
      expect(opacityOf(t), lessThan(1.0));
    });

    testWidgets('habilitado: opacidad completa', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', action: () {})));
      expect(opacityOf(t), 1.0);
    });
  });

  group('estilos', () {
    testWidgets('por defecto es contorno', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'Deshacer', action: () {})));
      expect(decorationOf(t).color, AppButtonStyle.outline.background);
    });

    for (final style in AppButtonStyle.values) {
      testWidgets('${style.name}: fondo y color del ícono', (t) async {
        await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', style: style, action: () {})));
        expect(decorationOf(t).color, style.background);
        expect(t.widget<Icon>(find.byIcon(Icons.undo)).color, style.textColor);
      });
    }

    testWidgets('outline: borde del color y grosor del estilo', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', action: () {})));
      final side = sideOf(t);
      expect(side.width, AppButtonStyle.outline.strokeWidth);
      expect(side.color, AppButtonStyle.outline.strokeColor);
    });

    for (final style in [AppButtonStyle.accent, AppButtonStyle.dark]) {
      testWidgets('${style.name}: sin borde', (t) async {
        await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', style: style, action: () {})));
        expect(sideOf(t).style, BorderStyle.none);
      });
    }

    testWidgets('forma de círculo', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', action: () {})));
      expect(decorationOf(t).shape, isA<CircleBorder>());
    });
  });

  group('tamaño', () {
    testWidgets('por defecto mide 44 × 44', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', action: () {})));
      expect(t.getSize(find.byType(CircleIconButton)), const Size(44, 44));
    });

    testWidgets('con size: mide lo pedido', (t) async {
      await t.pumpWidget(wrap(CircleIconButton(icon: Icons.undo, text: 'X', size: 46, action: () {})));
      expect(t.getSize(find.byType(CircleIconButton)), const Size(46, 46));
    });

    testWidgets('cabe en el menú plegado (56 px) sin desbordar', (t) async {
      await t.pumpWidget(wrap(
        Row(children: [CircleIconButton(icon: Icons.chevron_right, text: 'Mostrar menú', action: () {})]),
        width: 56,
      ));
      expect(t.takeException(), isNull);
    });

    testWidgets('varios en fila (barra móvil) no dan error', (t) async {
      await t.pumpWidget(wrap(Row(mainAxisSize: MainAxisSize.min, children: [
        CircleIconButton(icon: Icons.undo, text: 'Deshacer', size: 46, action: () {}),
        CircleIconButton(icon: Icons.redo, text: 'Rehacer', size: 46),
        CircleIconButton(icon: Icons.more_horiz, text: 'Más', size: 46, style: AppButtonStyle.dark, action: () {}),
      ])));
      expect(t.takeException(), isNull);
      expect(find.byType(CircleIconButton), findsNWidgets(3));
    });
  });
}
