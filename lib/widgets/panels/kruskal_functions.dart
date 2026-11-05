import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/kruskal.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/result_box.dart';

class KruskalFunctions extends StatelessWidget {
  final String? message;
  final KruskalResult? result;
  final Map<String, String> names;
  final bool canSolve;
  final ValueChanged<KruskalGoal> onSolve;
  final VoidCallback? onOpenSteps;
  final String Function(double) format;

  const KruskalFunctions({
    super.key,
    required this.message,
    required this.result,
    required this.names,
    required this.canSolve,
    required this.onSolve,
    required this.onOpenSteps,
    required this.format,
  });

  Widget _resultView(BuildContext context, KruskalResult result) {
    final String kind = result.goal == KruskalGoal.minimum ? 'mínimo' : 'máximo';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Árbol $kind',
            style: const TextStyle(color: AppColors.cian, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        if (!result.isConnected)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 6),
            child: Text(
              'El grafo no es conexo (${result.components} partes): es un bosque, un árbol por parte.',
              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 13),
            ),
          ),
        for (final KruskalEdge edge in result.treeEdges)
          ResultRow(label: '${names[edge.source]} - ${names[edge.target]}', value: format(edge.weight)),
        const Divider(height: 12),
        ResultRow(label: 'Peso total', value: format(result.totalWeight), bold: true),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            '${result.treeEdges.length} de ${result.steps.length} aristas en el árbol',
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final KruskalResult? current = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResultBox(
          error: message,
          placeholder: 'Dibuja aristas no dirigidas con peso y elige el árbol mínimo o máximo',
          child: current == null ? null : _resultView(context, current),
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Árbol mínimo',
          icon: Icons.trending_down,
          style: current?.goal == KruskalGoal.minimum ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(KruskalGoal.minimum) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Árbol máximo',
          icon: Icons.trending_up,
          style: current?.goal == KruskalGoal.maximum ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(KruskalGoal.maximum) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          label: 'Ver pasos',
          icon: Icons.list_alt,
          style: AppButtonStyle.outline,
          onTap: onOpenSteps,
          fullWidth: true,
        ),
      ],
    );
  }
}
