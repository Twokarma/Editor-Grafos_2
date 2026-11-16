import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/layout/editor_card.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/editor_tour_host.dart';
import 'package:graph_maker_app_2/layout/side_column.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/navigation/go_to_mode.dart';
import 'package:graph_maker_app_2/widgets/nav/side_nav.dart';
import 'package:graph_maker_app_2/widgets/panels/options_panel.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:graph_maker_app_2/widgets/ui/panel_card.dart';

class WebEditorLayout extends StatefulWidget{
  final EditorShell editorShell;
  final bool menuCollapsed;
  final double columnWidth;

  const WebEditorLayout({super.key, required this.editorShell, required this.menuCollapsed, required this.columnWidth});

  @override
  State<WebEditorLayout> createState() => _WebEditorLayoutState();
}

class _WebEditorLayoutState extends State<WebEditorLayout> with EditorTourHost<WebEditorLayout>{
  static const Duration _panelAnimation = Duration(milliseconds: 450);

  bool? _userCollapsed;
  bool _chatOpen = false;

  bool get effectiveValue => _userCollapsed?? widget.menuCollapsed;

  void toggle() => setState(() => _userCollapsed = !effectiveValue);

  _SidePanel? _openPanel = _SidePanel.functions;
  _SidePanel? _savedPanel;

  void _togglePanel(_SidePanel panel) => setState(() => _openPanel = _openPanel == panel ? null : panel);

  @override
  EditorShell get shell => widget.editorShell;

  @override
  bool get isTouchLayout => false;

  @override
  Future<void> reveal(TourArea area) async {
    final _SidePanel? wanted = switch(area){
      TourArea.functions => _SidePanel.functions,
      TourArea.options => _SidePanel.options,
      _ => _openPanel,
    };
    final bool changed = wanted != _openPanel;
    if(changed) setState(() => _openPanel = wanted);
    await settle(changed, _panelAnimation);
  }

  @override
  void saveState() => _savedPanel = _openPanel;

  @override
  void restoreState(){
    if(mounted) setState(() => _openPanel = _savedPanel);
  }

  @override
  Widget build(BuildContext context){
    AppMode editorMode = widget.editorShell.mode;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    return tourScope(Scaffold(
      backgroundColor: AppColors.paper,
      body: Stack(
        children: [
          Padding(
          padding: const EdgeInsetsGeometry.all(Breakpoints.margin),
          child: Row(
            children: [
              KeyedSubtree(
                key: anchorFor(TourArea.navigation),
                child: SideNav(
                    activeMode: editorMode,
                    collapsed: effectiveValue,
                    onToggleCollapsed: toggle,
                    onSelection: (mode) => goToMode(context, mode, editorMode),
                    onBack: () => Navigator.maybePop(context),
                ),
              ),
              const SizedBox(width: Breakpoints.margin,),
              Expanded(
                child: EditorCard(
                    title: widget.editorShell.title?? "Editor · ${editorMode.label}",
                    hint: widget.editorShell.hint?? editorMode.description,
                    child: withTourInvite(
                      KeyedSubtree(key: anchorFor(TourArea.canvas), child: widget.editorShell.canvas),
                    ),
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
                  functionsExpanded: _openPanel == _SidePanel.functions,
                  summary: widget.editorShell.summaryOnWeb? PanelCard(
                      title: "Resumen",
                      child: widget.editorShell.summary,
                  ) : null,
                  functions: PanelCard(
                      key: anchorFor(TourArea.functions),
                      title: "Funciones",
                      expanded: _openPanel == _SidePanel.functions,
                      onToggle: () => _togglePanel(_SidePanel.functions),
                      child: widget.editorShell.functions
                  ),
                  options: OptionsPanel(
                      key: anchorFor(TourArea.options),
                      optionsConfig: tourOptions,
                      keys: optionKeys,
                      expanded: _openPanel == _SidePanel.options,
                      onToggle: () => _togglePanel(_SidePanel.options),
                  ),
                ),
              ),
            ],
          ),
          ),
        ],
      ),
    ));
  }
}

enum _SidePanel{functions, options}
