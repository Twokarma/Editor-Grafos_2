import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class PillBar extends StatefulWidget{
  final OptionsConfig options;
  final VoidCallback? onBack;
  final VoidCallback? onOpenAlgorithms;
  final AppMode mode;
  final String? title;
  final bool expanded;
  final ValueChanged<bool> onExpandedChanged;
  final Map<OptionKind, GlobalKey> optionKeys;
  final GlobalKey? moreKey;
  final GlobalKey? islandKey;

  const PillBar({super.key, required this.options, this.onBack, this.onOpenAlgorithms, required this.mode, this.title, required this.expanded, required this.onExpandedChanged, this.optionKeys = const {}, this.moreKey, this.islandKey});

  @override
  State<PillBar> createState() => _PillBarState();
}

class _PillBarState extends State<PillBar> with SingleTickerProviderStateMixin{
  static const double _expandedHeight = 72;
  static const double _collapsedHeight = 46;
  static const double _collapsedPadding = 24;
  static const double _collapsedMinWidth = 140;
  static const TextStyle _titleStyle = TextStyle(
    color: AppColors.blue,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    reverseDuration: const Duration(milliseconds: 750),
    value: widget.expanded ? 1 : 0,
  );
  late final Animation<double> _size = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOutCubicEmphasized,
  );
  late final Animation<double> _compactOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
  );
  late final Animation<double> _fullOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.35, 1.0, curve: Curves.easeInOut),
  );

  String get _title => widget.title?? widget.mode.label;

  bool get _expanded => widget.expanded;

  void _expand() => widget.onExpandedChanged(true);

  @override
  void didUpdateWidget(PillBar oldWidget){
    super.didUpdateWidget(oldWidget);
    if(widget.expanded == oldWidget.expanded) return;
    widget.expanded ? _controller.forward() : _controller.reverse();
  }

  @override
  void dispose(){
    _controller.dispose();
    super.dispose();
  }

  double _collapsedWidth(BuildContext context, double maxWidth){
    final TextPainter painter = TextPainter(
      text: TextSpan(text: _title, style: _titleStyle),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final double width = painter.width + _collapsedPadding * 2;
    painter.dispose();
    return width.clamp(_collapsedMinWidth, maxWidth);
  }

  List<Widget> _buildMore(List<OptionItem> more){
    final List<Widget> items = [];
    for(OptionItem item in more){
      if(items.isNotEmpty && item.kind == OptionKind.aiChat){
        items.add(const Divider(height: 1,));
      }
      items.add(MenuItemButton(
        leadingIcon: Icon(item.kind.icon),
        onPressed: item.action,
        child: Text(item.kind.label,),
      ));
    }
    return items;
  }

  Widget _buildFullBar(bool narrow){
    final visible = widget.options.visibleOptions();
    final more = visible.where((o) => o.kind.group != OptionGroup.history).toList();
    final undo = visible.where((o) => o.kind == OptionKind.undo).firstOrNull;
    final redo = visible.where((o) => o.kind == OptionKind.redo).firstOrNull;
    final menuItems = narrow? visible : more;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13),
      child: Row(
        children: [
          CircleIconButton(
            size: 46,
            icon: Icons.arrow_back,
            text: "Volver al inicio",
            action: widget.onBack,
          ),
          const SizedBox(width: 8,),
          Expanded(
            child: Text(
              _title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _titleStyle,
            ),
          ),
          if(undo != null && !narrow)...[
            const SizedBox(width: 8,),
            CircleIconButton(
              key: widget.optionKeys[OptionKind.undo],
              size: 46,
              icon: OptionKind.undo.icon,
              text: "Deshacer",
              action: undo.action,
            ),
          ],
          //only move redo inside the menu
          if(redo != null && !narrow)...[
            const SizedBox(width: 8,),
            CircleIconButton(
              key: widget.optionKeys[OptionKind.redo],
              size: 46,
              icon: OptionKind.redo.icon,
              text: "Rehacer",
              action: redo.action,
            ),
          ],
          const SizedBox(width: 8,),
          CircleIconButton(
            icon: Icons.grid_view,
            text: "Menú",
            action: widget.onOpenAlgorithms,
            size: 46,
          ),
          if(menuItems.isNotEmpty)...[
            const SizedBox(width: 8,),
            MenuAnchor(
              builder: (context, controller, _){
                return CircleIconButton(
                  key: widget.moreKey,
                  icon: Icons.more_horiz,
                  text: "Más opciones",
                  action: controller.isOpen? controller.close : controller.open,
                  size: 46,
                  style: AppButtonStyle.dark,
                );
              },
              style: MenuStyle(
                backgroundColor: WidgetStateProperty.all(AppColors.white),
                shape: WidgetStateProperty.all(RoundedRectangleBorder(
                  borderRadius: BorderRadiusGeometry.circular(16),
                )),
              ),
              menuChildren: _buildMore(menuItems),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompact(){
    return Center(
      child: Text(
        _title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: _titleStyle,
      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return LayoutBuilder(builder: (context, constraints){
      final double fullWidth = constraints.maxWidth;
      final bool narrow = fullWidth < 360;
      final double collapsedWidth = _collapsedWidth(context, fullWidth);
      return SizedBox(
        height: _expandedHeight,
        child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _expanded? null : _expand,
              child: Semantics(
                button: !_expanded,
                label: _expanded? null : "Mostrar opciones",
                child: AnimatedBuilder(
                  animation: _size,
                  builder: (context, content) => Container(
                    key: widget.islandKey,
                    width: lerpDouble(collapsedWidth, fullWidth, _size.value),
                    height: lerpDouble(_collapsedHeight, _expandedHeight, _size.value),
                    clipBehavior: Clip.antiAlias,
                    decoration: ShapeDecoration(
                      color: AppColors.white,
                      shape: const StadiumBorder(),
                      shadows: [
                        BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: content,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        ignoring: _expanded,
                        child: FadeTransition(
                          opacity: ReverseAnimation(_compactOpacity),
                          child: OverflowBox(
                            minWidth: collapsedWidth,
                            maxWidth: collapsedWidth,
                            minHeight: _collapsedHeight,
                            maxHeight: _collapsedHeight,
                            child: _buildCompact(),
                          ),
                        ),
                      ),
                      IgnorePointer(
                        ignoring: !_expanded,
                        child: FadeTransition(
                          opacity: _fullOpacity,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 0.96, end: 1.0).animate(_size),
                            child: OverflowBox(
                              minWidth: fullWidth,
                              maxWidth: fullWidth,
                              minHeight: _expandedHeight,
                              maxHeight: _expandedHeight,
                              child: _buildFullBar(narrow),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      );
    });
  }
}
