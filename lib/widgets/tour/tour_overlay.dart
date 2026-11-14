import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class AppTour {
  AppTour._();

  static bool _active = false;

  static bool get isActive => _active;

  @visibleForTesting
  static void resetForTest() => _active = false;

  static void start(BuildContext context, {required TourHost host, required List<TourStep> steps, VoidCallback? onFinish}) {
    if (_active || steps.isEmpty) return;
    _active = true;
    final OverlayState overlay = Overlay.of(context, rootOverlay: true);
    final FocusNode? previousFocus = FocusManager.instance.primaryFocus;
    host.saveState();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TourOverlay(
        host: host,
        steps: steps,
        onClose: () {
          entry.remove();
          _active = false;
          if (host.mounted) host.restoreState();
          if (previousFocus != null && previousFocus.context != null) previousFocus.requestFocus();
          onFinish?.call();
        },
      ),
    );
    overlay.insert(entry);
  }
}

class _Resolved {
  final int index;
  final int next;
  final GlobalKey key;
  final List<TourStep> merged;

  const _Resolved({required this.index, required this.next, required this.key, required this.merged});
}

class _TourOverlay extends StatefulWidget {
  final TourHost host;
  final List<TourStep> steps;
  final VoidCallback onClose;

  const _TourOverlay({required this.host, required this.steps, required this.onClose});

  @override
  State<_TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<_TourOverlay> with TickerProviderStateMixin {
  static const Duration _moveDuration = Duration(milliseconds: 320);

  final FocusNode _focus = FocusNode(debugLabel: 'tour');
  late final AnimationController _move = AnimationController(vsync: this, duration: _moveDuration);
  late final AnimationController _gesture = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
  late final Ticker _tracker = createTicker((_) => _track());
  late final Listenable _animations = Listenable.merge([_move, _gesture]);

  _Resolved? _current;
  Rect? _liveRect;
  Rect? _fromRect;
  bool _busy = false;
  bool _closed = false;
  bool _waitDone = false;
  TourWait? _attachedWait;

  TourStep? get _step => _current == null ? null : widget.steps[_current!.index];

  @override
  void initState() {
    super.initState();
    _tracker.start();
    WidgetsBinding.instance.addPostFrameCallback((_) => _go(0));
  }

  @override
  void dispose() {
    _detachWait();
    _tracker.dispose();
    _move.dispose();
    _gesture.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _reduceMotion => MediaQuery.disableAnimationsOf(context);

  Rect? _rectOf(GlobalKey key) {
    final RenderObject? target = key.currentContext?.findRenderObject();
    final RenderObject? self = context.findRenderObject();
    if (target is! RenderBox || self is! RenderBox || !target.attached || !target.hasSize) return null;
    return MatrixUtils.transformRect(target.getTransformTo(self), Offset.zero & target.size);
  }

  void _track() {
    if (!mounted) return;
    if (!widget.host.mounted) {
      _finish();
      return;
    }
    final _Resolved? current = _current;
    if (current == null) return;
    final Rect? rect = _rectOf(current.key);
    if (rect != null && rect != _liveRect) setState(() => _liveRect = rect);
  }

  Rect? get _shownRect {
    final Rect? live = _liveRect;
    if (live == null) return null;
    final Rect? from = _fromRect;
    if (from == null || !_move.isAnimating) return live;
    return Rect.lerp(from, live, Curves.easeInOutCubic.transform(_move.value));
  }

  bool _missing(TourStep step) => step.key == null || step.key!.currentContext == null;

  Future<void> _go(int target, {bool backward = false}) async {
    if (_busy || _closed) return;
    _busy = true;
    _detachWait();
    int i = target;
    _Resolved? resolved;
    while (i >= 0 && i < widget.steps.length) {
      final TourStep step = widget.steps[i];
      await widget.host.reveal(step.area);
      if (!mounted || _closed) return;
      await _nextFrame();
      if (!mounted || _closed) return;

      if (!_missing(step)) {
        resolved = _Resolved(index: i, next: i + 1, key: step.key!, merged: const []);
        break;
      }
      final GlobalKey anchor = widget.host.anchorFor(step.area);
      if (anchor.currentContext == null) {
        i += backward ? -1 : 1;
        continue;
      }
      if (step.key == null) {
        resolved = _Resolved(index: i, next: i + 1, key: anchor, merged: const []);
        break;
      }
      int start = i;
      while (start > 0) {
        final TourStep before = widget.steps[start - 1];
        if (before.area != step.area || before.key == null || !_missing(before)) break;
        start--;
      }
      int end = i;
      while (end + 1 < widget.steps.length) {
        final TourStep after = widget.steps[end + 1];
        if (after.area != step.area || after.key == null || !_missing(after)) break;
        end++;
      }
      resolved = _Resolved(index: start, next: end + 1, key: anchor, merged: [for (int j = start; j <= end; j++) widget.steps[j]]);
      break;
    }

    if (resolved == null) {
      _busy = false;
      if (!backward) _finish();
      return;
    }

    await _ensureVisible(resolved.key);
    if (!mounted || _closed) return;
    final Rect? rect = _rectOf(resolved.key);
    setState(() {
      _fromRect = _shownRect;
      _current = resolved;
      _liveRect = rect;
      _waitDone = false;
    });
    if (_reduceMotion || _fromRect == null) {
      _move.value = 1;
    } else {
      _move.forward(from: 0);
    }
    final TourStep step = widget.steps[resolved.index];
    if (step.gesture != null && !_reduceMotion) {
      _gesture.repeat();
    } else {
      _gesture.stop();
      _gesture.value = 0.6;
    }
    _attachWait(step.wait);
    _focus.requestFocus();
    _busy = false;
  }

  Future<void> _nextFrame() {
    final Completer<void> done = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) => done.complete());
    SchedulerBinding.instance.ensureVisualUpdate();
    return done.future;
  }

  Future<void> _ensureVisible(GlobalKey key) async {
    final BuildContext? target = key.currentContext;
    if (target == null || Scrollable.maybeOf(target) == null) return;
    await Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
    );
  }

  void _attachWait(TourWait? wait) {
    if (wait == null) return;
    _attachedWait = wait;
    wait.listenable.addListener(_onWaitChanged);
  }

  void _detachWait() {
    _attachedWait?.listenable.removeListener(_onWaitChanged);
    _attachedWait = null;
  }

  void _onWaitChanged() {
    final TourWait? wait = _attachedWait;
    if (wait == null || _waitDone || !wait.isDone()) return;
    _detachWait();
    setState(() => _waitDone = true);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted && !_closed && _waitDone) _next();
    });
  }

  void _next() {
    final _Resolved? current = _current;
    if (current == null) return;
    _go(current.next);
  }

  void _previous() {
    final _Resolved? current = _current;
    if (current == null || current.index == 0) return;
    _go(current.index - 1, backward: true);
  }

  int? get _nextChapterIndex {
    final _Resolved? current = _current;
    if (current == null) return null;
    final String chapter = widget.steps[current.index].chapter;
    for (int i = current.next; i < widget.steps.length; i++) {
      if (widget.steps[i].chapter != chapter) return i;
    }
    return null;
  }

  void _skipChapter() {
    final int? target = _nextChapterIndex;
    if (target != null) _go(target);
  }

  void _finish() {
    if (_closed) return;
    _closed = true;
    _detachWait();
    widget.onClose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.handled;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      _finish();
    } else if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.enter) {
      _next();
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      _previous();
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final TourStep? step = _step;
    final _Resolved? current = _current;
    final Size size = MediaQuery.sizeOf(context);
    final bool touch = widget.host.isTouchLayout;
    final bool waiting = step?.wait != null && !_waitDone;

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: Material(
        type: MaterialType.transparency,
        child: BlockSemantics(
          child: AnimatedBuilder(
            animation: _animations,
            builder: (context, _) {
              final Rect? hole = _shownRect?.inflate(6).intersect(Offset.zero & size);
              return Stack(
                children: [
                  Positioned.fill(
                    child: _TourBarrier(
                      hole: hole,
                      passThrough: waiting,
                      child: CustomPaint(painter: _ScrimPainter(hole: hole)),
                    ),
                  ),
                  if (hole != null && step?.gesture != null)
                    Positioned.fromRect(
                      rect: hole,
                      child: IgnorePointer(
                        child: CustomPaint(
                          painter: _GesturePainter(gesture: step!.gesture!, t: _gesture.value),
                        ),
                      ),
                    ),
                  if (step != null && current != null)
                    CustomSingleChildLayout(
                      delegate: _BubblePlacement(hole: hole),
                      child: _Bubble(
                        step: step,
                        merged: current.merged,
                        touch: touch,
                        index: current.index,
                        total: widget.steps.length,
                        isLast: current.next >= widget.steps.length,
                        waiting: waiting,
                        waitDone: _waitDone,
                        onPrevious: current.index > 0 ? _previous : null,
                        onNext: _next,
                        onSkip: _finish,
                        onSkipChapter: _nextChapterIndex == null ? null : _skipChapter,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TourBarrier extends SingleChildRenderObjectWidget {
  final Rect? hole;
  final bool passThrough;

  const _TourBarrier({required this.hole, required this.passThrough, super.child});

  @override
  _RenderTourBarrier createRenderObject(BuildContext context) => _RenderTourBarrier(hole, passThrough);

  @override
  void updateRenderObject(BuildContext context, _RenderTourBarrier renderObject) {
    renderObject
      ..hole = hole
      ..passThrough = passThrough;
  }
}

class _RenderTourBarrier extends RenderProxyBox {
  Rect? hole;
  bool passThrough;

  _RenderTourBarrier(this.hole, this.passThrough);

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    final Rect? currentHole = hole;
    if (passThrough && currentHole != null && currentHole.contains(position)) return false;
    result.add(BoxHitTestEntry(this, position));
    return true;
  }
}

class _ScrimPainter extends CustomPainter {
  final Rect? hole;

  const _ScrimPainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    final Path scrim = Path()..addRect(Offset.zero & size);
    final Rect? currentHole = hole;
    if (currentHole != null) {
      scrim
        ..addRRect(RRect.fromRectAndRadius(currentHole, const Radius.circular(18)))
        ..fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(scrim, Paint()..color = AppColors.darkBlue.withValues(alpha: 0.72));
    if (currentHole != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(currentHole, const Radius.circular(18)),
        Paint()
          ..color = AppColors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScrimPainter oldDelegate) => oldDelegate.hole != hole;
}

class _GesturePainter extends CustomPainter {
  final TourGesture gesture;
  final double t;

  const _GesturePainter({required this.gesture, required this.t});

  static final Paint _finger = Paint()..color = AppColors.white.withValues(alpha: 0.95);
  static final Paint _fingerRing = Paint()
    ..color = AppColors.blue
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3;

  void _dot(Canvas canvas, Offset at, [double radius = 14]) {
    canvas.drawCircle(at, radius, _finger);
    canvas.drawCircle(at, radius, _fingerRing);
  }

  void _ripple(Canvas canvas, Offset at, double progress) {
    if (progress <= 0 || progress >= 1) return;
    canvas.drawCircle(
      at,
      14 + 28 * progress,
      Paint()
        ..color = AppColors.white.withValues(alpha: 1 - progress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _node(Canvas canvas, Offset at) {
    canvas.drawCircle(at, 20, Paint()..color = AppColors.blue.withValues(alpha: 0.85));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = size.center(Offset.zero);
    final double reach = math.min(size.width * 0.22, 140);
    final double eased = Curves.easeInOut.transform((t / 0.8).clamp(0.0, 1.0));
    switch (gesture) {
      case TourGesture.tap:
        _ripple(canvas, c, t / 0.7);
        _dot(canvas, c);
      case TourGesture.doubleTap:
        _node(canvas, c);
        _ripple(canvas, c, t / 0.35);
        _ripple(canvas, c, (t - 0.4) / 0.35);
        _dot(canvas, c);
      case TourGesture.hold:
        _node(canvas, c);
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: 26),
          -math.pi / 2,
          2 * math.pi * (t / 0.7).clamp(0.0, 1.0),
          false,
          Paint()
            ..color = AppColors.white
            ..style = PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
        _dot(canvas, c + Offset(t > 0.75 ? (t - 0.75) * 4 * reach * 0.5 : 0, 0));
      case TourGesture.drag:
        final Offset a = c - Offset(reach, 0);
        final Offset b = c + Offset(reach, 0);
        final Offset p = Offset.lerp(a, b, eased)!;
        _node(canvas, a);
        _node(canvas, b);
        canvas.drawLine(
          a,
          p,
          Paint()
            ..color = AppColors.previewEdge
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
        _dot(canvas, p);
      case TourGesture.pan:
        final Offset a = c - Offset(reach * 0.6, 0);
        final Offset b = c + Offset(reach * 0.6, 0);
        _dot(canvas, Offset.lerp(a, b, Curves.easeInOut.transform(t < 0.5 ? t * 2 : 2 - t * 2))!);
      case TourGesture.pinch:
        final double spread = 18 + (reach - 18) * eased;
        _dot(canvas, c - Offset(spread, 0), 12);
        _dot(canvas, c + Offset(spread, 0), 12);
    }
  }

  @override
  bool shouldRepaint(covariant _GesturePainter oldDelegate) => oldDelegate.t != t || oldDelegate.gesture != gesture;
}

class _BubblePlacement extends SingleChildLayoutDelegate {
  final Rect? hole;

  const _BubblePlacement({required this.hole});

  static const double _margin = 16;
  static const double _gap = 14;
  static const double _maxWidth = 340;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return BoxConstraints(
      maxWidth: math.min(_maxWidth, constraints.maxWidth - 2 * _margin),
      maxHeight: constraints.maxHeight - 2 * _margin,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size child) {
    double clampX(double x) => x.clamp(_margin, math.max(_margin, size.width - child.width - _margin));
    double clampY(double y) => y.clamp(_margin, math.max(_margin, size.height - child.height - _margin));
    final Rect? target = hole;
    if (target == null) {
      return Offset(clampX((size.width - child.width) / 2), clampY((size.height - child.height) / 2));
    }
    final double below = size.height - target.bottom - _gap - _margin;
    final double above = target.top - _gap - _margin;
    final double right = size.width - target.right - _gap - _margin;
    final double left = target.left - _gap - _margin;
    final List<(double, Offset)> options = [
      if (below >= child.height) (below, Offset(clampX(target.center.dx - child.width / 2), target.bottom + _gap)),
      if (above >= child.height) (above, Offset(clampX(target.center.dx - child.width / 2), target.top - _gap - child.height)),
      if (right >= child.width) (right, Offset(target.right + _gap, clampY(target.center.dy - child.height / 2))),
      if (left >= child.width) (left, Offset(target.left - _gap - child.width, clampY(target.center.dy - child.height / 2))),
    ];
    if (options.isEmpty) {
      return Offset(clampX(target.center.dx - child.width / 2), clampY(target.bottom - child.height - _margin));
    }
    options.sort((a, b) => b.$1.compareTo(a.$1));
    return options.first.$2;
  }

  @override
  bool shouldRelayout(covariant _BubblePlacement oldDelegate) => oldDelegate.hole != hole;
}

class _Bubble extends StatelessWidget {
  final TourStep step;
  final List<TourStep> merged;
  final bool touch;
  final int index;
  final int total;
  final bool isLast;
  final bool waiting;
  final bool waitDone;
  final VoidCallback? onPrevious;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final VoidCallback? onSkipChapter;

  const _Bubble({
    required this.step,
    required this.merged,
    required this.touch,
    required this.index,
    required this.total,
    required this.isLast,
    required this.waiting,
    required this.waitDone,
    required this.onPrevious,
    required this.onNext,
    required this.onSkip,
    required this.onSkipChapter,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMerged = merged.isNotEmpty;
    final String title = isMerged ? 'Más opciones' : step.title;
    return Semantics(
      container: true,
      liveRegion: true,
      label: title,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
        decoration: ShapeDecoration(
          color: AppColors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          shadows: [BoxShadow(color: AppColors.black.withValues(alpha: 0.25), blurRadius: 30, offset: const Offset(0, 12))],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      step.chapter.toUpperCase(),
                      style: const TextStyle(color: AppColors.blue, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.2),
                    ),
                  ),
                  TextButton(
                    onPressed: onSkip,
                    style: TextButton.styleFrom(foregroundColor: AppColors.gray, visualDensity: VisualDensity.compact),
                    child: const Text('Saltar recorrido'),
                  ),
                ],
              ),
              Text(
                title,
                style: const TextStyle(color: AppColors.darkBlue, fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              if (isMerged) ...[
                Text(
                  touch ? 'Están en el menú ⋯ de la barra superior:' : 'Están en el panel Opciones:',
                  style: const TextStyle(color: AppColors.darkBlue, fontSize: 15, height: 1.35),
                ),
                const SizedBox(height: 6),
                for (final TourStep item in merged)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '• ${item.title}: ',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          TextSpan(text: item.textFor(touch)),
                        ],
                      ),
                      style: const TextStyle(color: AppColors.darkBlue, fontSize: 14, height: 1.35),
                    ),
                  ),
              ] else
                Text(step.textFor(touch), style: const TextStyle(color: AppColors.darkBlue, fontSize: 15, height: 1.4)),
              if (step.wait != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: ShapeDecoration(
                    color: (waitDone ? AppColors.sortSorted : AppColors.lightBlue).withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Icon(waitDone ? Icons.check_circle : Icons.touch_app_outlined, color: AppColors.darkBlue, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          waitDone ? '¡Bien hecho!' : '${step.wait!.prompt} (o pulsa Siguiente)',
                          style: const TextStyle(color: AppColors.darkBlue, fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _Progress(index: index, total: total),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (onPrevious != null) ...[
                    Expanded(
                      child: PillButton(label: 'Anterior', style: AppButtonStyle.outline, onTap: onPrevious, fullWidth: true),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: PillButton(
                      label: isLast ? 'Terminar' : 'Siguiente',
                      icon: isLast ? Icons.check : Icons.arrow_forward,
                      style: AppButtonStyle.accent,
                      onTap: onNext,
                      fullWidth: true,
                    ),
                  ),
                ],
              ),
              if (onSkipChapter != null)
                Align(
                  alignment: Alignment.center,
                  child: TextButton(
                    onPressed: onSkipChapter,
                    style: TextButton.styleFrom(foregroundColor: AppColors.blue),
                    child: Text('Saltar «${step.chapter}»'),
                  ),
                ),
              if (!touch)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    '← → para moverte · Esc para salir',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.gray, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  final int index;
  final int total;

  const _Progress({required this.index, required this.total});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Paso ${index + 1} de $total',
      child: ExcludeSemantics(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: 5,
          children: [
            for (int i = 0; i < total; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == index ? 18 : 7,
                height: 7,
                decoration: ShapeDecoration(color: i <= index ? AppColors.blue : AppColors.marfil, shape: const StadiumBorder()),
              ),
          ],
        ),
      ),
    );
  }
}
