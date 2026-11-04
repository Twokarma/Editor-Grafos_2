import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/canvas/dot_grid_painter.dart';

class EditorCard extends StatelessWidget{
  final String title;
  final String? hint;
  final Widget child;

  const EditorCard({super.key, required this.title, this.hint, required this.child});

  @override
  Widget build(BuildContext context){
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadiusGeometry.circular(32),
          ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700
                  ),
              ),
              if(hint != null)...[
                const SizedBox(width: 12,),
                Expanded(
                  child: Text(
                    hint!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                        color: AppColors.gray,
                        fontSize: 15
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12,),
          Expanded(
              child: ClipRRect(
                borderRadius: BorderRadiusGeometry.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    RepaintBoundary(
                      child: CustomPaint(painter: DotGridPainter(),),
                    ),
                    child,
                  ],
                ),
              ),
          ),
        ],
      ),
    );
  }
}