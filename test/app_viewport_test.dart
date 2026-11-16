import 'dart:ui';

import 'package:flutter/painting.dart' show EdgeInsets;
import 'package:flutter_test/flutter_test.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';
import 'package:graph_maker_app_2/models/graph.dart';

void main() {
  group('conversions', () {
    test('identity at start', () {
      final v = AppViewport();
      expect(v.toWorld(const Offset(120, 80)), const Offset(120, 80));
    });

    test('screen and world round-trip with offset and scale', () {
      final v = AppViewport()..set(const Offset(100, 50), 2);
      expect(v.toScreen(const Offset(200, 150)), const Offset(500, 350));
      expect(v.toWorld(const Offset(500, 350)), const Offset(200, 150));
    });

    test('visible world rect follows the view', () {
      final v = AppViewport()..set(const Offset(-100, -50), 2);
      expect(v.visibleWorldRect(const Size(400, 300)), const Rect.fromLTRB(50, 25, 250, 175));
    });
  });

  group('zoom', () {
    test('zoomAt keeps the focal point fixed', () {
      final v = AppViewport();
      const focal = Offset(300, 300);
      final before = v.toWorld(focal);
      v.zoomAt(focal, 2);
      expect(v.offset, const Offset(-300, -300));
      expect(v.toWorld(focal), before);
    });

    test('zoom is clamped to the allowed range', () {
      final v = AppViewport();
      v.zoomAt(Offset.zero, 100);
      expect(v.scale, AppViewport.maxScale);
      v.zoomAt(Offset.zero, 0.01);
      expect(v.scale, AppViewport.minScale);
    });

    test('pin keeps a world point under the fingers', () {
      final v = AppViewport();
      const world = Offset(40, 60);
      v.pin(world, const Offset(200, 100), 1.5);
      expect(v.toScreen(world), const Offset(200, 100));
    });

    test('panBy moves 1:1 with the finger at any zoom', () {
      final v = AppViewport()..set(Offset.zero, 2.5);
      v.panBy(const Offset(30, -10));
      expect(v.offset, const Offset(30, -10));
    });
  });

  group('fit', () {
    test('centres the rect inside the free area', () {
      final target = AppViewport.fitted(
        const Rect.fromLTWH(0, 0, 200, 100),
        const Size(500, 500),
        insets: const EdgeInsets.only(top: 100),
        padding: 0,
      );
      final v = AppViewport()..set(target.offset, target.scale);
      expect(target.scale, AppViewport.maxFitScale);
      expect(v.toScreen(const Offset(100, 50)), const Offset(250, 300));
    });

    test('a single node does not zoom in past the fit cap', () {
      final target = AppViewport.fitted(const Rect.fromLTWH(0, 0, 1, 1), const Size(800, 600));
      expect(target.scale, AppViewport.maxFitScale);
    });

    test('a huge graph stops at the minimum zoom', () {
      final target = AppViewport.fitted(const Rect.fromLTWH(0, 0, 100000, 100000), const Size(800, 600));
      expect(target.scale, AppViewport.minScale);
    });
  });

  group('graph hit tests', () {
    test('a minimum hit radius makes small nodes easier to tap', () {
      final g = Graph()..addNode(100, 100);
      expect(g.findNodeAt(140, 100), '');
      expect(g.findNodeAt(140, 100, minRadius: 45), 'n0');
    });

    test('the closest node wins when hit areas overlap', () {
      final g = Graph()
        ..addNode(100, 100)
        ..addNode(170, 100);
      expect(g.findNodeAt(150, 100, minRadius: 60), 'n1');
    });

    test('edge tolerance can grow when zoomed out', () {
      final g = Graph()
        ..addNode(0, 0)
        ..addNode(200, 0)
        ..addEdge('n0', 'n1', 1);
      expect(g.findEdgeAt(100, 25), '');
      expect(g.findEdgeAt(100, 25, tolerance: 30), 'e0');
    });

    test('bounds cover every node plus a margin and are null when empty', () {
      final g = Graph();
      expect(g.bounds, isNull);
      g
        ..addNode(0, 0)
        ..addNode(300, 100);
      expect(g.bounds, const Rect.fromLTRB(-50, -50, 350, 150));
    });

    test('bounds include a self-loop on the right', () {
      final g = Graph()
        ..addNode(0, 0)
        ..addEdge('n0', 'n0', 1);
      expect(g.bounds!.right, greaterThan(30 + 20));
    });
  });
}
