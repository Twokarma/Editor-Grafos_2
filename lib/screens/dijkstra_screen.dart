import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/dijkstra.dart';
import '../providers/graph_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import '../widgets/overlays/highlight_overlay.dart';
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
      );
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
    _showSummary(result);
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

  void _showSummary(DijkstraResult result) {
    final from = _names[result.sourceId];
    final to = _names[result.targetId];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.6,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!result.reachable)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'There is no path from $from to $to.',
                        style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
                      ),
                    )
                  else ...[
                    ListTile(
                      title: Text('Shortest path: $from to $to'),
                      subtitle: Text(
                        result.pathNodeIds.map((id) => _names[id]).join(' → '),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: result.pathEdges.length,
                        itemBuilder: (BuildContext context, int i) {
                          final edge = result.pathEdges[i];
                          final link = edge.directed ? '→' : '-';
                          return ListTile(
                            title: Text(
                              '${_names[result.pathNodeIds[i]]} $link ${_names[result.pathNodeIds[i + 1]]}',
                            ),
                            trailing: Text(_fmt(edge.weight)),
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Total distance:'),
                      subtitle: Text('${result.pathEdges.length} edges'),
                      trailing: Text(_fmt(result.totalDistance)),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _openSteps();
                      },
                      icon: const Icon(Icons.list_alt),
                      label: const Text('Show steps'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _nodePicker({
    required String label,
    required String? value,
    required Map<String, String> nodes,
    required ValueChanged<String?> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          items: [
            for (final entry in nodes.entries)
              DropdownMenuItem(value: entry.key, child: Text(entry.value)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
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

    void handleMenuSelection(BuildContext context, MenuOption option) {
      switch (option) {
        case MenuOption.save:
          showSaveDialog(context, graphProviderCopy);
          break;
        case MenuOption.open:
          showOpenDialog(context, graphProviderCopy);
          break;
        case MenuOption.clear:
          graphProviderCopy.clearGraph();
          break;
        default:
          break;
      }
    }

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: ((didPop, _) {
        if (didPop) return;
        showConfirmExitDialog(context, _copy);
      }),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Dijkstra"),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              tooltip: "Manual",
              onPressed: _openManual,
            ),
            IconButton(
              icon: const Icon(Icons.publish),
              tooltip: "Apply to main graph",
              onPressed: hasChanges
                  ? () {
                      widget.mainProvider.replaceGraph(_copy.snapshot());
                      setState(() {
                        _lastAppliedJson = currentGraph;
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Graph Updated')),
                      );
                    }
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: "Undo",
              onPressed: graphProviderCopy.canUndo ? () => graphProviderCopy.undo() : null,
            ),
            IconButton(
              icon: const Icon(Icons.list_alt),
              tooltip: "Show steps",
              onPressed: _result != null ? _openSteps : null,
            ),
            PopupMenuButton<MenuOption>(
              onSelected: (option) => handleMenuSelection(context, option),
              itemBuilder: (BuildContext context) => <PopupMenuEntry<MenuOption>>[
                const PopupMenuItem<MenuOption>(
                  value: MenuOption.save,
                  child: ListTile(
                    leading: Icon(Icons.save_outlined),
                    title: Text('Save'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<MenuOption>(
                  value: MenuOption.open,
                  child: ListTile(
                    leading: Icon(Icons.folder_open_outlined),
                    title: Text('Open'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                const PopupMenuItem<MenuOption>(
                  value: MenuOption.clear,
                  child: ListTile(
                    leading: Icon(Icons.delete_sweep_outlined),
                    title: Text('Clear'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        // Sin allowDirected: false, el diálogo de arista ofrece
        // Directed y Non-directed.
        body: GraphWidget(
          canvasOverlay: HighlightOverlay(_pathEdgeIds, AppColors.assignmentEdge),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      error,
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: _nodePicker(
                        label: 'From',
                        value: sourceValue,
                        nodes: nodes,
                        onChanged: (v) => setState(() {
                          _sourceId = v;
                          _result = null;
                          _pathEdgeIds = {};
                        }),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: _nodePicker(
                        label: 'To',
                        value: targetValue,
                        nodes: nodes,
                        onChanged: (v) => setState(() {
                          _targetId = v;
                          _result = null;
                          _pathEdgeIds = {};
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8.0),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canSolve ? _solve : null,
                    icon: const Icon(Icons.alt_route),
                    label: const Text('Shortest path'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}