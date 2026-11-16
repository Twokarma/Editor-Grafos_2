import 'package:flutter/widgets.dart';

class CanvasInsets extends InheritedWidget {
  final EdgeInsets insets;
  final Axis controlsAxis;

  const CanvasInsets({
    super.key,
    required this.insets,
    this.controlsAxis = Axis.horizontal,
    required super.child,
  });

  static CanvasInsets? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CanvasInsets>();

  @override
  bool updateShouldNotify(CanvasInsets oldWidget) =>
      insets != oldWidget.insets || controlsAxis != oldWidget.controlsAxis;
}
