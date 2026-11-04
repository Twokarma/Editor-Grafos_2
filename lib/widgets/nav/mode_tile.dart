import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

enum ModeTileStyle{
  normal(Colors.transparent,AppColors.darkBlue, 1.5, AppColors.darkBlue, Colors.transparent, TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.normal), 0),
  hover(Colors.transparent,AppColors.darkBlue, 1.5, AppColors.darkBlue, AppColors.navHover, TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.normal), 4),
  active(AppColors.blue, AppColors.paper, null, AppColors.white, AppColors.navActive, TextStyle(color: AppColors.darkBlue, fontWeight: FontWeight.w600), 0);

  const ModeTileStyle(
      this.circleBackgroundColor,
      this.circleStrokeColor,
      this.circleStrokeWidth,
      this.initialsTextColor,
      this.backgroundColor,
      this.textStyle,
      this.movement
      );


  final Color circleBackgroundColor;
  final Color circleStrokeColor;
  final double? circleStrokeWidth;
  final Color initialsTextColor;
  final Color backgroundColor;
  final TextStyle textStyle;
  final double movement;
}

class ModeTile extends StatelessWidget{
  final AppMode mode;
  final bool active;
  final bool collapsed;
  final VoidCallback? action;

  const ModeTile({super.key, required this.mode, required this.active, required this.collapsed, required this.action});

  Widget buildPressable(){
    return Semantics(
      selected: active,
      child: Pressable(
        hoverLift: 0,
        onTap: action,
        builder: (context, hovered){
          final ModeTileStyle style = active? ModeTileStyle.active : hovered? ModeTileStyle.hover : ModeTileStyle.normal;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: ShapeDecoration(
              color: style.backgroundColor,
              shape: const StadiumBorder(),
            ),
            height: 52,
            transform: Matrix4.translationValues(style.movement, 0, 0),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 36,
                  width: 36,
                  decoration: ShapeDecoration(
                    color: style.circleBackgroundColor,
                    shape: CircleBorder(
                      side: style.circleStrokeWidth != null? BorderSide(
                        color: style.circleStrokeColor,
                        width: style.circleStrokeWidth!,
                      ) : BorderSide.none,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: ExcludeSemantics(
                    child: Text(
                      mode.initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: style.initialsTextColor,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child: AnimatedOpacity(
                    opacity: collapsed? 0 : 1,
                    duration: Duration(milliseconds: 250),
                    child: Padding(
                      padding: EdgeInsetsGeometry.directional(start: 12),
                      child: Text(
                        mode.label,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: style.textStyle.copyWith(fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },

      ),
    );
  }

  @override
  Widget build(BuildContext context){
    return collapsed? Tooltip(
      message: mode.label,
      child: buildPressable(),
    ) : buildPressable();
  }
}