import 'package:flutter/material.dart';

import '../../providers/graph_provider.dart';


void showEdgeDialog(
    BuildContext context,
    GraphProvider provider, {
      required String source,
      required String target,
      // Si es false (p. ej. Dijkstra), solo se crean aristas non-directed.
      bool allowDirected = true,
    }) {
  final controller = TextEditingController();
  final bool onlyDirected = provider.rules.forcesDirected();
  // Kruskal: siempre no dirigida, sin selector ni etiqueta.
  final bool onlyUndirected = provider.rules.forcesUndirected();
  // Se muestra el selector solo si ambas opciones son posibles.
  final bool showToggle = allowDirected && !onlyDirected && !onlyUndirected;
  bool isDirected = onlyDirected ? true : (allowDirected && !onlyUndirected);

  showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: const Text("Set weight"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showToggle)
                  ToggleButtons(
                    isSelected: [isDirected, !isDirected],
                    onPressed: (index) {
                      setDialogState(() {
                        isDirected = index == 0;
                      });
                    },
                    children: const [
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Directed"),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text("Non-directed"),
                      ),
                    ],
                  )
                else if (!allowDirected && !onlyUndirected)
                  const Text("Non-directed"),

                const SizedBox(height: 12),
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
                  if (weight != null) {
                    final message = provider.addEdge(
                      source,
                      target,
                      weight,
                      isDirected,
                    );
                    Navigator.of(dialogContext).pop();
                    if (message != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(message)),
                      );
                    }
                  }

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