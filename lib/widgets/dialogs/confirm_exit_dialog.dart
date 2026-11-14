import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/widgets/dialogs/save_graph_dialog.dart';

enum ExitOption {save, dontSave, cancel}

Future<bool> confirmLeaveGraph(BuildContext context, GraphProvider provider) async {
  if(!provider.hasUnsavedChanges) return true;

  final ExitOption? option = await showDialog<ExitOption>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text("Grafo sin guardar"),
          content: const Text("¿Quieres guardar el grafo antes de salir?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.cancel),
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.dontSave),
              child: const Text("No guardar"),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(ExitOption.save),
              child: const Text("Guardar"),
            ),
          ],
        );
      }
  );

  if(option == null || !context.mounted) return false;

  return switch(option){
    ExitOption.dontSave => true,
    ExitOption.save => await showSaveDialog(context, provider),
    ExitOption.cancel => false,
  };
}

class UnsavedGraphScope extends StatelessWidget{
  final GraphProvider provider;
  final Widget child;

  const UnsavedGraphScope({super.key, required this.provider, required this.child});

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if(didPop) return;
        final NavigatorState navigator = Navigator.of(context);
        if(await confirmLeaveGraph(context, provider)) navigator.pop();
      },
      child: child,
    );
  }
}
