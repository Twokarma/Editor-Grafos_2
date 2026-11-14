import 'dart:math';
import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;

class AppViewport {
  Offset offset = Offset.zero;
  double scale = 1.0;
  static const double minScale = 0.3;
  static const double maxScale = 3.0;
  static const double maxFitScale = 1.5;

  Offset toWorld(Offset screenPoint){
    return (screenPoint - offset) / scale;
  }

  Offset toScreen(Offset worldPoint){
    return worldPoint * scale + offset;
  }

  Rect visibleWorldRect(Size viewSize){
    return Rect.fromPoints(toWorld(Offset.zero), toWorld(Offset(viewSize.width, viewSize.height)));
  }

  void panBy(Offset screenDelta){
    offset += screenDelta;
  }

  void zoomAt(Offset focalScreen, double newScale){
    newScale = newScale.clamp(minScale, maxScale);
    Offset w = toWorld(focalScreen);
    scale = newScale;
    offset = focalScreen - w * scale;
  }

  void zoomBy(Offset focalScreen, double factor){
    zoomAt(focalScreen, factor * scale);
  }

  void pin(Offset worldPoint, Offset focalScreen, double newScale){
    scale = newScale.clamp(minScale, maxScale);
    offset = focalScreen - worldPoint * scale;
  }

  void reset(){
    offset = Offset.zero;
    scale = 1.0;
  }

  void set(Offset newOffset, double newScale){
    offset = newOffset;
    scale = newScale;
  }

  static ({Offset offset, double scale}) fitted(Rect worldRect, Size viewSize, {EdgeInsets insets = EdgeInsets.zero, double padding = 32}){
    final Rect available = Rect.fromLTRB(
      insets.left + padding,
      insets.top + padding,
      max(insets.left + padding + 1, viewSize.width - insets.right - padding),
      max(insets.top + padding + 1, viewSize.height - insets.bottom - padding),
    );
    final double width = max(worldRect.width, 1);
    final double height = max(worldRect.height, 1);
    final double scale = min(available.width / width, available.height / height).clamp(minScale, maxFitScale);
    return (offset: available.center - worldRect.center * scale, scale: scale);
  }

  void fitToRect(Rect worldRect, Size viewSize, {EdgeInsets insets = EdgeInsets.zero, double padding = 32}){
    final target = fitted(worldRect, viewSize, insets: insets, padding: padding);
    offset = target.offset;
    scale = target.scale;
  }
}
