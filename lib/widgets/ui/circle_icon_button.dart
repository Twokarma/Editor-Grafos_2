import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

class CircleIconButton extends StatelessWidget{
  final IconData icon;
  final VoidCallback? action;
  final String text;
  final double size;
  final AppButtonStyle style;

  const CircleIconButton({super.key, required this.icon, this.action, required this.text, this.size = 44, this.style = AppButtonStyle.outline});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: text,
      child: Pressable(
        onTap: action,
        child: Opacity(
            opacity: action != null? 1 : 0.45,
          child: Container(
            height: size,
            width: size,
            decoration: ShapeDecoration(
              color: style.background,
              shape: CircleBorder(
                side: style.strokeWidth != null? BorderSide(
                  color: style.strokeColor!,
                  width: style.strokeWidth!,
                ) : BorderSide.none,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: style.textColor,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}