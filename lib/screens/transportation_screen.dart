import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../algorithms/transportation.dart';
import '../layout/editor_shell.dart';
import '../layout/options_config.dart';
import '../models/app_mode.dart';
import '../models/assignment_overlay.dart';
import '../models/matrix_data.dart';
import '../providers/graph_provider.dart';
import '../services/transportation_overlay_builder.dart';
import '../theme/app_colors.dart';
import '../widgets/dialogs/confirm_exit_dialog.dart';
import '../widgets/dialogs/open_graph_dialog.dart';
import '../widgets/dialogs/save_graph_dialog.dart';
import '../widgets/graph_canvas.dart';
import '../widgets/overlays/assignment_canvas_overlay.dart';
import '../widgets/panels/transport_functions.dart';
import '../tours/graph_tours.dart';
import 'pdf_viewer_screen.dart';
import 'transportation_steps_screen.dart';

class TransportationScreen extends StatefulWidget {
  const TransportationScreen({super.key});

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen> {
  final TransportTourKeys _tourKeys = TransportTourKeys();

  late final GraphProvider _provider;

  TransportationResult? _result;
  List<String> _sourceNames = const [];
  List<String> _destinationNames = const [];
  AssignmentOverlay _overlay = AssignmentOverlay();

  final Map<String, String> _supplyText = {};
  final Map<String, String> _demandText = {};

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
      _overlay = AssignmentOverlay();
    });
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  Future<void> _solve(TransportGoal goal) async {
    final MatrixData matrix = _provider.buildMatrixData();
    final rows = matrix.rowHeaders;
    final cols = matrix.colHeaders;

    final inputs = await showDialog<_TransportInputs>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SupplyDemandDialog(
        goal: goal,
        sourceNames: [for (final n in rows) n.name],
        destinationNames: [for (final n in cols) n.name],
        initialSupply: [for (final n in rows) _supplyText[n.id] ?? ''],
        initialDemand: [for (final n in cols) _demandText[n.id] ?? ''],
      ),
    );
    if (inputs == null || !mounted) return;

    for (var i = 0; i < rows.length; i++) {
      _supplyText[rows[i].id] = inputs.supplyText[i];
    }
    for (var j = 0; j < cols.length; j++) {
      _demandText[cols[j].id] = inputs.demandText[j];
    }

    final costs = [
      for (var i = 0; i < rows.length; i++)
        [
          for (var j = 0; j < cols.length; j++)
            matrix.hasEdge[i][j] ? matrix.matrix[i][j] : null,
        ],
    ];

    final TransportationResult result;
    try {
      result = TransportationAlgorithm.solve(TransportationProblem(
        costs: costs,
        supply: inputs.supply,
        demand: inputs.demand,
        goal: goal,
      ));
    } catch (e, st) {
      debugPrint('Transportation error: $e\n$st');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      return;
    }

    final overlay = TransportationOverlayBuilder.build(matrix, result);

    setState(() {
      _result = result;
      _sourceNames = [for (final n in rows) n.name];
      _destinationNames = [for (final n in cols) n.name];
      _overlay = overlay;
    });
  }

  void _openSteps() {
    final result = _result;
    if (result == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransportationStepsScreen(
          result: result,
          sourceNames: _sourceNames,
          destinationNames: _destinationNames,
        ),
      ),
    );
  }

  String _summaryText(String? message) {
    final TransportationResult? result = _result;
    if (message != null) return message;
    if (result == null) return 'Elige minimizar o maximizar en Funciones';
    if (result.isInfeasible) return 'Sin solución con las aristas actuales';
    final String kind = result.goal == TransportGoal.minimize ? 'mínimo' : 'máximo';
    return 'Costo $kind: ${_fmt(result.totalCost)}';
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    final List<String> messages = _provider.validateGraph();
    final bool canSolve = _provider.graphGetter().edges.isNotEmpty && messages.isEmpty;
    final String? message = messages.isNotEmpty ? messages.first : null;
    final bool infeasible = _result?.isInfeasible ?? false;

    final OptionsConfig options = OptionsConfig(
      onUndo: graphProvider.undo,
      onRedo: graphProvider.redo,
      onOpen: () => showOpenDialog(context, graphProvider),
      onSave: () => showSaveDialog(context, graphProvider),
      onClear: graphProvider.clearGraph,
      onManual: () => openManual(
        context,
        title: 'Transporte',
        assetPath: 'assets/docs/guia_transporte.pdf',
      ),
      canUndo: graphProvider.canUndo,
      canRedo: graphProvider.canRedo,
    );

    return UnsavedGraphScope(
      provider: _provider,
      child: EditorShell(
        mode: AppMode.transporte,
        canvas: GraphWidget(
          canvasOverlay: AssignmentCanvasOverlay(
            _overlay.highlightedEdgeIds,
            AppColors.assignmentEdge,
            _overlay.nodes,
            _overlay.edges,
          ),
        ),
        functions: TransportFunctions(
          message: message,
          result: _result,
          sourceNames: _sourceNames,
          destinationNames: _destinationNames,
          canSolve: canSolve,
          onSolve: _solve,
          onOpenSteps: _result != null ? _openSteps : null,
          format: _fmt,
          minKey: _tourKeys.minimize,
          maxKey: _tourKeys.maximize,
          stepsKey: _tourKeys.steps,
        ),
        summary: Text(
          _summaryText(message),
          style: TextStyle(
            fontSize: 15,
            color: message != null || infeasible ? Theme.of(context).colorScheme.error : AppColors.blue,
          ),
        ),
        options: options,
        tour: transportTour(_tourKeys),
        hint: 'Dibuja aristas con costo de origen a destino y elige en Funciones',
      ),
    );
  }
}

/// Lo que devuelve el diálogo de oferta y demanda.
class _TransportInputs {
  final List<String> supplyText;
  final List<String> demandText;
  final List<double> supply;
  final List<double> demand;
  const _TransportInputs(
      this.supplyText, this.demandText, this.supply, this.demand);
}

/// Pide la oferta de cada origen y la demanda de cada destino.
class _SupplyDemandDialog extends StatefulWidget {
  final TransportGoal goal;
  final List<String> sourceNames;
  final List<String> destinationNames;
  final List<String> initialSupply;
  final List<String> initialDemand;

  const _SupplyDemandDialog({
    required this.goal,
    required this.sourceNames,
    required this.destinationNames,
    required this.initialSupply,
    required this.initialDemand,
  });

  @override
  State<_SupplyDemandDialog> createState() => _SupplyDemandDialogState();
}

class _SupplyDemandDialogState extends State<_SupplyDemandDialog> {
  late final List<TextEditingController> _supplyCtrls;
  late final List<TextEditingController> _demandCtrls;
  String? _error;

  @override
  void initState() {
    super.initState();
    _supplyCtrls = [
      for (final t in widget.initialSupply) TextEditingController(text: t),
    ];
    _demandCtrls = [
      for (final t in widget.initialDemand) TextEditingController(text: t),
    ];
  }

  @override
  void dispose() {
    for (final c in _supplyCtrls) {
      c.dispose();
    }
    for (final c in _demandCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  double? _parse(String text) => double.tryParse(text.trim().replaceAll(',', '.'));

  void _submit() {
    final supply = [for (final c in _supplyCtrls) _parse(c.text)];
    final demand = [for (final c in _demandCtrls) _parse(c.text)];
    final valid = [...supply, ...demand].every((v) => v != null && v.isFinite && v >= 0);
    if (!valid) {
      setState(() => _error = 'Escribe un número (0 o más) en cada campo.');
      return;
    }
    Navigator.of(context).pop(_TransportInputs(
      [for (final c in _supplyCtrls) c.text],
      [for (final c in _demandCtrls) c.text],
      [for (final v in supply) v!],
      [for (final v in demand) v!],
    ));
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(labelText: label, isDense: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final goalText =
        widget.goal == TransportGoal.minimize ? 'Minimizar costo' : 'Maximizar costo';
    final error = _error;

    return AlertDialog(
      title: Text(goalText),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Oferta de cada origen',
                  style: Theme.of(context).textTheme.titleSmall),
              for (var i = 0; i < _supplyCtrls.length; i++)
                _field(_supplyCtrls[i], widget.sourceNames[i]),
              const SizedBox(height: 16),
              Text('Demanda de cada destino',
                  style: Theme.of(context).textTheme.titleSmall),
              for (var j = 0; j < _demandCtrls.length; j++)
                _field(_demandCtrls[j], widget.destinationNames[j]),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    error,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('Resolver'),
        ),
      ],
    );
  }
}
