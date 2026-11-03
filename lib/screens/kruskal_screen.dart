import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/kruskal.dart';
import '../providers/graph_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/menu_option.dart';
import '../widgets/overlays/highlight_overlay.dart';
import 'kruskal_steps_screen.dart';

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
    _showSummary(result);
  }

  String _edgeName(KruskalEdge e) => '${_names[e.source]} - ${_names[e.target]}';

  void _openSteps() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => KruskalStepsScreen(result: result, names: _names),
      ),
    );
  }

  void _showSummary(KruskalResult result) {
    final kind = result.goal == KruskalGoal.minimum ? 'minimum' : 'maximum';
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
                  if (!result.isConnected)
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        'The graph is not connected (${result.components} parts), '
                        'so there is no tree that reaches every node. '
                        'This is a spanning forest: one tree per part.',
                        style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
                      ),
                    ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: result.treeEdges.length,
                      itemBuilder: (BuildContext context, int i) {
                        final edge = result.treeEdges[i];
                        return ListTile(
                          title: Text(_edgeName(edge)),
                          trailing: Text(_fmt(edge.weight)),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    title: Text('Total weight ($kind):'),
                    subtitle: Text(
                      '${result.treeEdges.length} of ${result.steps.length} edges in the tree',
                    ),
                    trailing: Text(_fmt(result.totalWeight)),
                  ),
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

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final List<String> messages = _copy.validateGraph();
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final bool canSolve = _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;

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
          title: const Text("Kruskal"),
          actions: [
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
        body: GraphWidget(
          canvasOverlay: HighlightOverlay(_treeEdgeIds, AppColors.assignmentEdge),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (messages.isNotEmpty)
                  Text(
                    messages.first,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSolve ? () => _solve(KruskalGoal.minimum) : null,
                        icon: const Icon(Icons.trending_down),
                        label: const Text('Minimum tree'),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: canSolve ? () => _solve(KruskalGoal.maximum) : null,
                        icon: const Icon(Icons.trending_up),
                        label: const Text('Maximum tree'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
