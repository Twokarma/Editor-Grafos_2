import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';

class PanelCard extends StatelessWidget{
  final String title;
  final Widget child;
  final bool scrollable;
  final bool expanded;
  final VoidCallback? onToggle;

  const PanelCard({super.key, required this.title, required this.child, this.scrollable = true, this.expanded = true, this.onToggle});

  @override
  Widget build(BuildContext context){
    final Widget header = Semantics(
      header: true,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.w600,
          color: AppColors.darkBlue,
        ),
      ),
    );
    final Widget body = scrollable? SingleChildScrollView(child: child) : child;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: ShapeDecoration(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: const BorderRadius.all(Radius.circular(32.0)),
          ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          onToggle == null? header : Row(
            children: [
              Expanded(child: header),
              const SizedBox(width: 8,),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                child: CircleIconButton(
                  icon: Icons.keyboard_arrow_up,
                  text: expanded? "Ocultar" : "Mostrar",
                  action: onToggle,
                ),
              ),
            ],
          ),
          Flexible(
            fit: FlexFit.loose,
            child: AnimatedSize(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: expanded? Padding(
                padding: const EdgeInsets.only(top: 14),
                child: body,
              ) : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
