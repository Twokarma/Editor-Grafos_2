import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/dijkstra.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/result_box.dart';

class DijkstraFunctions extends StatelessWidget {
  final String? message;
  final DijkstraResult? result;
  final Map<String, String> names;
  final Map<String, String> nodes;
  final String? from;
  final String? to;
  final bool canSolve;
  final bool maximize;
  final ValueChanged<bool> onMaximizeChanged;
  final ValueChanged<String?> onFromChanged;
  final ValueChanged<String?> onToChanged;
  final VoidCallback onSolve;
  final VoidCallback? onOpenSteps;
  final String Function(double) format;

  const DijkstraFunctions({
    super.key,
    required this.message,
    required this.result,
    required this.names,
    required this.nodes,
    required this.from,
    required this.to,
    required this.canSolve,
    required this.maximize,
    required this.onMaximizeChanged,
    required this.onFromChanged,
    required this.onToChanged,
    required this.onSolve,
    required this.onOpenSteps,
    required this.format,
  });

  Widget _nodeDropDown(String label, String? value, ValueChanged<String?> onSelected) {
    return DropdownMenu<String>(
      key: ValueKey('${label}_${value}_${nodes.length}'),
      expandedInsets: EdgeInsets.zero,
      initialSelection: value,
      label: Text(label),
      requestFocusOnTap: false,
      enabled: nodes.isNotEmpty,
      menuHeight: 300,
      textStyle: const TextStyle(color: AppColors.darkBlue, fontSize: 16, fontWeight: FontWeight.w600),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: AppColors.darkBlue),
        floatingLabelStyle: const TextStyle(color: AppColors.blue),
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        enabledBorder: ShapedInputBorder(
          shape: const StadiumBorder(),
          borderSide: const BorderSide(color: AppColors.darkBlue, width: 1.5),
        ),
        disabledBorder: ShapedInputBorder(
          shape: const StadiumBorder(),
          borderSide: BorderSide(color: AppColors.darkBlue.withValues(alpha: 0.3), width: 1.5),
        ),
      ),
      dropdownMenuEntries: [
        for (final MapEntry<String, String> entry in nodes.entries)
          DropdownMenuEntry<String>(value: entry.key, label: entry.value),
      ],
      onSelected: onSelected,
    );
  }

  Widget _resultView(BuildContext context, DijkstraResult result) {
    final String? fromName = names[result.sourceId];
    final String? toName = names[result.targetId];
    if (!result.reachable) {
      return Text(
        'No hay camino de $fromName a $toName',
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
            result.pathNodeIds.map((id) => names[id]).join(' → '),
            style: const TextStyle(color: AppColors.cian, fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
        for (int i = 0; i < result.pathEdges.length; i++)
          ResultRow(
            label: '${names[result.pathNodeIds[i]]} ${result.pathEdges[i].directed ? '→' : '-'} '
                '${names[result.pathNodeIds[i + 1]]}',
            value: format(result.pathEdges[i].weight),
          ),
        const Divider(height: 12),
        ResultRow(label: result.maximize ? 'Distancia total (máxima)' : 'Distancia total', value: format(result.totalDistance), bold: true),
        Padding(
          padding: const EdgeInsets.only(left: 4, top: 2),
          child: Text(
            '${result.pathEdges.length} ${result.pathEdges.length == 1 ? 'arista' : 'aristas'}',
            style: const TextStyle(color: AppColors.gray, fontSize: 12),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DijkstraResult? current = result;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResultBox(
          error: message,
          placeholder: maximize
              ? 'Elige origen y destino y busca el camino más largo'
              : 'Elige origen y destino y busca el camino más corto',
          child: current == null ? null : _resultView(context, current),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          return constraints.maxWidth >= 300
              ? Row(
                  children: [
                    Expanded(child: _nodeDropDown('Desde', from, onFromChanged)),
                    const SizedBox(width: 8),
                    Expanded(child: _nodeDropDown('Hacia', to, onToChanged)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _nodeDropDown('Desde', from, onFromChanged),
                    const SizedBox(height: 16),
                    _nodeDropDown('Hacia', to, onToChanged),
                  ],
                );
        }),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment<bool>(value: false, label: Text('Minimizar'), icon: Icon(Icons.south)),
            ButtonSegment<bool>(value: true, label: Text('Maximizar'), icon: Icon(Icons.north)),
          ],
          selected: {maximize},
          onSelectionChanged: (s) => onMaximizeChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.blue,
            selectedForegroundColor: AppColors.white,
            foregroundColor: AppColors.darkBlue,
            side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
          ),
        ),
        if (maximize)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'Para maximizar, las aristas deben ser dirigidas y sin ciclos',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.gray, fontSize: 12),
            ),
          ),
        const SizedBox(height: 16),
        PillButton(
          label: maximize ? 'Camino más largo' : 'Camino más corto',
          icon: Icons.alt_route,
          style: AppButtonStyle.accent,
          onTap: canSolve ? onSolve : null,
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
