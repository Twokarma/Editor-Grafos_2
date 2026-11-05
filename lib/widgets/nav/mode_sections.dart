import 'package:flutter/material.dart';

import '../../models/app_mode.dart';
import '../../theme/app_colors.dart';
import 'mode_tile.dart';

class ModeSections extends StatelessWidget{
  final AppMode activeMode;
  final bool collapsed;
  final ValueChanged<AppMode> onSelection;

  const ModeSections({super.key, required this.activeMode, required this.collapsed, required this.onSelection});

  @override
  Widget build(BuildContext context){
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
}