import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/transportation.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/result_box.dart';

class TransportFunctions extends StatelessWidget {
  final String? message;
  final TransportationResult? result;
  final List<String> sourceNames;
  final List<String> destinationNames;
  final bool canSolve;
  final ValueChanged<TransportGoal> onSolve;
  final VoidCallback? onOpenSteps;
  final String Function(double) format;
  final GlobalKey? minKey;
  final GlobalKey? maxKey;
  final GlobalKey? stepsKey;

  const TransportFunctions({
    super.key,
    required this.message,
    required this.result,
    required this.sourceNames,
    required this.destinationNames,
    required this.canSolve,
    required this.onSolve,
    required this.onOpenSteps,
    required this.format,
    this.minKey,
    this.maxKey,
    this.stepsKey,
  });

  Widget _resultView(BuildContext context, TransportationResult result) {
    final String kind = result.goal == TransportGoal.minimize ? 'mínimo' : 'máximo';
    if (result.isInfeasible) {
      return Text(
        'Sin solución: las aristas existentes no cubren toda la oferta y la demanda.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 15, fontWeight: FontWeight.w600),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            'Costo $kind',
            style: const TextStyle(color: AppColors.cian, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        for (final TransportFlow flow in result.realFlows)
          ResultRow(
            label: '${sourceNames[flow.row]} → ${destinationNames[flow.col]}  '
                '(${format(flow.amount)} × ${format(result.costs[flow.row][flow.col]!)})',
            value: format(flow.amount * result.costs[flow.row][flow.col]!),
          ),
        const Divider(height: 12),
        ResultRow(label: 'Costo total', value: format(result.totalCost), bold: true),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            'Esquina noroeste: ${format(result.initialCost)} · Pasos MODI: ${result.iterations.length}',
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final TransportationResult? current = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResultBox(
          error: message,
          placeholder: 'Dibuja aristas con costo de origen a destino y elige minimizar o maximizar',
          child: current == null ? null : _resultView(context, current),
        ),
        const SizedBox(height: 16),
        PillButton(
          key: minKey,
          label: 'Minimizar',
          icon: Icons.trending_down,
          style: current?.goal == TransportGoal.minimize ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(TransportGoal.minimize) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: maxKey,
          label: 'Maximizar',
          icon: Icons.trending_up,
          style: current?.goal == TransportGoal.maximize ? AppButtonStyle.accent : AppButtonStyle.outline,
          onTap: canSolve ? () => onSolve(TransportGoal.maximize) : null,
          fullWidth: true,
        ),
        const SizedBox(height: 16),
        PillButton(
          key: stepsKey,
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
