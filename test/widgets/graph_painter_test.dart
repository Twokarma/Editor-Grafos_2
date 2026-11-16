import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/widgets/overlays/highlight_overlay.dart';
import 'package:graph_maker_app_2/models/node.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/graph_painter.dart';

void main() {
  Widget canvas({String? movingNodeId}) => Directionality(
        textDirection: TextDirection.ltr,
        child: CustomPaint(
          size: const Size(200, 200),
          painter: GraphPainter(
            nodes: {'a': Node('a', '7', 100, 100, 30, color: 0xFF2196F3)},
            edges: const {},
            dragSourceId: '',
            dragCurrentPosition: null,
            movingNodeId: movingNodeId,
            movingNodePosition: movingNodeId == null ? null : const Offset(100, 100),
            viewport: AppViewport(),
            showGrid: false,
          ),
        ),
      );

  testWidgets('un nodo en movimiento lleva un anillo del fondo y otro de su color', (tester) async {
    await tester.pumpWidget(canvas(movingNodeId: 'a'));
    expect(
      find.byType(CustomPaint),
      paints
        ..circle(x: 100, y: 100, radius: 30, color: const Color(0xFF2196F3), style: PaintingStyle.fill)
        ..circle(x: 100, y: 100, radius: 32.25, color: AppColors.canvasBackground, strokeWidth: 4.5, style: PaintingStyle.stroke)
        ..circle(x: 100, y: 100, radius: 36.75, color: const Color(0xFF2196F3), strokeWidth: 4.5, style: PaintingStyle.stroke),
    );
  });

  testWidgets('los nodos del camino llevan anillos y los demás no', (tester) async {
    final g = Graph();
    g.nodes['a'] = Node('a', 'A', 50, 50, 20);
    g.nodes['b'] = Node('b', 'B', 150, 50, 20);
    g.nodes['c'] = Node('c', 'C', 100, 150, 20);
    g.addEdge('a', 'b', 1);
    final String pathEdge = g.edges.keys.first;
    await tester.pumpWidget(Directionality(
      textDirection: TextDirection.ltr,
      child: CustomPaint(
        size: const Size(200, 200),
        painter: GraphPainter(
          nodes: g.nodes,
          edges: g.edges,
          dragSourceId: '',
          dragCurrentPosition: null,
          canvasOverlay: HighlightOverlay({pathEdge}, AppColors.assignmentEdge, ringPathNodes: true),
          viewport: AppViewport(),
          showGrid: false,
        ),
      ),
    ));
    expect(
      find.byType(CustomPaint),
      paints
        ..circle(x: 50, y: 50, radius: 20, color: AppColors.assignmentEdge)
        ..circle(x: 50, y: 50, radius: 22.25, color: AppColors.canvasBackground, strokeWidth: 4.5)
        ..circle(x: 50, y: 50, radius: 26.75, color: AppColors.assignmentEdge, strokeWidth: 4.5)
        ..circle(x: 150, y: 50, radius: 20, color: AppColors.assignmentEdge)
        ..circle(x: 150, y: 50, radius: 22.25, color: AppColors.canvasBackground, strokeWidth: 4.5)
        ..circle(x: 150, y: 50, radius: 26.75, color: AppColors.assignmentEdge, strokeWidth: 4.5)
        ..circle(x: 100, y: 150, radius: 20, color: const Color(Node.defaultColor)),
    );
    expect(
      find.byType(CustomPaint),
      isNot(paints
        ..circle(x: 100, y: 150, radius: 20)
        ..circle(x: 100, y: 150)),
    );
  });

  testWidgets('un nodo quieto no lleva anillos', (tester) async {
    await tester.pumpWidget(canvas());
    expect(
      find.byType(CustomPaint),
      isNot(paints..circle(style: PaintingStyle.stroke)),
    );
  });
}
