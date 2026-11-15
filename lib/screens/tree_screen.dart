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
import 'package:graph_maker_app_2/tours/tree_sort_tours.dart';
import 'package:graph_maker_app_2/widgets/overlays/tree_overlay.dart';
import 'package:graph_maker_app_2/widgets/panels/tree_functions.dart';
import 'package:graph_maker_app_2/screens/pdf_viewer_screen.dart';
import 'package:provider/provider.dart';

class TreeScreen extends StatefulWidget {
  const TreeScreen({super.key});

  @override
  State<TreeScreen> createState() => _TreeScreenState();
}

class _TreeScreenState extends State<TreeScreen> {
  late final GraphProvider _provider;

  TreePair _pair = TreePair.inPost;
  final TextEditingController _inController = TextEditingController();
  final TextEditingController _otherController = TextEditingController();
  String? _buildError;

  final TextEditingController _insertController = TextEditingController();
  final FocusNode _insertFocus = FocusNode();
  String? _insertError;

  int _nodeCount = 7;

  Traversal? _selectedTraversal;

  final TreeTourKeys _tourKeys = TreeTourKeys();

  @override
  void initState() {
    super.initState();
    _provider = context.read<GraphProvider>();
    _inController.addListener(_onFieldsChanged);
    _otherController.addListener(_onFieldsChanged);
    _insertController.addListener(_onInsertChanged);
  }

  @override
  void dispose() {
    _inController.dispose();
    _otherController.dispose();
    _insertController.dispose();
    _insertFocus.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    setState(() => _buildError = null);
  }

  void _onInsertChanged() {
    setState(() => _insertError = null);
  }

  bool get _isMobile => MediaQuery.sizeOf(context).width < Breakpoints.mobileUntil;

  void _drawTree(TreeNode root) {
    final Graph graph = BinaryTree.toGraph(root, BinaryTree.layoutArea(root));
    _provider.replaceGraph(graph);
  }

  void _build() {
    FocusScope.of(context).unfocus();
    final TreeResult result = BinaryTree.fromTraversals(
      BinaryTree.parseList(_inController.text),
      BinaryTree.parseList(_otherController.text),
      _pair,
    );
    if (!result.isOk) {
      setState(() => _buildError = result.error);
      return;
    }
    _autoText[_inController] = _inController.text;
    _autoText[_otherController] = _otherController.text;
    _drawTree(result.root!);
  }

  void _insert() {
    final List<String> values = BinaryTree.parseList(_insertController.text);
    final TreeResult current = BinaryTree.fromGraph(_provider.graphGetter());
    if (!current.isOk) {
      setState(() => _insertError = 'Corrige el árbol del lienzo antes de insertar: ${current.error}');
      return;
    }
    final TreeResult result = BinaryTree.insertAll(current.root, values);
    if (!result.isOk) {
      setState(() => _insertError = result.error);
      return;
    }
    _drawTree(result.root!);
    _insertController.clear();
    _insertFocus.requestFocus();
  }

  void _generate() {
    _drawTree(BinaryTree.random(_nodeCount.clamp(1, BinaryTree.maxRandomNodes)));
  }

  void _useInBuild(Map<Traversal, List<String>> lists) {
    _setAuto(_inController, lists[Traversal.inorder]!.join(', '));
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
    _syncField(_inController, lists == null ? '' : lists[Traversal.inorder]!.join(', '));
    _syncField(_otherController, lists == null ? '' : lists[_pair.other]!.join(', '));
  }

  @override
  Widget build(BuildContext context) {
    final GraphProvider provider = context.watch<GraphProvider>();
    final TreeResult tree = BinaryTree.fromGraph(_provider.graphGetter());
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

    final bool canBuild = _inController.text.trim().isNotEmpty && _otherController.text.trim().isNotEmpty;

    final OptionsConfig options = OptionsConfig(
      onUndo: provider.undo,
      onRedo: provider.redo,
      onOpen: () => showOpenDialog(context, provider),
      onSave: () => showSaveDialog(context, provider),
      onClear: provider.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Árboles',
        assetPath: 'assets/docs/guia_arboles.pdf',
      ),
      canUndo: provider.canUndo,
      canRedo: provider.canRedo,
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
      inController: _inController,
      otherController: _otherController,
      buildError: _buildError,
      onBuild: canBuild ? _build : null,
      insertController: _insertController,
      insertFocusNode: _insertFocus,
      insertError: _insertError,
      onInsert: _insertController.text.trim().isNotEmpty ? _insert : null,
      nodeCount: _nodeCount,
      maxNodes: BinaryTree.maxRandomNodes,
      onNodeCountChanged: (n) => setState(() => _nodeCount = n),
      onGenerate: _generate,
      keys: _tourKeys,
    );

    return UnsavedGraphScope(
      provider: _provider,
      child: EditorShell(
        mode: AppMode.tree,
        canvas: GraphWidget(canvasOverlay: TreeOverlay(visitOrder: visitOrder)),
        functions: functions,
        summary: mobile ? _TreeSummaryLine(lists: lists, error: tree.error) : traversalsBlock,
        summaryOnWeb: true,
        options: options,
        tour: treeTour(_tourKeys),
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
