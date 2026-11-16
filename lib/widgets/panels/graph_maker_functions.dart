import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/result_box.dart';

class GraphMakerFunctions extends StatelessWidget {
  final int nodeCount;
  final int edgeCount;
  final int directedCount;
  final VoidCallback? onOpenMatrix;
  final GlobalKey? matrixKey;

  const GraphMakerFunctions({
    super.key,
    required this.nodeCount,
    required this.edgeCount,
    required this.directedCount,
    required this.onOpenMatrix,
    this.matrixKey,
  });

  @override
  Widget build(BuildContext context) {
    final bool empty = nodeCount == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        ResultBox(
          placeholder: 'Toca el lienzo para crear un nodo y arrastra entre nodos para crear aristas',
          child: empty ? null : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ResultRow(label: 'Nodos', value: '$nodeCount'),
              ResultRow(label: 'Aristas', value: '$edgeCount'),
              ResultRow(label: 'Dirigidas', value: '$directedCount'),
              ResultRow(label: 'No dirigidas', value: '${edgeCount - directedCount}'),
            ],
          ),
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
