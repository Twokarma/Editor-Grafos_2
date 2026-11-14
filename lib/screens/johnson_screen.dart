import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/johnson1.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/models/edge.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/screens/johnson_matrix_screen.dart';
import 'package:graph_maker_app_2/services/johnson_service.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:graph_maker_app_2/widgets/overlays/johnson_overlay.dart';
import 'package:graph_maker_app_2/widgets/panels/johnson_functions.dart';
import 'package:graph_maker_app_2/widgets/panels/options_panel.dart';
import 'package:provider/provider.dart';

import '../models/node.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import 'chat_screen.dart';

import '../tours/graph_tours.dart';

import 'pdf_viewer_screen.dart'; // ★ MANUAL: openManual()

class JohnsonScreen extends StatefulWidget {
  const JohnsonScreen({super.key});

  @override
  State<JohnsonScreen> createState() => _JohnsonScreenState();
}

class _JohnsonScreenState extends State<JohnsonScreen> {
  JohnsonResult1? _lastResult;
  String _lastSignature = ''; // ★ ya no es late: evita errores si el listener se dispara antes
  JohnsonService? _service;
  Objective _objective = Objective.max;
  String? _from;
  String? _to;
  Set<String> _pathEdgeIds = {};
  String? _message;
  bool _hasChanges = true;

  late final GraphProvider _provider;

  final JohnsonTourKeys _tourKeys = JohnsonTourKeys();

  @override
  void initState() {
    super.initState();

    _provider = context.read<GraphProvider>();
    _provider.addListener(_onGraphChanged);

    // ★ setState dentro de _runJohnson: se ejecuta después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _runJohnson();
    });
  }

  void _onGraphChanged() {
    // Sin setState ni postFrameCallback: context.watch ya reconstruye la
    // pantalla, y el camino viejo debe limpiarse antes de ese build
    // (si no, _buildTextPath busca aristas borradas).
    if (_lastSignature != _structureSignature()) {
      _lastResult = null;
      _pathEdgeIds = {};
      _message = null;
      _hasChanges = true;
    } else {
      _hasChanges = false;
    }
  }

  @override
  void dispose() {
    _provider.removeListener(_onGraphChanged);
    super.dispose();
  }

  void _fail(String message) {
    setState(() {
      _service = null;
      _lastResult = null;
      _pathEdgeIds = <String>{};
      _from = null;
      _to = null;
      _message = message;
    });
  }

  void _runJohnson() {
    _lastSignature = _structureSignature();
    List<Node> nodes = _provider.graphGetter().nodes.values.toList();
    List<Edge> edges = _provider.graphGetter().edges.values.toList();

    if (edges.isEmpty) {
      _fail("There are no edges");
      return;
    }

    List<String> messages = _provider.validateGraph();
    if (messages.isNotEmpty) {
      // ★ CORRECCIÓN: faltaba el return
      _fail(messages.first);
      return;
    }

    Set<String> sources = {};
    Set<String> targets = {};
    for (Edge edge in edges) {
      sources.add(edge.sourceNodeId);
      targets.add(edge.targetNodeId);
    }

    // ★ CORRECCIÓN: ambas diferencias se calculan sobre los conjuntos originales
    final Set<String> nodesFrom = sources.difference(targets);
    final Set<String> nodesTo = targets.difference(sources);

    if (nodesFrom.isEmpty || nodesTo.isEmpty) {
      _fail("No start or end node");
      return;
    }
    final String nodeFrom = nodesFrom.first;
    final String nodeTo = nodesTo.first;

    _service = JohnsonService(
        nodes: nodes, edges: edges, nodeFrom: nodeFrom, nodeTo: nodeTo);
    JohnsonResult1 result = _service!.run();

    int n = result.distanceMax.length;
    for (int i = 0; i < n; i++) {
      if (result.distanceMax[i][i] != 0 || result.distanceMin[i][i] != 0) {
        _fail("Cycle detected");
        return;
      }
    }
    setState(() {
      _lastResult = result;
      _from = _service?.nodeFrom;
      _to = _service?.nodeTo;
      _hasChanges = false;
      _message = null;
    });

    _pathUpdate();
  }

  String _structureSignature() {
    return _provider
        .graphGetter()
        .edges
        .values
        .map((e) => [
              e.id,
              e.sourceNodeId,
              e.targetNodeId,
              e.weight,
              e.directed,
            ])
        .toList()
        .toString();
  }

  void _pathUpdate() {
    if (_service == null ||
        _lastResult == null ||
        _from == null ||
        _to == null) {
      setState(() {
        _pathEdgeIds = <String>{};
      });
      return;
    }
    final Set<String> path = _service!.path(_objective, from: _from, to: _to);

    // ★ un solo setState
    setState(() {
      if (path.isEmpty || _from == _to) {
        _message =
            "No path from ${_service!.nodes[_service!.index[_from]!].name} to ${_service!.nodes[_service!.index[_to]!].name}";
      } else {
        _message = null;
      }
      _pathEdgeIds = path;
    });
  }

  String _buildTextPath() {
    if (_pathEdgeIds.isEmpty) return '';

    final List<String> copy = _pathEdgeIds.toList();
    final Map<String, Node> nodes = _provider.graphGetter().nodes;
    final Map<String, Edge> edges = _provider.graphGetter().edges;

    String path = "";
    for (int i = copy.length - 2; i >= 0; i--) {
      path += "${nodes[edges[copy[i]]!.sourceNodeId]!.name} -> ";
    }
    // ★ aviso corregido: interpolación innecesaria
    path += nodes[edges[copy[0]]!.targetNodeId]!.name;

    // JohnsonService.path() agrega la distancia total como último elemento
    return "$path = ${copy[copy.length - 1]}";
  }

  void _changeFrom(String? id){
    setState(() {
      _from = id;
    });
    _pathUpdate();
  }

  void _changeTo(String? id){
    setState(() {
      _to = id;
    });
    _pathUpdate();
  }

  void _changeObjective(Objective newObjective){
    setState(() {
      _objective = newObjective;
    });
    if(_hasChanges) _runJohnson();
    _pathUpdate();
  }

  void _openMatrix(){
    Navigator.of(context).push(
      MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider.value(
            value: _provider,
            child: JohnsonMatrixScreen(
                nodes: _service!.nodes,
                result: _service!.result),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    final List<String> messages = _provider.validateGraph();
    final bool canSolve = _provider.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final String? pathText = _pathEdgeIds.isNotEmpty? _buildTextPath() : null;

    final OptionsConfig options = OptionsConfig(
        onUndo: graphProvider.undo,
        onRedo: graphProvider.redo,
        onOpen: () => showOpenDialog(context, graphProvider),
        onSave: () => showSaveDialog(context, graphProvider),
        onClear: graphProvider.clearGraph,
        onManual: () => openManual(
          context,
          title: 'Johnson',
          assetPath: 'assets/docs/guia_johnson.pdf',
        ),
      canUndo: graphProvider.canUndo,
      canRedo: graphProvider.canRedo,
    );
    final JohnsonFunctions functions = JohnsonFunctions(
        path: pathText,
        message: _message,
        nodes: _service?.nodes ?? [],
        from: _from,
        to: _to,
        objective: _objective,
        canSolve: canSolve,
        resultExists: _lastResult != null,
        onFromChanged: _changeFrom,
        onToChanged: _changeTo,
        onObjectiveChanged: _changeObjective,
        onOpenMatrix: _openMatrix,
        fromKey: _tourKeys.from,
        toKey: _tourKeys.to,
        objectiveKey: _tourKeys.objective,
        matrixKey: _tourKeys.matrix,
    );

    return UnsavedGraphScope(
        provider: _provider,
        child: EditorShell(
            mode: AppMode.johnson,
            canvas: GraphWidget(
              canvasOverlay: JohnsonOverlay(
                  _pathEdgeIds,
                  _objective == Objective.max? AppColors.maxJohnson : AppColors.minJohnson,
                  _lastResult ?? JohnsonResult1(),
                  _lastResult != null? _service!.nodes : <Node>[]
              ),
            ),
            functions: functions,
            summary: Text(
              _message?? pathText?? '',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.blue,
              ),
            ),
            options: options,
            tour: johnsonTour(_tourKeys),
            hint: "Elige origen, destino y objetivo en Funciones",
        ),
    );
  }
}