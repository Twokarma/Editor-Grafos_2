import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/nav/mode_sections.dart';

class ModeDrawer extends StatelessWidget{
  final AppMode activeMode;
  final ValueChanged<AppMode> onSelection;

  const ModeDrawer({super.key, required this.activeMode, required this.onSelection});

  @override
  Widget build(BuildContext context){
    return Drawer(
      width: 290,
      backgroundColor: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadiusGeometry.horizontal(right: Radius.circular(32)),
      ),
      child: SafeArea(
          child: Padding(
              padding: EdgeInsetsGeometry.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Graph M4ker",
                    style: TextStyle(
                      color: AppColors.darkBlue,
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                      letterSpacing: -1,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 20,),
                  Expanded(
                      child: SingleChildScrollView(
                        child: ModeSections(
                            activeMode: activeMode,
                            collapsed: false,
                            onSelection: onSelection
                        ),
                      )
                  ),
                ],
              ),
          ),
      ),
    );
  }
}