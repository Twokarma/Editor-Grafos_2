import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/kruskal.dart';
import '../layout/editor_shell.dart';
import '../layout/options_config.dart';
import '../models/app_mode.dart';
import '../providers/graph_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/overlays/highlight_overlay.dart';
import '../widgets/panels/kruskal_functions.dart';
import 'kruskal_steps_screen.dart';
import 'pdf_viewer_screen.dart';

/// Árbol de expansión mínimo (o máximo) con el algoritmo de Kruskal.
///
/// El usuario dibuja nodos y aristas NO dirigidas con peso; al pulsar el botón
/// se resuelve y las aristas del árbol quedan resaltadas sobre el grafo.
///
/// Igual que AssignmentScreen, JohnsonScreen y TransportationScreen, trabaja
/// sobre una COPIA del grafo (el provider que recibe de _pushWithCopy).
class KruskalScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const KruskalScreen({super.key, required this.mainProvider});

  @override
  State<KruskalScreen> createState() => _KruskalScreenState();
}

class _KruskalScreenState extends State<KruskalScreen> {
  late final GraphProvider _copy;
  late String _lastAppliedJson;

  KruskalResult? _result;
  Map<String, String> _names = const {};
  Set<String> _treeEdgeIds = {};

  @override
  void initState() {
    super.initState();
    _copy = context.read<GraphProvider>();
    _copy.addListener(_clearResult);
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());
  }

  @override
  void dispose() {
    _copy.removeListener(_clearResult);
    super.dispose();
  }

  // Si el grafo cambia, el resultado ya no corresponde a lo que se ve.
  void _clearResult() {
    if (_result == null) return;
    setState(() {
      _result = null;
      _treeEdgeIds = {};
    });
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  void _solve(KruskalGoal goal) {
    final graph = _copy.graphGetter();
    final names = {for (final n in graph.nodes.values) n.id: n.name};

    final KruskalResult result;
    try {
      result = KruskalAlgorithm.solve(
        nodeIds: graph.nodes.keys.toList(),
        edges: [
          for (final e in graph.edges.values)
            KruskalEdge(e.id, e.sourceNodeId, e.targetNodeId, e.weight),
        ],
        goal: goal,
      );
    } catch (e, st) {
      debugPrint('Kruskal error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return;
    }

    setState(() {
      _result = result;
      _names = names;
      _treeEdgeIds = {for (final e in result.treeEdges) e.id};
    });
  }

  void _openSteps() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KruskalStepsScreen(result: result, names: _names),
      ),
    );
  }

  void _apply(String currentGraph) {
    widget.mainProvider.replaceGraph(_copy.snapshot());
    setState(() {
      _lastAppliedJson = currentGraph;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Grafo actualizado')),
    );
  }

  String _summaryText(String? message) {
    final KruskalResult? result = _result;
    if (message != null) return message;
    if (result == null) return 'Elige árbol mínimo o máximo';
    final String kind = result.goal == KruskalGoal.minimum ? 'mínimo' : 'máximo';
    return 'Árbol $kind: peso ${_fmt(result.totalWeight)}';
  }

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final List<String> messages = _copy.validateGraph();
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final bool canSolve = _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final String? message = messages.isNotEmpty ? messages.first : null;

    final OptionsConfig options = OptionsConfig(
      onApply: () => _apply(currentGraph),
      onUndo: graphProviderCopy.undo,
      onOpen: () => showOpenDialog(context, graphProviderCopy),
      onSave: () => showSaveDialog(context, graphProviderCopy),
      onClear: graphProviderCopy.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Manual de Kruskal',
        assetPath: 'assets/docs/guia_kruskal.pdf',
      ),
      hasChanges: hasChanges,
      canUndo: graphProviderCopy.canUndo,
    );

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: ((didPop, _) {
        if (didPop) return;
        showConfirmExitDialog(context, _copy);
      }),
      child: EditorShell(
        mode: AppMode.kruskal,
        canvas: GraphWidget(
          canvasOverlay: HighlightOverlay(_treeEdgeIds, AppColors.assignmentEdge),
        ),
        functions: KruskalFunctions(
          message: message,
          result: _result,
          names: _names,
          canSolve: canSolve,
          onSolve: _solve,
          onOpenSteps: _result != null ? _openSteps : null,
          format: _fmt,
        ),
        summary: Text(
          _summaryText(message),
          style: TextStyle(
            fontSize: 15,
            color: message != null ? Theme.of(context).colorScheme.error : AppColors.blue,
          ),
        ),
        options: options,
        hint: 'Dibuja aristas no dirigidas con peso y elige el árbol en Funciones',
      ),
    );
  }
}
