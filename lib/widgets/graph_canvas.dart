import 'dart:async';
import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:graph_maker_app_2/models/app_viewport.dart';
import 'package:graph_maker_app_2/widgets/canvas/canvas_insets.dart';
import 'package:graph_maker_app_2/widgets/canvas/zoom_controls.dart';
import 'package:graph_maker_app_2/widgets/dialogs/edit_edge_dialog.dart';
import 'package:graph_maker_app_2/widgets/overlays/canvas_overlay.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:provider/provider.dart';

import '../providers/graph_provider.dart';
import 'dialogs/edge_dialog.dart';
import 'dialogs/edit_node_dialog.dart';
import 'dialogs/node_value_dialog.dart';
import 'graph_painter.dart';

enum _GestureMode { none, edgeDrag, nodeMove, pan, pinch }

class GraphWidget extends StatefulWidget{
  final CanvasOverlay canvasOverlay;

  /// Si es false, al conectar o editar aristas solo se ofrece "non-directed".
  /// Por defecto true, así las demás pantallas no cambian.
  final bool allowDirected;

  const GraphWidget({
    super.key,
    this.canvasOverlay = const DefaultOverlay(),
    this.allowDirected = true,
  });

  @override
  State<GraphWidget> createState() => _GraphWidgetState();
}

class _GraphWidgetState extends State<GraphWidget> with SingleTickerProviderStateMixin {
  static const Duration _holdDuration = Duration(milliseconds: 500);
  static const double _nodeHitPixels = 22;
  static const double _edgeHitPixels = 10;
  static const double _wheelZoomSpeed = 300;
  static const double _buttonZoomFactor = 1.25;
  static const double _controlsReserve = 56;

  final AppViewport _viewport = AppViewport();
  final FocusNode _focusNode = FocusNode(debugLabel: 'graphCanvas');
  late final AnimationController _viewAnimation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
  )..addListener(_onViewAnimation);
  Offset _animFromOffset = Offset.zero;
  Offset _animToOffset = Offset.zero;
  double _animFromScale = 1;
  double _animToScale = 1;

  Size _viewSize = Size.zero;
  EdgeInsets _insets = EdgeInsets.zero;
  Axis _controlsAxis = Axis.horizontal;
  int? _layoutVersion;

  String _sourceNode = "";
  Offset? _dragPosition;

  Timer? _holdTimer;
  bool _panMoved = false;
  bool _suppressNextTap = false;

  bool _isMovingNode = false;
  String _movingNodeId = "";
  Offset? _movingNodePosition;

  _GestureMode _mode = _GestureMode.none;
  int _activePointers = 0;
  bool _multiTouch = false;
  double _pinchStartScale = 1;
  Offset _pinchStartWorldFocal = Offset.zero;
  Offset _panAnchorWorld = Offset.zero;
  Offset? _downPosition;

  final Map<int, Offset> _touches = {};
  Offset _touchAnchorWorld = Offset.zero;
  double _touchAnchorSpan = 0;
  double _touchAnchorScale = 1;

  static Offset _centroid(Iterable<Offset> points) {
    Offset sum = Offset.zero;
    for (final Offset p in points) {
      sum += p;
    }
    return sum / points.length.toDouble();
  }

  static double _span(Iterable<Offset> points, Offset centre) {
    double total = 0;
    for (final Offset p in points) {
      total += (p - centre).distance;
    }
    return total / points.length;
  }

  void _reanchorTouches() {
    if (_touches.length < 2) return;
    final Offset centre = _centroid(_touches.values);
    _touchAnchorWorld = _toWorld(centre);
    _touchAnchorSpan = _span(_touches.values, centre);
    _touchAnchorScale = _viewport.scale;
  }
  bool _middlePanning = false;
  bool _spaceHeld = false;

  double get _nodeHit => _nodeHitPixels / _viewport.scale;
  double get _edgeHit => _edgeHitPixels / _viewport.scale;

  Rect get _availableRect => Rect.fromLTRB(
        _insets.left,
        _insets.top,
        max(_insets.left + 1, _viewSize.width - _insets.right),
        max(_insets.top + 1, _viewSize.height - _insets.bottom),
      );

  @override
  void dispose() {
    _cancelHold();
    _viewAnimation.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _cancelHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Offset _toWorld(Offset screen) => _viewport.toWorld(screen);

  String _nodeAt(GraphProvider provider, Offset world) =>
      provider.findNodeAt(world.dx, world.dy, minRadius: _nodeHit);

  String _edgeAt(GraphProvider provider, Offset world) =>
      provider.findEdgeAt(world.dx, world.dy, tolerance: _edgeHit);

  void _onViewAnimation() {
    final double t = Curves.easeInOutCubic.transform(_viewAnimation.value);
    setState(() {
      _viewport.set(
        Offset.lerp(_animFromOffset, _animToOffset, t)!,
        _animFromScale + (_animToScale - _animFromScale) * t,
      );
    });
  }

  void _stopViewAnimation() {
    if (_viewAnimation.isAnimating) _viewAnimation.stop();
  }

  void _animateTo(Offset offset, double scale) {
    _animFromOffset = _viewport.offset;
    _animFromScale = _viewport.scale;
    _animToOffset = offset;
    _animToScale = scale;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _viewport.set(offset, scale));
      return;
    }
    _viewAnimation.forward(from: 0);
  }

  void _animateZoom(double targetScale, {Offset? focal}) {
    final Offset focus = focal ?? _availableRect.center;
    final double scale = targetScale.clamp(AppViewport.minScale, AppViewport.maxScale);
    final Offset world = _toWorld(focus);
    _animateTo(focus - world * scale, scale);
  }

  void _zoomIn() => _animateZoom(_viewport.scale * _buttonZoomFactor);

  void _zoomOut() => _animateZoom(_viewport.scale / _buttonZoomFactor);

  void _resetZoom() => _animateZoom(1);

  void _fit() {
    final Rect? bounds = context.read<GraphProvider>().graphGetter().bounds;
    if (bounds == null || _viewSize.isEmpty) {
      _animateTo(Offset(_insets.left, _insets.top), 1);
      return;
    }
    final EdgeInsets controlsRoom = _controlsAxis == Axis.vertical
        ? const EdgeInsets.only(right: _controlsReserve)
        : const EdgeInsets.only(bottom: _controlsReserve);
    final target = AppViewport.fitted(bounds, _viewSize, insets: _insets + controlsRoom);
    _animateTo(target.offset, target.scale);
  }

  void _checkLayoutVersion(GraphProvider provider) {
    final int version = provider.layoutVersion;
    if (_layoutVersion == null) {
      _layoutVersion = version;
      return;
    }
    if (_layoutVersion == version) return;
    _layoutVersion = version;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fit();
    });
  }

  void _resetGestureState() {
    _cancelHold();
    _sourceNode = "";
    _dragPosition = null;
    _isMovingNode = false;
    _movingNodeId = "";
    _movingNodePosition = null;
    _mode = _GestureMode.none;
    _downPosition = null;
  }

  void _onPointerDown(PointerDownEvent event) {
    _stopViewAnimation();
    _activePointers++;

    if (event.kind == PointerDeviceKind.mouse && (event.buttons & kMiddleMouseButton) != 0) {
      setState(() => _middlePanning = true);
      return;
    }
    if (event.kind == PointerDeviceKind.mouse && (event.buttons & kPrimaryButton) == 0) return;

    _touches[event.pointer] = event.localPosition;
    _reanchorTouches();

    if (_activePointers > 1) {
      _multiTouch = true;
      _suppressNextTap = true;
      setState(_resetGestureState);
      return;
    }

    _multiTouch = false;
    _panMoved = false;
    _suppressNextTap = false;
    _downPosition = event.localPosition;
    _cancelHold();
    _focusNode.requestFocus();
    if (_spaceHeld) return;

    final provider = context.read<GraphProvider>();
    final String nodeId = _nodeAt(provider, _toWorld(event.localPosition));
    setState(() => _sourceNode = nodeId);
    if (nodeId == "") return;

    _holdTimer = Timer(_holdDuration, () {
      if (_panMoved || !mounted) return;
      final node = provider.graphGetter().nodes[nodeId];
      if (node == null) return;
      HapticFeedback.lightImpact();
      _suppressNextTap = true;
      setState(() {
        _isMovingNode = true;
        _movingNodeId = nodeId;
        _movingNodePosition = Offset(node.x, node.y);
        _sourceNode = "";
      });
    });
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (_touches.containsKey(event.pointer)) _touches[event.pointer] = event.localPosition;
    if (!_middlePanning) return;
    setState(() => _viewport.panBy(event.localDelta));
  }

  void _onPointerEnd(PointerEvent event) {
    _activePointers = max(0, _activePointers - 1);
    if (_touches.remove(event.pointer) != null) _reanchorTouches();
    if (_middlePanning) {
      setState(() => _middlePanning = false);
      return;
    }
    if (_activePointers == 0 && _mode == _GestureMode.none) {
      setState(_resetGestureState);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    GestureBinding.instance.pointerSignalResolver.register(event, (PointerSignalEvent event) {
      _stopViewAnimation();
      if (event is PointerScrollEvent) {
        final HardwareKeyboard keyboard = HardwareKeyboard.instance;
        setState(() {
          if (keyboard.isControlPressed || keyboard.isMetaPressed) {
            _viewport.zoomBy(event.localPosition, exp(-event.scrollDelta.dy / _wheelZoomSpeed));
          } else {
            _viewport.panBy(-event.scrollDelta);
          }
        });
      } else if (event is PointerScaleEvent) {
        setState(() => _viewport.zoomBy(event.localPosition, event.scale));
      }
    });
  }

  void _onScaleStart(ScaleStartDetails details) {
    _panMoved = true;
    _stopViewAnimation();
    _GestureMode mode;
    if (details.pointerCount >= 2) {
      mode = _GestureMode.pinch;
      _pinchStartScale = _viewport.scale;
      _pinchStartWorldFocal = _toWorld(details.localFocalPoint);
    } else if (_multiTouch) {
      mode = _GestureMode.pan;
    } else if (_middlePanning) {
      mode = _GestureMode.none;
    } else if (_spaceHeld) {
      mode = _GestureMode.pan;
    } else if (_isMovingNode) {
      mode = _GestureMode.nodeMove;
    } else if (_sourceNode != "") {
      mode = _GestureMode.edgeDrag;
    } else {
      mode = _GestureMode.pan;
    }
    if (mode == _GestureMode.pan) {
      final bool fromDown = details.pointerCount == 1 && !_multiTouch && _downPosition != null;
      _panAnchorWorld = _toWorld(fromDown ? _downPosition! : details.localFocalPoint);
    }
    setState(() => _mode = mode);
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      switch (_mode) {
        case _GestureMode.pan:
          _viewport.pin(_panAnchorWorld, details.localFocalPoint, _viewport.scale);
        case _GestureMode.pinch:
          if (_touches.length >= 2 && _touchAnchorSpan > 0) {
            final Offset centre = _centroid(_touches.values);
            final double span = _span(_touches.values, centre);
            _viewport.pin(_touchAnchorWorld, centre, _touchAnchorScale * span / _touchAnchorSpan);
          } else {
            _viewport.pin(_pinchStartWorldFocal, details.localFocalPoint, _pinchStartScale * details.scale);
          }
        case _GestureMode.edgeDrag:
          _dragPosition = _toWorld(details.localFocalPoint);
        case _GestureMode.nodeMove:
          _movingNodePosition = _toWorld(details.localFocalPoint);
        case _GestureMode.none:
          break;
      }
    });
  }

  void _onScaleEnd(ScaleEndDetails details) {
    if (_activePointers > 0) return;
    final provider = context.read<GraphProvider>();

    if (_mode == _GestureMode.nodeMove && !_multiTouch && _movingNodePosition != null) {
      final Offset target = _movingNodePosition!;
      final String? moved = provider.moveNode(_movingNodeId, target.dx, target.dy);
      if (moved != null) _snack(moved);
    } else if (_mode == _GestureMode.edgeDrag && !_multiTouch && _dragPosition != null) {
      _commitEdge(provider, _sourceNode, _nodeAt(provider, _dragPosition!));
    }

    setState(_resetGestureState);
  }

  void _commitEdge(GraphProvider provider, String source, String target) {
    if (target == "") return;
    final String? message = provider.checkEdgeEndpoints(source, target);
    if (message != null) {
      _snack(message);
    } else if (provider.rules.autoEdgeWeight != null) {
      final String? added = provider.addEdge(source, target, provider.rules.autoEdgeWeight!, true);
      if (added != null) _snack(added);
    } else {
      showEdgeDialog(
        context,
        provider,
        source: source,
        target: target,
        allowDirected: widget.allowDirected,
      );
    }
  }

  void _onDoubleTapDown(TapDownDetails details) {
    if (_spaceHeld || _multiTouch) return;
    final provider = context.read<GraphProvider>();
    final Offset world = _toWorld(details.localPosition);
    final String nodeId = _nodeAt(provider, world);
    if (nodeId != "") {
      final String? message = provider.removeNode(nodeId);
      if (message != null) _snack(message);
      return;
    }
    final String edgeId = _edgeAt(provider, world);
    if (edgeId != "") {
      final String? message = provider.removeEdge(edgeId);
      if (message != null) _snack(message);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_spaceHeld || _multiTouch || _suppressNextTap) {
      _suppressNextTap = false;
      return;
    }

    final provider = context.read<GraphProvider>();
    final Offset world = _toWorld(details.localPosition);
    String tap = _nodeAt(provider, world);

    if (tap.startsWith("n")) {
      showEditNodeDialog(context, provider, tap);
      return;
    }
    tap = _edgeAt(provider, world);
    if (tap.startsWith("e")) {
      if (provider.rules.autoEdgeWeight == null) {
        showEditEdgeDialog(context, provider, tap, allowDirected: widget.allowDirected);
      }
      return;
    }

    if (provider.rules.nodesAreValues) {
      final String? tooClose = provider.rules.checkAddNode(provider.graphGetter(), world.dx, world.dy);
      if (tooClose != null) {
        _snack(tooClose);
      } else {
        showNodeValueDialog(context, provider, world.dx, world.dy);
      }
      return;
    }
    final String? message = provider.addNode(world.dx, world.dy);
    if (message != null) _snack(message);
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      final bool held = event is! KeyUpEvent;
      if (held != _spaceHeld) setState(() => _spaceHeld = held);
      return KeyEventResult.handled;
    }
    if (event is KeyUpEvent) return KeyEventResult.ignored;

    final HardwareKeyboard keyboard = HardwareKeyboard.instance;
    final bool command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final provider = context.read<GraphProvider>();

    if (command && key == LogicalKeyboardKey.keyZ) {
      keyboard.isShiftPressed ? provider.redo() : provider.undo();
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyY) {
      provider.redo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.equal || key == LogicalKeyboardKey.add || key == LogicalKeyboardKey.numpadAdd) {
      _zoomIn();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.minus || key == LogicalKeyboardKey.numpadSubtract) {
      _zoomOut();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      _resetZoom();
      return KeyEventResult.handled;
    }
    if (!command && key == LogicalKeyboardKey.keyF) {
      _fit();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  MouseCursor get _cursor {
    if (_middlePanning || (_mode == _GestureMode.pan && _spaceHeld)) return SystemMouseCursors.grabbing;
    if (_spaceHeld) return SystemMouseCursors.grab;
    return MouseCursor.defer;
  }

  @override
  Widget build(BuildContext context) {
    final graphProvider = context.watch<GraphProvider>();
    _checkLayoutVersion(graphProvider);
    final CanvasInsets? canvasInsets = CanvasInsets.maybeOf(context);
    _insets = canvasInsets?.insets ?? EdgeInsets.zero;
    final Axis controlsAxis = canvasInsets?.controlsAxis ?? Axis.horizontal;
    _controlsAxis = controlsAxis;

    final Widget controls = ZoomControls(
      key: EditorTourScope.maybeOf(context)?.anchorFor(TourArea.zoom),
      scale: _viewport.scale,
      axis: controlsAxis,
      onZoomIn: _viewport.scale < AppViewport.maxScale - 0.001 ? _zoomIn : null,
      onZoomOut: _viewport.scale > AppViewport.minScale + 0.001 ? _zoomOut : null,
      onReset: _resetZoom,
      onFit: _fit,
    );

    return LayoutBuilder(builder: (context, constraints) {
      _viewSize = constraints.biggest;
      return Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (!focused && _spaceHeld) setState(() => _spaceHeld = false);
        },
        child: MouseRegion(
          cursor: _cursor,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onScaleStart: _onScaleStart,
                  onScaleUpdate: _onScaleUpdate,
                  onScaleEnd: _onScaleEnd,
                  onTapUp: _onTapUp,
                  onDoubleTapDown: _onDoubleTapDown,
                  child: Listener(
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerEnd,
                    onPointerCancel: _onPointerEnd,
                    onPointerSignal: _onPointerSignal,
                    child: SizedBox.expand(
                      child: CustomPaint(
                        painter: GraphPainter(
                          nodes: graphProvider.graphGetter().nodes,
                          edges: graphProvider.graphGetter().edges,
                          dragSourceId: _mode == _GestureMode.edgeDrag ? _sourceNode : "",
                          dragCurrentPosition: _dragPosition,
                          movingNodeId: _isMovingNode ? _movingNodeId : null,
                          movingNodePosition: _isMovingNode ? _movingNodePosition : null,
                          canvasOverlay: widget.canvasOverlay,
                          viewport: _viewport,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (controlsAxis == Axis.vertical)
                Positioned(
                  right: 12 + _insets.right,
                  top: _insets.top,
                  bottom: _insets.bottom,
                  child: Center(child: controls),
                )
              else
                Positioned(
                  right: 12 + _insets.right,
                  bottom: 12 + _insets.bottom,
                  child: controls,
                ),
            ],
          ),
        ),
      );
    });
  }
}
