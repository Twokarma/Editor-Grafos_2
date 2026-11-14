import 'package:flutter/widgets.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum TourArea { navigation, canvas, zoom, functions, options }

enum TourGesture { tap, drag, hold, doubleTap, pan, pinch }

enum TourCanvas { graph, tree, sort }

class TourWait {
  final Listenable listenable;
  final bool Function() isDone;
  final String prompt;

  const TourWait({required this.listenable, required this.isDone, required this.prompt});
}

class TourStep {
  final GlobalKey? key;
  final TourArea area;
  final String chapter;
  final String title;
  final String text;
  final String? desktopText;
  final TourGesture? gesture;
  final TourWait? wait;

  const TourStep({
    this.key,
    required this.area,
    required this.chapter,
    required this.title,
    required this.text,
    this.desktopText,
    this.gesture,
    this.wait,
  });

  String textFor(bool touch) => touch ? text : (desktopText ?? text);
}

class EditorTour {
  final TourCanvas canvas;
  final String subject;
  final List<TourStep> Function() functionSteps;
  final String functionsIntro;
  final TourWait? Function()? canvasWait;
  final VoidCallback? onStart;

  const EditorTour({
    required this.canvas,
    required this.subject,
    required this.functionSteps,
    required this.functionsIntro,
    this.canvasWait,
    this.onStart,
  });
}

abstract class TourHost {
  bool get mounted;
  bool get isTouchLayout;
  GlobalKey anchorFor(TourArea area);
  Map<OptionKind, GlobalKey> get optionKeys;
  Future<void> reveal(TourArea area);
  void saveState();
  void restoreState();
}

class EditorTourScope extends InheritedWidget {
  final TourHost host;

  const EditorTourScope({super.key, required this.host, required super.child});

  static TourHost? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EditorTourScope>()?.host;

  @override
  bool updateShouldNotify(EditorTourScope oldWidget) => host != oldWidget.host;
}

class TourMemory {
  TourMemory._();

  static const String _prefix = 'tour_seen_';
  static final Map<String, bool> _cache = {};

  static Future<bool> isSeen(String id) async {
    final bool? cached = _cache[id];
    if (cached != null) return cached;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      return _cache[id] = prefs.getBool('$_prefix$id') ?? false;
    } catch (_) {
      return _cache[id] = true;
    }
  }

  static Future<void> markSeen(String id) async {
    _cache[id] = true;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_prefix$id', true);
    } catch (_) {}
  }

  @visibleForTesting
  static void resetForTest([Map<String, bool> values = const {}]) {
    _cache
      ..clear()
      ..addAll(values);
  }
}
