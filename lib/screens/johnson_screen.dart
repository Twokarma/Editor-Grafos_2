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
import 'dart:convert';

import '../layout/breakpoints.dart';
import '../models/node.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import 'chat_screen.dart';

// ★ AYUDA: imports nuevos
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import '../widgets/graph_tour.dart';

import 'pdf_viewer_screen.dart'; // ★ MANUAL: openManual()

class JohnsonScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const JohnsonScreen({super.key, required this.mainProvider});

  @override
  State<JohnsonScreen> createState() => _JohnsonScreenState();
}

class _JohnsonScreenState extends State<JohnsonScreen> {
  JohnsonResult1? _lastResult;
  String _lastSignature = ''; // ★ ya no es late: evita errores si el listener se dispara antes
  late String _lastAppliedJson;
  JohnsonService? _service;
  Objective _objective = Objective.max;
  String? _from;
  String? _to;
  Set<String> _pathEdgeIds = {};
  String? _message;
  bool _hasChanges = true;

  late final GraphProvider _copy;

  // ★ AYUDA: keys de cada botón que explica el tour
  final _publishKey = GlobalKey();
  final _undoKey = GlobalKey();
  final _manualKey = GlobalKey();
  final _helpKey = GlobalKey();
  final _matrixKey = GlobalKey();
  final _fromKey = GlobalKey();
  final _toKey = GlobalKey();
  final _objectiveKey = GlobalKey();

  // ★ AYUDA: pasos del tour
  void _startTour() {
    final align = MediaQuery.sizeOf(context).width < Breakpoints.mobileUntil ? ContentAlign.top : ContentAlign.left;
    List<TourStep> tourSteps = [
      TourStep(_fromKey, 'Desde (Origen)',
        'Vértice desde el que se calcula el camino.',
        align: align, shape: ShapeLightFocus.RRect),
      TourStep(_toKey, 'Hacia (Destino)', 'Vértice al que quieres llegar.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_objectiveKey, 'Maximizar / Minimizar',
          'Cambia entre el camino de mayor costo y el de menor costo.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_matrixKey, 'Matriz M[x]',
          'Muestra las matrices de distancias calculadas por Johnson.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_undoKey, 'Deshacer',
          'Revierte la última acción en esta copia del grafo.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_publishKey, 'Aplicar al grafo principal',
          'Envía los cambios de esta copia al grafo principal. Se activa solo cuando hay cambios.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_manualKey, 'Cómo usar Johnson',
          'Muestra una guía para utilizar la app con Johnson.',
          align: align, shape: ShapeLightFocus.RRect)
    ].where((s) => s.key.currentContext != null).toList();

    if(tourSteps.isNotEmpty) GraphTour.show(context, tourSteps);
  }

  @override
  void initState() {
    super.initState();

    _copy = context.read<GraphProvider>();
    _copy.addListener(_onGraphChanged);
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());

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
    _copy.removeListener(_onGraphChanged);
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
    List<Node> nodes = _copy.graphGetter().nodes.values.toList();
    List<Edge> edges = _copy.graphGetter().edges.values.toList();

    if (edges.isEmpty) {
      _fail("There are no edges");
      return;
    }

    List<String> messages = _copy.validateGraph();
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
    return _copy
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
    final Map<String, Node> nodes = _copy.graphGetter().nodes;
    final Map<String, Edge> edges = _copy.graphGetter().edges;

    String path = "";
    for (int i = copy.length - 2; i >= 0; i--) {
      path += "${nodes[edges[copy[i]]!.sourceNodeId]!.name} -> ";
    }
    // ★ aviso corregido: interpolación innecesaria
    path += nodes[edges[copy[0]]!.targetNodeId]!.name;

    // JohnsonService.path() agrega la distancia total como último elemento
    return "$path = ${copy[copy.length - 1]}";
  }

  void _apply(String currentGraph){
    widget.mainProvider.replaceGraph(_copy.snapshot());
    setState(() {
      _lastAppliedJson = currentGraph;
    });
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Grafo actualizado'))
    );
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
            value: _copy,
            child: JohnsonMatrixScreen(
                nodes: _service!.nodes,
                result: _service!.result),
          )),
    );
  }

  @override
  Widget build(BuildContext context) {
    final graphProviderCopy = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final bool hasChanges = _lastAppliedJson != currentGraph;
    final List<String> messages = _copy.validateGraph();
    final bool canSolve = _copy.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final String? pathText = _pathEdgeIds.isNotEmpty? _buildTextPath() : null;

    final OptionsConfig options = OptionsConfig(
        onApply: () => _apply(currentGraph),
        onUndo: graphProviderCopy.undo,
        onHelp: _startTour,
        onOpen: () => showOpenDialog(context, graphProviderCopy),
        onSave: () => showSaveDialog(context, graphProviderCopy),
        onClear: graphProviderCopy.clearGraph,
        onManual: () => openManual(
          context,
          title: 'Johnson',
          assetPath: 'assets/docs/guia_johnson.pdf',
        ),
      hasChanges: hasChanges,
      canUndo: graphProviderCopy.canUndo,
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
        fromKey: _fromKey,
        toKey: _toKey,
        objectiveKey: _objectiveKey,
        matrixKey: _matrixKey,
    );

    return PopScope(
        canPop: !hasChanges,
        onPopInvokedWithResult: ((didPop, result) {
          if (didPop) return;
          showConfirmExitDialog(context, _copy);
        }),
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
            optionsKeys: {
              OptionKind.apply: _publishKey,
              OptionKind.undo: _undoKey,
              OptionKind.manual: _manualKey,
            },
            hint: "Elige origen, destino y objetivo en Funciones",
        ),
    );
  }
}