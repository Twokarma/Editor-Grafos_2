import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/mobile_editor_layout.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/layout/web_editor_layout.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';

class EditorShell extends StatelessWidget{
    final AppMode mode;
    final String? title;
    final String? hint;
    final Widget canvas;
    final Widget functions;
    final Widget summary;
    final bool summaryOnWeb;
    final OptionsConfig options;
    final Map<OptionKind, GlobalKey> optionsKeys;

    const EditorShell ({
        super.key,
        required this.mode,
        this.title, this.hint,
        required this.canvas,
        required this.functions,
        required this.summary,
        this.summaryOnWeb = false,
        required this.options,
        this.optionsKeys = const <OptionKind, GlobalKey>{}
    });

    @override
    Widget build(BuildContext context){
        return LayoutBuilder(builder: (context, constraints){
            final width = constraints.maxWidth;
            final bool menuCollapsed = width < Breakpoints.openedMenuFrom;
            final double columnWidth = width >= Breakpoints.mobileUntil && width < Breakpoints.tightColumnUntil? Breakpoints.tightColumn : Breakpoints.wideColumn;
            return width < Breakpoints.mobileUntil? MobileEditorLayout(editorShell: this) : WebEditorLayout(editorShell: this, menuCollapsed: menuCollapsed, columnWidth: columnWidth);
        });
    }
}