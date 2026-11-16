import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/hungarian_assignment.dart';
import '../layout/editor_shell.dart';
import '../layout/options_config.dart';
import '../models/app_mode.dart';
import '../models/assignment_overlay.dart';
import '../models/matrix_data.dart';
import '../providers/graph_provider.dart';
import '../services/assignment_service.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../tours/graph_tours.dart';
import '../widgets/overlays/assignment_canvas_overlay.dart';
import '../widgets/panels/assignment_functions.dart';
import 'chat_screen.dart';
import 'matrix_screen.dart';
import 'pdf_viewer_screen.dart';

class AssignmentScreen extends StatefulWidget {
  const AssignmentScreen({super.key});

  @override
  State<AssignmentScreen> createState() => _AssignmentScreenState();
}

class _AssignmentScreenState extends State<AssignmentScreen> {
  late final GraphProvider _provider;

  HungarianResult? _result;
  AssignmentOverlay? _overlay;
  bool? _minimized;

  final AssignmentTourKeys _tourKeys = AssignmentTourKeys();

  @override
  void initState() {
    super.initState();
    _provider = context.read<GraphProvider>();
    _provider.addListener(_clearResult);
  }

  @override
  void dispose() {
    _provider.removeListener(_clearResult);
    super.dispose();
  }

  void _clearResult() {
    if (_result == null) return;
    setState(() {
      _result = null;
      _overlay = null;
      _minimized = null;
    });
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }


  void _solve(bool minimize) {
    final MatrixData matrix = _provider.buildMatrixData();
    final AssignmentService service = AssignmentService(matrix: matrix, mode: minimize);
    final HungarianResult result;
    final AssignmentOverlay overlay;
    try {
      result = service.run();
      overlay = service.buildOverlay(result);
    } catch (e, st) {
      debugPrint('Assignment error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return;
    }
    setState(() {
      _result = result;
      _overlay = overlay;
      _minimized = minimize;
    });
  }

  void _openMatrix() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(value: _provider, child: const MatrixScreen(square: true)),
      ),
    );
  }

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(value: _provider, child: const ChatScreen()),
      ),
    );
  }

  String _summaryText(String? message) {
    final HungarianResult? result = _result;
    if (message != null) return message;
    if (result == null) return 'Elige minimizar o maximizar en Funciones';
    final String kind = _minimized == true ? 'mínima' : 'máxima';
    return 'Asignación $kind: costo ${_fmt(result.totalCost)}';
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    final List<String> messages = _provider.validateGraph();
    final bool canSolve = _provider.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final String? message = messages.isNotEmpty ? messages.first : null;
    final AssignmentOverlay? overlay = _overlay;

    final OptionsConfig options = OptionsConfig(
      onUndo: graphProvider.undo,
      onRedo: graphProvider.redo,
      onOpen: () => showOpenDialog(context, graphProvider),
      onSave: () => showSaveDialog(context, graphProvider),
      onClear: graphProvider.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Asignación',
        assetPath: 'assets/docs/guia_asignacion.pdf',
      ),
      onChat: _openChat,
      canUndo: graphProvider.canUndo,
      canRedo: graphProvider.canRedo,
    );

    return UnsavedGraphScope(
      provider: _provider,
      child: EditorShell(
        mode: AppMode.assignment,
        canvas: GraphWidget(
          canvasOverlay: AssignmentCanvasOverlay(
            overlay?.highlightedEdgeIds ?? const <String>{},
            AppColors.assignmentEdge,
            overlay?.nodes ?? const [],
            overlay?.edges ?? const [],
          ),
        ),
        functions: AssignmentFunctions(
          message: message,
          pairs: overlay?.pairs,
          totalCost: _result?.totalCost,
          minimized: _minimized,
          canSolve: canSolve,
          onSolve: _solve,
          onOpenMatrix: messages.isEmpty ? _openMatrix : null,
          format: _fmt,
          minKey: _tourKeys.minimize,
          maxKey: _tourKeys.maximize,
          matrixKey: _tourKeys.matrix,
        ),
        summary: Text(
          _summaryText(message),
          style: TextStyle(
            fontSize: 15,
            color: message != null ? Theme.of(context).colorScheme.error : AppColors.blue,
          ),
        ),
        options: options,
        tour: assignmentTour(_tourKeys),
        hint: 'Dibuja aristas con costo de origen a destino y elige en Funciones',
      ),
    );
  }
}
