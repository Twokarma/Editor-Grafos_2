import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/breakpoints.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/nav/mode_tile.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class SideNav extends StatelessWidget{
  final AppMode activeMode;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final ValueChanged<AppMode> onSelection;
  final VoidCallback onBack;

  const SideNav({super.key, required this.activeMode, required this.collapsed, required this.onToggleCollapsed, required this.onSelection, required this.onBack});

  Widget buildSections(){
    List<Widget> sections = [];
    for(var group in ModeGroup.values){
      if(group.label != ""){
        Container titleSection = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          height: 32,
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              AnimatedOpacity(
                opacity: collapsed? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: Text(
                  group.label,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  textAlign: TextAlign.start,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkBlue,
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: collapsed? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Center(
                  child: SizedBox(
                    width: 36,
                    child: Divider(
                      color: AppColors.darkBlue,
                      thickness: 1,
                    ),
                  ),
                ),
              )
            ],
          ),
        );
        sections.add(titleSection);
        sections.add(const SizedBox(height: 4,));
      }

      for(var mode in AppMode.values){
        if(mode.group != group) continue;
        sections.add(ModeTile(mode: mode, active: activeMode == mode, collapsed: collapsed, action: () => onSelection(mode)));
        sections.add(const SizedBox(height: 4,));
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: sections,);
  }

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
                    child: buildSections(),
                  ),
              ),
          ),
        ],
      ),
    );
  }
}