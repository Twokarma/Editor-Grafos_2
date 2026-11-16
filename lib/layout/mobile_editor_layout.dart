import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:graph_maker_app_2/layout/editor_tour_host.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:graph_maker_app_2/navigation/go_to_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/canvas/canvas_insets.dart';
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

class _MobileEditorLayoutState extends State<MobileEditorLayout> with EditorTourHost<MobileEditorLayout>{
  static const double _islandTop = 14;
  static const double _islandHeight = 72;
  static const Duration _islandAnimation = Duration(milliseconds: 900);
  static const Duration _sheetAnimation = Duration(milliseconds: 450);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _islandOpen = false;
  bool _sheetOpen = true;
  double _sheetHeight = 0;
  (bool, bool)? _savedState;

  @override
  EditorShell get shell => widget.editorShell;

  @override
  bool get isTouchLayout => true;

  @override
  Future<void> reveal(TourArea area) async {
    final bool island = area == TourArea.options;
    final bool sheet = switch(area){
      TourArea.functions => true,
      TourArea.canvas || TourArea.zoom => false,
      _ => _sheetOpen,
    };
    final bool islandChanged = island != _islandOpen;
    final bool sheetChanged = sheet != _sheetOpen;
    if(islandChanged || sheetChanged){
      setState(() {
        _islandOpen = island;
        _sheetOpen = sheet;
      });
    }
    await settle(islandChanged || sheetChanged, islandChanged ? _islandAnimation : _sheetAnimation);
  }

  @override
  void saveState() => _savedState = (_islandOpen, _sheetOpen);

  @override
  void restoreState(){
    final (bool, bool)? saved = _savedState;
    if(saved == null || !mounted) return;
    setState(() {
      _islandOpen = saved.$1;
      _sheetOpen = saved.$2;
    });
  }

  void _onSheetSize(Size size){
    if(size.height == _sheetHeight) return;
    setState(() => _sheetHeight = size.height);
  }

  void _setIsland(bool open){
    if(open == _islandOpen) return;
    setState(() => _islandOpen = open);
  }

  void _selectMode(AppMode mode){
    _scaffoldKey.currentState?.closeDrawer();
    goToMode(context, mode, widget.editorShell.mode);
  }

  @override
  Widget build(BuildContext context){
    final double canvasTop = MediaQuery.paddingOf(context).top + _islandTop + _islandHeight;
    return tourScope(Scaffold(
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
              child: CanvasInsets(
                insets: EdgeInsets.only(
                  top: canvasTop,
                  bottom: _sheetHeight,
                ),
                controlsAxis: Axis.vertical,
                child: withTourInvite(widget.editorShell.canvas, top: canvasTop + 8),
              ),
          ),
          Positioned(
            top: canvasTop, left: 0, right: 0, bottom: _sheetHeight,
            child: IgnorePointer(
              child: SizedBox.expand(key: anchorFor(TourArea.canvas)),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: _SizeReporter(
              onSize: _onSheetSize,
              child: SafeArea(
                top: false,
                child:FunctionsSheet(
                  key: anchorFor(TourArea.functions),
                  summary: widget.editorShell.summary,
                  functions: widget.editorShell.functions,
                  open: _sheetOpen,
                  onToggle: () => setState(() => _sheetOpen = !_sheetOpen),
                ),
              ),
            ),
          ),
          if(_islandOpen)
            Positioned.fill(
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _setIsland(false),
              ),
            ),
          Positioned(
              top: 0, left: 0, right: 0,
              child: SafeArea(
                  bottom: false,
                  child: Padding(
                      padding: EdgeInsetsGeometry.only(top: _islandTop, left: 12, right: 12),
                      child: PillBar(
                          options: tourOptions,
                          optionKeys: optionKeys,
                          moreKey: anchorFor(TourArea.options),
                          islandKey: anchorFor(TourArea.navigation),
                          mode: widget.editorShell.mode,
                          title: widget.editorShell.title,
                          expanded: _islandOpen,
                          onExpandedChanged: _setIsland,
                          onBack: () => Navigator.maybePop(context),
                          onOpenAlgorithms: () => _scaffoldKey.currentState?.openDrawer(),
                      ),
                  ),
              ),
          ),
        ],
      ),
    ));
  }
}

class _SizeReporter extends SingleChildRenderObjectWidget{
  final ValueChanged<Size> onSize;

  const _SizeReporter({required this.onSize, required super.child});

  @override
  _RenderSizeReporter createRenderObject(BuildContext context) => _RenderSizeReporter(onSize);

  @override
  void updateRenderObject(BuildContext context, _RenderSizeReporter renderObject){
    renderObject.onSize = onSize;
  }
}

class _RenderSizeReporter extends RenderProxyBox{
  ValueChanged<Size> onSize;
  Size? _reported;

  _RenderSizeReporter(this.onSize);

  @override
  void performLayout(){
    super.performLayout();
    if(size == _reported) return;
    _reported = size;
    final Size reported = size;
    WidgetsBinding.instance.addPostFrameCallback((_) => onSize(reported));
  }
}
