import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/navigation/go_to_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/canvas/dot_grid_painter.dart';
import 'package:graph_maker_app_2/widgets/nav/mode_drawer.dart';
import 'package:graph_maker_app_2/widgets/nav/pill_bar.dart';
import 'package:graph_maker_app_2/widgets/panels/functions_sheet.dart';

import 'editor_shell.dart';

class MobileEditorLayout extends StatefulWidget{
  final EditorShell editorShell;

  const MobileEditorLayout({super.key, required this.editorShell});

  @override
  State<MobileEditorLayout> createState () => _MobileEditorLayoutState();
}

class _MobileEditorLayoutState extends State<MobileEditorLayout>{
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _selectMode(AppMode mode){
    _scaffoldKey.currentState?.closeDrawer();
    goToMode(context, mode, widget.editorShell.mode);
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      key: _scaffoldKey,
      drawerEnableOpenDragGesture: false,
      drawer: ModeDrawer(
          activeMode: widget.editorShell.mode,
          onSelection: _selectMode,
      ),
      backgroundColor: AppColors.paper,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Positioned.fill(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(painter: DotGridPainter(),),
                  ),
                  widget.editorShell.canvas,
                ],
              ),
          ),
          Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                  bottom: false,
                  child: Padding(
                      padding: EdgeInsetsGeometry.only(top: 14, left: 12, right: 12),
                      child: PillBar(
                          options: widget.editorShell.options,
                          mode: widget.editorShell.mode,
                          title: widget.editorShell.title,
                          onBack: () => Navigator.maybePop(context),
                          onOpenAlgorithms: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                  ),
              ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: SafeArea(
              top: false,
              child:FunctionsSheet(
                summary: widget.editorShell.summary,
                functions: widget.editorShell.functions,
              ),
            ),
          )
        ],
      ),
    );
  }
}