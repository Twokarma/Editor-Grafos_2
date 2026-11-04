import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class DotGridPainter extends CustomPainter{
    final double spacing;
    final double radius;
    final Color color;

    const DotGridPainter({this.spacing = 24, this.radius = 1.2, this.color = AppColors.gridColor});

    @override
    void paint(Canvas canvas, Size size){
      final Paint gridPaint = Paint()
          ..color = color;

      for(double y = spacing/2; y < size.height; y += spacing){
        for(double x = spacing/2; x < size.width; x += spacing){
          canvas.drawCircle(Offset(x, y), radius, gridPaint);
        }
      }
    }

    @override
    bool shouldRepaint(covariant DotGridPainter oldDelegate){
      return (spacing != oldDelegate.spacing || radius != oldDelegate.radius || color != oldDelegate.color);
    }
}