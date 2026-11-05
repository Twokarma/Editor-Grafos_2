import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../ui/circle_icon_button.dart';

class FunctionsSheet extends StatefulWidget{
  final Widget summary;
  final Widget functions;

  const FunctionsSheet({super.key, required this.summary, required this.functions});

  @override
  State<FunctionsSheet> createState () => _FunctionsSheetState();
}

class _FunctionsSheetState extends State<FunctionsSheet>{
  bool _open = true;

  void _toggle() => setState(() => _open = !_open);

  @override
  Widget build(BuildContext context){
    final double keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final double screenHeight = MediaQuery.sizeOf(context).height;
    final double maxHeight = keyboard > 0
        ? (screenHeight - keyboard - 110).clamp(120.0, screenHeight / 2)
        : screenHeight / 2;
    return  Padding(
          padding: EdgeInsetsGeometry.only(left: 10, right: 10, bottom: 12 + keyboard),
          child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: ShapeDecoration(
                  color: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(30),
                  ),
                  shadows: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: 44,),
                        Expanded(
                            child: Center(
                              child: DefaultTextStyle.merge(
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                child: widget.summary,
                              ),
                            )
                        ),
                        AnimatedRotation(
                          turns: _open ? 0.5 : 0,
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          child: CircleIconButton(
                            icon: Icons.keyboard_arrow_up,
                            text: _open? "Ocultar" : "Mostrar",
                            action: _toggle,
                          ),
                        ),
                      ],
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          alignment: Alignment.topCenter,
                          child: _open? Padding(
                            padding: const EdgeInsetsGeometry.only(top: 12),
                            child: widget.functions,
                          ) : const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ),
    );
  }
}