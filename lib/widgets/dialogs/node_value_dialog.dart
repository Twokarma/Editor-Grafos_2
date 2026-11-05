import 'package:flutter/material.dart';

import '../../providers/graph_provider.dart';

Future<void> showNodeValueDialog(BuildContext context, GraphProvider provider, double x, double y) {
  final controller = TextEditingController();
  String? error;

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          void submit() {
            final String? message = provider.addNode(x, y, name: controller.text);
            if (message != null) {
              setDialogState(() => error = message);
              return;
            }
            Navigator.of(dialogContext).pop();
          }

          return AlertDialog(
            title: const Text("Nuevo nodo"),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => submit(),
              onChanged: (_) {
                if (error != null) setDialogState(() => error = null);
              },
              decoration: InputDecoration(
                labelText: "Valor",
                hintText: "Ej.: 5 o 3.5",
                errorText: error,
                errorMaxLines: 3,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text("Cancelar"),
              ),
              TextButton(
                onPressed: submit,
                child: const Text("Crear"),
              ),
            ],
          );
        },
      );
    },
  );
}
