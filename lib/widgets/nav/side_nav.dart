import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/nav/mode_sections.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class SideNav extends StatelessWidget{
  final AppMode activeMode;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<AppMode> onSelection;
  final VoidCallback onBack;

  const SideNav({super.key, required this.activeMode, required this.collapsed, required this.onToggleCollapsed, required this.onSelection, required this.onBack});

  @override
  Widget build(BuildContext context){
    return AnimatedContainer(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: AppColors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.all(Radius.circular(32)),
          )
      ),
      width: collapsed? Breakpoints.collapsedMenu : Breakpoints.openedMenu,
      curve: Curves.easeOutCubic,
      duration: const Duration(milliseconds: 450),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AnimatedSize(
              curve: Curves.easeOutCubic,
              duration: const Duration(milliseconds: 450),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                          builder: (context, constrains){
                            return Row(
                              children: [
                                CircleIconButton(
                                  icon: Icons.arrow_back,
                                  text: "Volver al inicio",
                                  action: onBack,
                                ),
                                if(!collapsed && constrains.maxWidth >= 150)...[
                                  const SizedBox(width: 10,),
                                  Expanded(
                                    child: PillButton(
                                      label: "ocultar",
                                      icon: Icons.chevron_left,
                                      style: AppButtonStyle.outline,
                                      onTap: onToggleCollapsed,
                                    ),
                                  ),
                                ]

                              ],
                            );
                          }
                      ),
                      if(collapsed)...[
                        const SizedBox(height: 4,),
                        CircleIconButton(
                          icon: Icons.chevron_right,
                          text: "Mostrar menú",
                          action: onToggleCollapsed,
                        ),
                      ],
                    ],
                  ),
              )
          ),
          const SizedBox(height: 12,),
          Expanded(
              child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
                  child: SingleChildScrollView(
                    child: ModeSections(
                        activeMode: activeMode,
                        collapsed: collapsed,
                        onSelection: onSelection
                    ),
                  ),
              ),
          ),
        ],
      ),
    );
  }
}