import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../layout/editor_shell.dart';
import '../layout/options_config.dart';
import '../models/app_mode.dart';
import '../providers/graph_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../tours/graph_tours.dart';
import '../widgets/panels/graph_maker_functions.dart';
import 'chat_screen.dart';
import 'matrix_screen.dart';
import 'pdf_viewer_screen.dart';

class GraphScreen extends StatefulWidget {
  const GraphScreen({super.key});

  @override
  State<GraphScreen> createState() => _GraphScreenState();
}

class _GraphScreenState extends State<GraphScreen> {
  final GraphMakerTourKeys _tourKeys = GraphMakerTourKeys();

  void _openMatrix() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MatrixScreen()),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    final graph = graphProvider.graphGetter();
    final int nodeCount = graph.nodes.length;
    final int edgeCount = graph.edges.length;
    final int directedCount = graph.edges.values.where((e) => e.directed).length;

    final OptionsConfig options = OptionsConfig(
      onUndo: graphProvider.undo,
      onRedo: graphProvider.redo,
      onSave: () => showSaveDialog(context, graphProvider),
      onOpen: () => showOpenDialog(context, graphProvider),
      onClear: graphProvider.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Graph Maker',
        assetPath: 'assets/docs/guia_graph_maker.pdf',
      ),
      onChat: _openChat,
      canUndo: graphProvider.canUndo,
      canRedo: graphProvider.canRedo,
    );

    return EditorShell(
      mode: AppMode.graphMaker,
      canvas: GraphWidget(),
      functions: GraphMakerFunctions(
        nodeCount: nodeCount,
        edgeCount: edgeCount,
        directedCount: directedCount,
        onOpenMatrix: nodeCount > 0 ? _openMatrix : null,
        matrixKey: _tourKeys.matrix,
      ),
      summary: Text(
        nodeCount == 0 ? 'Grafo vacío' : '$nodeCount nodos · $edgeCount aristas',
        style: const TextStyle(fontSize: 15, color: AppColors.blue),
      ),
      options: options,
      tour: graphMakerTour(_tourKeys),
      hint: 'Toca el lienzo para crear nodos y arrastra entre ellos para crear aristas',
    );
  }
}
