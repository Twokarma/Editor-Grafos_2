import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

enum OptionKind{
  undo('Deshacer', Icons.undo, AppButtonStyle.outline, OptionGroup.history),
  redo('Rehacer', Icons.redo, AppButtonStyle.outline, OptionGroup.history),
  save('Guardar', Icons.save_outlined, AppButtonStyle.outline, OptionGroup.graph),
  open('Abrir', Icons.folder_open_outlined, AppButtonStyle.outline, OptionGroup.graph),
  clear('Limpiar', Icons.delete_sweep_outlined, AppButtonStyle.outline, OptionGroup.graph),
  manual('Manual', Icons.menu_book_outlined, AppButtonStyle.outline, OptionGroup.graph),
  help('Ayuda', Icons.help_outline, AppButtonStyle.outline, OptionGroup.graph),
  aiChat('ChatIA', Icons.chat_bubble_outline, AppButtonStyle.dark, OptionGroup.graph);

  const OptionKind(this.label, this.icon, this.style, this.group);

  final String label;
  final IconData icon;
  final AppButtonStyle style;
  final OptionGroup group;
}

enum OptionGroup{history, graph}

class OptionsConfig {
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;
  final VoidCallback? onSave;
  final VoidCallback? onOpen;
  final VoidCallback? onClear;
  final VoidCallback? onManual;
  final VoidCallback? onHelp;
  final VoidCallback? onChat;

  final bool canUndo;
  final bool canRedo;

  final bool offersChat;

  const OptionsConfig({this.onUndo, this.onRedo, this.onSave, this.onOpen, this.onClear, this.onManual, this.onHelp, this.onChat,
    this.canUndo = true, this.canRedo = true, this.offersChat = false});

  OptionsConfig withHelp(VoidCallback help) => OptionsConfig(
    onUndo: onUndo, onRedo: onRedo, onSave: onSave, onOpen: onOpen, onClear: onClear, onManual: onManual,
    onHelp: help, onChat: onChat, canUndo: canUndo, canRedo: canRedo, offersChat: offersChat,
  );

  VoidCallback? actionFor(OptionKind kind) => switch(kind){
    OptionKind.undo => onUndo,
    OptionKind.redo => onRedo,
    OptionKind.save => onSave,
    OptionKind.open => onOpen,
    OptionKind.clear => onClear,
    OptionKind.manual => onManual,
    OptionKind.help => onHelp,
    OptionKind.aiChat => onChat,
  };

  bool isOffered(OptionKind kind) => kind == OptionKind.aiChat ? offersChat || onChat != null : actionFor(kind) != null;

  bool isAvailable(OptionKind kind) => switch(kind){
    OptionKind.undo => canUndo,
    OptionKind.redo => canRedo,
    _ => true,
  };

  List<OptionItem> visibleOptions(){
    List<OptionItem> options = [];
    for(final kind in OptionKind.values){
      if(!isOffered(kind)) continue;
      options.add(OptionItem(kind: kind, action: isAvailable(kind) ? actionFor(kind) : null));
    }
    return options;
  }

}

class OptionItem{
  final OptionKind kind;
  final VoidCallback? action;

  const OptionItem({required this.kind, required this.action});
}
