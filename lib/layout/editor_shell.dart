import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/web_editor_layout.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';

class EditorShell extends StatelessWidget{
    final AppMode mode;
    final String? title;
    final String? hint;
    final Widget canvas;
    final Widget functions;
    final Widget summary;
    final Widget options;

    const EditorShell ({super.key, required this.mode, this.title, this.hint, required this.canvas, required this.functions, required this.summary, required this.options});

    @override
    Widget build(BuildContext context){
        return LayoutBuilder(builder: (context, constraints){
            final width = constraints.maxWidth;
            final bool menuCollapsed = width < Breakpoints.openedMenuFrom;
            final double columnWidth = width >= Breakpoints.mobileUntil && width < Breakpoints.tightColumnUntil? Breakpoints.tightColumn : Breakpoints.wideColumn;
            return WebEditorLayout(editorShell: this, menuCollapsed: menuCollapsed, columnWidth: columnWidth);
        });
    }
}