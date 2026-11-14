import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/assignment_overlay.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/result_box.dart';

class AssignmentFunctions extends StatelessWidget {
  final String? message;
  final List<AssignmentPair>? pairs;
  final double? totalCost;
  final bool? minimized;
  final bool canSolve;
  final ValueChanged<bool> onSolve;
  final VoidCallback? onOpenMatrix;
  final String Function(double) format;
  final GlobalKey? minKey;
  final GlobalKey? maxKey;
  final GlobalKey? matrixKey;

  const AssignmentFunctions({
    super.key,
    required this.message,
    required this.pairs,
    required this.totalCost,
    required this.minimized,
    required this.canSolve,
    required this.onSolve,
    required this.onOpenMatrix,
    required this.format,
    this.minKey,
    this.maxKey,
    this.matrixKey,
  });

  String _pairValue(AssignmentPair pair) => switch (pair.kind) {
    AssignmentPairKind.real => format(pair.weight),
    AssignmentPairKind.dummy => '${format(pair.weight)} (ficticio)',
    AssignmentPairKind.noEdge => 'sin arista',
  };

  Widget _resultView(List<AssignmentPair> pairs, double total) {
    final String kind = minimized == true ? 'mínima' : 'máxima';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Asignación $kind',
            style: const TextStyle(color: AppColors.cian, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        for (final AssignmentPair pair in pairs)
          ResultRow(label: '${pair.sourceName} → ${pair.targetName}', value: _pairValue(pair)),
        const Divider(height: 12),
        ResultRow(label: 'Costo total', value: format(total), bold: true),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<AssignmentPair>? currentPairs = pairs;
    final double? total = totalCost;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResultBox(
          error: message,
          placeholder: 'Dibuja aristas con su costo de origen a destino y elige minimizar o maximizar',
          child: currentPairs == null || total == null ? null : _resultView(currentPairs, total),
        ),
        const SizedBox(height: 16),
        PillButton(
          key: minKey,
          label: 'Minimizar',
          icon: Icons.trending_down,
          style: minimized == true ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(true) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: maxKey,
          label: 'Maximizar',
          icon: Icons.trending_up,
          style: minimized == false ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(false) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: matrixKey,
          label: 'Matriz M[x]',
          icon: Icons.grid_on,
          style: AppButtonStyle.outline,
          onTap: onOpenMatrix,
          fullWidth: true,
        ),
      ],
    );
  }
}
