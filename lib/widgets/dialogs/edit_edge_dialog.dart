import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/graph_provider.dart';


// [allowDirected] se acepta para que GraphWidget pueda pasarlo igual que a
// showEdgeDialog. Este diálogo solo edita el peso, no el tipo de arista, así
// que hoy no hace falta usarlo.
Future<void> showEditEdgeDialog(
  BuildContext context,
  GraphProvider provider,
  String edgeId, {
  bool allowDirected = true,
}) {
  final edge = provider.graphGetter().edges[edgeId]!;
  final controller = TextEditingController(text: edge.weight.toString());

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text("Edit edge"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(hintText: "6.54"),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final weight = double.tryParse(controller.text);
                  if(weight != null) {
                    provider.updateEdgeWeight(edgeId, weight);
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: const Text("Save"),
              ),
            ],
          );
        },
      );
    },
  );
}