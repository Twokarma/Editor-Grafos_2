import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/models/app_mode.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/circle_icon_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class PillBar extends StatelessWidget{
  final OptionsConfig options;
  final VoidCallback? onBack;
  final VoidCallback? onOpenAlgorithms;
  final AppMode mode;
  final String? title;

  const PillBar({super.key, required this.options, this.onBack, this.onOpenAlgorithms, required this.mode, this.title});

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

  @override
  Widget build(BuildContext context){
    final visible = options.visibleOptions();
    final more = visible.where((o) => o.kind.group != OptionGroup.history).toList();
    final undo = visible.where((o) => o.kind == OptionKind.undo).firstOrNull;
    final redo = visible.where((o) => o.kind == OptionKind.redo).firstOrNull;
    return LayoutBuilder(builder: (context, constraints){
      final width = constraints.maxWidth;
      final narrow = width < 360;
      final menuItems =  narrow? visible : more;
      return Container(
        height: 72,
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
        padding: const EdgeInsets.symmetric(horizontal: 13),
        child: Row(
          children: [
            CircleIconButton(
              size: 46,
              icon: Icons.arrow_back,
              text: "Volver al inicio",
              action: onBack,
            ),
            const SizedBox(width: 8,),
            Expanded(
              child: Text(
                title?? mode.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if(undo != null && !narrow)...[
              const SizedBox(width: 8,),
              CircleIconButton(
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
              action: onOpenAlgorithms,
              size: 46,
            ),
            if(menuItems.isNotEmpty)...[
              const SizedBox(width: 8,),
              MenuAnchor(
                builder: (context, controller, _){
                  return CircleIconButton(
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
    });
  }
}