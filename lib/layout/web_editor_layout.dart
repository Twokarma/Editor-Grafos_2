import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/editor_card.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/side_column.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/navigation/go_to_mode.dart';
import 'package:graph_maker_app_2/widgets/nav/side_nav.dart';
import 'package:graph_maker_app_2/widgets/panels/options_panel.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';

class WebEditorLayout extends StatefulWidget{
  final EditorShell editorShell;
  final bool menuCollapsed;
  final double columnWidth;

  const WebEditorLayout({super.key, required this.editorShell, required this.menuCollapsed, required this.columnWidth});

  @override
  State<WebEditorLayout> createState() => _WebEditorLayoutState();
}

class _WebEditorLayoutState extends State<WebEditorLayout>{
  bool? _userCollapsed;
  bool _chatOpen = false;

  bool get effectiveValue => _userCollapsed?? widget.menuCollapsed;

  void toggle() => setState(() => _userCollapsed = !effectiveValue);

  @override
  Widget build(BuildContext context){
    AppMode editorMode = widget.editorShell.mode;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    return Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Padding(
          padding: const EdgeInsetsGeometry.all(Breakpoints.margin),
          child: Row(
            children: [
              SideNav(
                  activeMode: editorMode,
                  collapsed: effectiveValue,
                  onToggleCollapsed: toggle,
                  onSelection: (mode) => goToMode(context, mode, editorMode),
                  onBack: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: Breakpoints.margin,),
              Expanded(
                child: EditorCard(
                    title: widget.editorShell.title?? "Editor · ${editorMode.label}",
                    hint: widget.editorShell.hint?? editorMode.description,
                    child: widget.editorShell.canvas
                ),
              ),
              const SizedBox(width: Breakpoints.margin,),
              SizedBox(
                width: widget.columnWidth,
                child: SideColumn(
                  gap: Breakpoints.margin,
                  summaryCap: screenHeight * 0.3,
                  optionsCap: screenHeight * 0.3,
                  minFunctionsHeight: screenHeight * 0.3,
                  summary: widget.editorShell.summaryOnWeb? PanelCard(
                      title: "Resumen",
                      child: widget.editorShell.summary,
                  ) : null,
                  functions: PanelCard(
                      title: "Funciones",
                      child: widget.editorShell.functions
                  ),
                  options: OptionsPanel(
                      optionsConfig: widget.editorShell.options,
                      keys: widget.editorShell.optionsKeys,
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}