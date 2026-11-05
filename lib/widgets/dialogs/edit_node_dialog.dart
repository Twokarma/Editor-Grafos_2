import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../../providers/graph_provider.dart';


Future<void> showEditNodeDialog(BuildContext context, GraphProvider provider, String nodeId) {
  final node = provider.graphGetter().nodes[nodeId]!;
  final controller = TextEditingController(text: node.name);
  int selectedColor = node.color;
  final bool isValue = provider.rules.nodesAreValues;
  String? error;

  return showDialog(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          return AlertDialog(
            title: Text(isValue ? "Editar nodo" : "Edit node"),
            content: SizedBox(
              width: 320,
              height: 380,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    TabBar(
                      tabs: [
                        Tab(text: isValue ? "Valor" : "Name"),
                        Tab(text: "Color"),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: TextField(
                              controller: controller,
                              autofocus: true,
                              keyboardType: isValue
                                  ? const TextInputType.numberWithOptions(decimal: true, signed: true)
                                  : null,
                              onChanged: (_) {
                                if (error != null) setDialogState(() => error = null);
                              },
                              decoration: InputDecoration(
                                hintText: isValue ? "Ej.: 5 o 3.5" : "Node name",
                                errorText: error,
                                errorMaxLines: 3,
                              ),
                            ),
                          ),
                          SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: ColorPicker(
                                pickerColor: Color(selectedColor),
                                onColorChanged: (color) {
                                  setDialogState(() {
                                    selectedColor = color.toARGB32();
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(isValue ? "Cancelar" : "Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final String? message = provider.updateNode(nodeId, newName: controller.text, newColor: selectedColor);
                  if (message != null) {
                    setDialogState(() => error = message);
                    return;
                  }
                  Navigator.of(dialogContext).pop();
                },
                child: Text(isValue ? "Guardar" : "Save"),
              ),
            ],
          );
        },
      );
    },
  );
}
