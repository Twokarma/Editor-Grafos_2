import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/binary_tree.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/models/graph.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/dialogs/confirm_exit_dialog.dart';
import 'package:graph_maker_app_2/widgets/dialogs/open_graph_dialog.dart';
import 'package:graph_maker_app_2/widgets/dialogs/save_graph_dialog.dart';
import 'package:graph_maker_app_2/widgets/graph_canvas.dart';
import 'package:graph_maker_app_2/widgets/graph_tour.dart';
import 'package:graph_maker_app_2/widgets/overlays/tree_overlay.dart';
import 'package:graph_maker_app_2/widgets/panels/tree_functions.dart';
import 'package:graph_maker_app_2/screens/pdf_viewer_screen.dart';
import 'package:provider/provider.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

class TreeScreen extends StatefulWidget {
  final GraphProvider mainProvider;
  const TreeScreen({super.key, required this.mainProvider});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  late final GraphProvider _copy;
  late String _lastAppliedJson;

  TreePair _pair = TreePair.postIn;
  final TextEditingController _postController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();
  String? _buildError;

  int _nodeCount = 7;

  Traversal? _selectedTraversal;

  Size _canvasSize = const Size(600, 400);

  final TreeTourKeys _tourKeys = TreeTourKeys();
  final GlobalKey _publishKey = GlobalKey();
  final GlobalKey _undoKey = GlobalKey();
  final GlobalKey _manualKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _copy = context.read<GraphProvider>();
    _lastAppliedJson = jsonEncode(_copy.graphGetter().toJson());
    _postController.addListener(_onFieldsChanged);
    _otherController.addListener(_onFieldsChanged);
  }

  @override
  void dispose() {
    _postController.dispose();
    _otherController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    setState(() => _buildError = null);
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < Breakpoints.mobileUntil;

  ({double top, double bottom}) get _canvasPadding => _isMobile
      ? (top: 96, bottom: MediaQuery.sizeOf(context).height / 2 + 40)
      : (top: 24, bottom: 24);

  int get _maxNodes => BinaryTree.maxNodesFor(_canvasSize.width).clamp(1, BinaryTree.maxRandomNodes);

  void _drawTree(TreeNode root) {
    final padding = _canvasPadding;
    final Graph graph = BinaryTree.toGraph(root, _canvasSize, top: padding.top, bottom: padding.bottom);
    _copy.replaceGraph(graph);
    if (BinaryTree.count(root) > BinaryTree.maxNodesFor(_canvasSize.width)) {
      _snack('El árbol es más ancho que el lienzo: algunos nodos quedan fuera de la vista');
    }
  }

  void _build() {
    FocusScope.of(context).unfocus();
    final TreeResult result = BinaryTree.fromTraversals(
      BinaryTree.parseList(_postController.text),
      BinaryTree.parseList(_otherController.text),
      _pair,
    );
    if (!result.isOk) {
      setState(() => _buildError = result.error);
      return;
    }
    _autoText[_postController] = _postController.text;
    _autoText[_otherController] = _otherController.text;
    _drawTree(result.root!);
  }

  void _generate() {
    _drawTree(BinaryTree.random(_nodeCount.clamp(1, _maxNodes)));
  }

  void _useInBuild(Map<Traversal, List<String>> lists) {
    _setAuto(_postController, lists[Traversal.post]!.join(', '));
    _setAuto(_otherController, lists[_pair.other]!.join(', '));
  }

  final Map<TextEditingController, String> _autoText = {};

  void _setAuto(TextEditingController controller, String text) {
    _autoText[controller] = text;
    if (controller.text != text) controller.text = text;
  }

  void _syncField(TextEditingController controller, String text) {
    if (controller.text == text) {
      _autoText[controller] = text;
      return;
    }
    if (controller.text != (_autoText[controller] ?? '')) return;
    _setAuto(controller, text);
  }

  void _syncFields(Map<Traversal, List<String>>? lists) {
    _syncField(_postController, lists == null ? '' : lists[Traversal.post]!.join(', '));
    _syncField(_otherController, lists == null ? '' : lists[_pair.other]!.join(', '));
  }

  void _apply(String currentGraph) {
    widget.mainProvider.replaceGraph(_copy.snapshot());
    setState(() => _lastAppliedJson = currentGraph);
    _snack('Grafo actualizado');
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  void _onCanvasSize(Size size) {
    if (size == _canvasSize || size.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _canvasSize = size;
        _nodeCount = _nodeCount.clamp(1, _maxNodes);
      });
    });
  }

  void _startTour() {
    final align = _isMobile ? ContentAlign.top : ContentAlign.left;
    final List<TourStep> steps = [
      TourStep(_tourKeys.traversals, 'Recorridos',
          'Preorden, inorden y postorden del árbol dibujado. Toca uno para numerar los nodos en el lienzo. '
          'Un hijo con valor menor o igual al del padre va a la izquierda; uno mayor, a la derecha.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.pair, 'Pareja de recorridos',
          'Elige si vas a escribir el postorden con el inorden o con el preorden.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.postField, 'Postorden', 'Los valores en postorden, separados por comas o espacios. Empieza con el árbol actual.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.otherField, 'Segundo recorrido', 'El inorden o preorden de los mismos valores.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.build, 'Construir', 'Dibuja el único árbol que tiene esos dos recorridos.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.count, 'Cantidad de nodos', 'Tamaño del árbol aleatorio.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_tourKeys.generate, 'Generar', 'Reemplaza el lienzo por un árbol aleatorio.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_undoKey, 'Deshacer', 'Recupera lo que había antes de construir o generar.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_publishKey, 'Aplicar al grafo principal',
          'Envía el árbol al grafo principal. Se activa solo cuando hay cambios.',
          align: align, shape: ShapeLightFocus.RRect),
      TourStep(_manualKey, 'Cómo usar Árboles',
          'Abre la guía del modo Árboles en PDF.',
          align: align, shape: ShapeLightFocus.RRect),
    ].where((s) => s.key.currentContext != null).toList();

    if (steps.isNotEmpty) GraphTour.show(context, steps);
  }

  @override
  Widget build(BuildContext context) {
    final GraphProvider provider = context.watch<GraphProvider>();
    final String currentGraph = jsonEncode(_copy.graphGetter().toJson());
    final bool hasChanges = _lastAppliedJson != currentGraph;

    final TreeResult tree = BinaryTree.fromGraph(_copy.graphGetter());
    final Map<Traversal, List<TreeNode>>? orders = tree.root == null
        ? null
        : {for (final t in Traversal.values) t: BinaryTree.traverse(tree.root, t)};
    final Map<Traversal, List<String>>? lists =
        orders?.map((t, nodes) => MapEntry(t, nodes.map((n) => n.label).toList()));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncFields(lists);
    });

    final Map<String, int> visitOrder = {};
    if (orders != null && _selectedTraversal != null) {
      final List<TreeNode> sequence = orders[_selectedTraversal]!;
      for (int i = 0; i < sequence.length; i++) {
        visitOrder[sequence[i].nodeId!] = i + 1;
      }
    }

    final bool canBuild = _postController.text.trim().isNotEmpty && _otherController.text.trim().isNotEmpty;

    final OptionsConfig options = OptionsConfig(
      onApply: () => _apply(currentGraph),
      onUndo: provider.undo,
      onHelp: _startTour,
      onOpen: () => showOpenDialog(context, provider),
      onSave: () => showSaveDialog(context, provider),
      onClear: provider.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Árboles',
        assetPath: 'assets/docs/guia_arboles.pdf',
      ),
      hasChanges: hasChanges,
      canUndo: provider.canUndo,
    );

    final bool mobile = _isMobile;
    final TreeTraversalsBlock traversalsBlock = TreeTraversalsBlock(
      traversals: lists,
      treeError: tree.error,
      selectedTraversal: _selectedTraversal,
      onTraversalTap: (t) => setState(() => _selectedTraversal = _selectedTraversal == t ? null : t),
      onUseInBuild: lists == null ? null : () => _useInBuild(lists),
      boxKey: _tourKeys.traversals,
    );

    final TreeFunctions functions = TreeFunctions(
      traversalsBlock: mobile ? traversalsBlock : null,
      pair: _pair,
      onPairChanged: (p) => setState(() {
        _pair = p;
        _buildError = null;
      }),
      postController: _postController,
      otherController: _otherController,
      buildError: _buildError,
      onBuild: canBuild ? _build : null,
      nodeCount: _nodeCount,
      maxNodes: _maxNodes,
      onNodeCountChanged: (n) => setState(() => _nodeCount = n),
      onGenerate: _generate,
      keys: _tourKeys,
    );

    return PopScope(
      canPop: !hasChanges,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showConfirmExitDialog(context, _copy);
      },
      child: EditorShell(
        mode: AppMode.tree,
        canvas: LayoutBuilder(builder: (context, constraints) {
          _onCanvasSize(constraints.biggest);
          return GraphWidget(canvasOverlay: TreeOverlay(visitOrder: visitOrder));
        }),
        functions: functions,
        summary: mobile ? _TreeSummaryLine(lists: lists, error: tree.error) : traversalsBlock,
        summaryOnWeb: true,
        options: options,
        optionsKeys: {
          OptionKind.apply: _publishKey,
          OptionKind.undo: _undoKey,
          OptionKind.manual: _manualKey,
        },
        hint: 'Toca el lienzo para crear un nodo con su valor y arrastra del padre al hijo',
      ),
    );
  }
}

class _TreeSummaryLine extends StatelessWidget {
  final Map<Traversal, List<String>>? lists;
  final String? error;

  const _TreeSummaryLine({required this.lists, required this.error});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Text(error!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.w600));
    }
    if (lists == null) {
      return const Text('Árbol vacío', style: TextStyle(color: AppColors.gray));
    }
    return Text(
      'Pre: ${lists![Traversal.pre]!.join(' ')}',
      style: const TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w600),
    );
  }
}
