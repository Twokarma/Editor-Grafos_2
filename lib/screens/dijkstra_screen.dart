import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/dijkstra.dart';
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
import '../widgets/panels/dijkstra_functions.dart';
import 'dijkstra_steps_screen.dart';
import 'pdf_viewer_screen.dart';

/// Camino más corto entre dos nodos con el algoritmo de Dijkstra.
///
/// El usuario dibuja nodos y aristas con peso, dirigidas o no dirigidas, elige
/// origen y destino, y el camino queda resaltado sobre el grafo. Las aristas
/// no dirigidas se recorren en ambos sentidos; las dirigidas, solo de origen
/// a destino.
///
/// Igual que KruskalScreen, trabaja sobre una COPIA del grafo (el provider que
/// recibe de _pushWithCopy).
class DijkstraScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const DijkstraScreen({super.key, required this.mainProvider});

  @override
  State<DijkstraScreen> createState() => _DijkstraScreenState();
}

class _DijkstraScreenState extends State<DijkstraScreen> {
  late final GraphProvider _copy;
  late String _lastAppliedJson;

  DijkstraResult? _result;
  Map<String, String> _names = const {};
  Set<String> _pathEdgeIds = {};

  String? _sourceId;
  String? _targetId;

  /// true: camino más largo; false: camino más corto.
  bool _maximize = false;

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
      _pathEdgeIds = {};
    });
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  /// Mensaje de error si el grafo no se puede resolver, o null si está bien.
  /// Se valida aquí (y no con las reglas del provider) porque Dijkstra admite
  /// aristas dirigidas y no dirigidas.
  String? _validate(int nodeCount, Iterable<dynamic> edges) {
    if (nodeCount < 2) return 'Add at least two nodes.';
    if (edges.isEmpty) return 'Add at least one edge.';
    // El camino más largo en un grafo sin ciclos admite pesos negativos.
    if (_maximize) return null;
    for (final e in edges) {
      if ((e.weight as num) < 0) {
        return 'Dijkstra does not support negative weights.';
      }
    }
    return null;
  }

  void _solve() {
    final graph = _copy.graphGetter();
    final names = {for (final n in graph.nodes.values) n.id: n.name};

    final DijkstraResult result;
    try {
      result = DijkstraAlgorithm.solve(
        nodeIds: graph.nodes.keys.toList(),
        edges: [
          for (final e in graph.edges.values)
            DijkstraEdge(
              e.id,
              e.sourceNodeId,
              e.targetNodeId,
              e.weight,
              directed: e.directed,
            ),
        ],
        sourceId: _sourceId!,
        targetId: _targetId!,
        maximize: _maximize,
        names: names,
      );
    } on ArgumentError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.message}')),
      );
      return;
    } catch (e, st) {
      debugPrint('Dijkstra error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return;
    }

    setState(() {
      _result = result;
      _names = names;
      _pathEdgeIds = {for (final e in result.pathEdges) e.id};
    });
  }

  void _openManual() {
    openManual(
      context,
      title: 'Manual de Dijkstra',
      assetPath: 'assets/docs/guia_dijkstra.pdf',
    );
  }

  void _openSteps() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DijkstraStepsScreen(result: result, names: _names),
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

  void _select({String? source, String? target}) {
    setState(() {
      if (source != null) _sourceId = source;
      if (target != null) _targetId = target;
      _result = null;
      _pathEdgeIds = {};
    });
  }

  String _summaryText(String? error) {
    final DijkstraResult? result = _result;
    if (error != null) return error;
    if (result == null) return 'Elige origen y destino en Funciones';
    if (!result.reachable) return 'No hay camino de ${_names[result.sourceId]} a ${_names[result.targetId]}';
    return '${result.pathNodeIds.map((id) => _names[id]).join(' → ')} = ${_fmt(result.totalDistance)}';
  }

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final graph = _copy.graphGetter();
    final String currentGraph = jsonEncode(graph.toJson());
    final String? error = _validate(graph.nodes.length, graph.edges.values);
    final bool hasChanges = _lastAppliedJson != currentGraph;

    final nodes = {for (final n in graph.nodes.values) n.id: n.name};
    // Si se borró un nodo elegido, se descarta la selección.
    final String? sourceValue = nodes.containsKey(_sourceId) ? _sourceId : null;
    final String? targetValue = nodes.containsKey(_targetId) ? _targetId : null;

    final bool canSolve =
        error == null && sourceValue != null && targetValue != null;

    final OptionsConfig options = OptionsConfig(
      onApply: () => _apply(currentGraph),
      onUndo: graphProviderCopy.undo,
      onOpen: () => showOpenDialog(context, graphProviderCopy),
      onSave: () => showSaveDialog(context, graphProviderCopy),
      onClear: graphProviderCopy.clearGraph,
      onManual: _openManual,
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
        mode: AppMode.dijkstra,
        // Sin allowDirected: false, el diálogo de arista ofrece
        // Directed y Non-directed.
        canvas: GraphWidget(
          canvasOverlay: HighlightOverlay(_pathEdgeIds, AppColors.assignmentEdge),
        ),
        functions: DijkstraFunctions(
          message: error,
          result: _result,
          names: _names,
          nodes: nodes,
          from: sourceValue,
          to: targetValue,
          canSolve: canSolve,
          maximize: _maximize,
          onMaximizeChanged: (v) => setState(() {
            _maximize = v;
            _result = null;
            _pathEdgeIds = {};
          }),
          onFromChanged: (v) => _select(source: v),
          onToChanged: (v) => _select(target: v),
          onSolve: _solve,
          onOpenSteps: _result != null ? _openSteps : null,
          format: _fmt,
        ),
        summary: Text(
          _summaryText(error),
          style: TextStyle(
            fontSize: 15,
            color: error != null ? Theme.of(context).colorScheme.error : AppColors.blue,
          ),
        ),
        options: options,
        hint: 'Elige origen y destino en Funciones',
      ),
    );
  }
}
