import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/layout/editor_shell.dart';
import 'package:graph_maker_app_2/layout/options_config.dart';
import 'package:graph_maker_app_2/providers/graph_provider.dart';
import 'package:graph_maker_app_2/tours/editor_tour_steps.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_invite.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_models.dart';
import 'package:graph_maker_app_2/widgets/tour/tour_overlay.dart';
import 'package:provider/provider.dart';

mixin EditorTourHost<T extends StatefulWidget> on State<T> implements TourHost {
  EditorShell get shell;

  final Map<TourArea, GlobalKey> _anchors = {
    for (final TourArea area in TourArea.values) area: GlobalKey(debugLabel: 'tour-${area.name}'),
  };

  @override
  final Map<OptionKind, GlobalKey> optionKeys = {
    for (final OptionKind kind in OptionKind.values) kind: GlobalKey(debugLabel: 'option-${kind.name}'),
  };

  bool _showInvite = false;

  String get _tourId => shell.mode.name;

  @override
  GlobalKey anchorFor(TourArea area) => _anchors[area]!;

  @override
  void initState() {
    super.initState();
    if (shell.tour == null) return;
    TourMemory.isSeen(_tourId).then((seen) {
      if (!seen && mounted) setState(() => _showInvite = true);
    });
  }

  OptionsConfig get tourOptions => shell.tour == null ? shell.options : shell.options.withHelp(startTour);

  TourWait? _defaultCanvasWait() {
    final GraphProvider? provider = Provider.of<GraphProvider?>(context, listen: false);
    if (provider == null || provider.rules.nodesAreValues) return null;
    final int start = provider.graphGetter().nodes.length;
    return TourWait(
      listenable: provider,
      isDone: () => provider.graphGetter().nodes.length > start,
      prompt: 'Ahora tú: crea un nodo en el lienzo',
    );
  }

  void startTour() {
    final EditorTour? tour = shell.tour;
    if (tour == null || AppTour.isActive) return;
    _dismissInvite();
    tour.onStart?.call();
    final TourWait? canvasWait = tour.canvasWait != null
        ? tour.canvasWait!()
        : (tour.canvas == TourCanvas.graph ? _defaultCanvasWait() : null);
    AppTour.start(
      context,
      host: this,
      steps: buildEditorTourSteps(
        tour: tour,
        host: this,
        mode: shell.mode,
        options: tourOptions,
        canvasWait: canvasWait,
      ),
    );
  }

  void _dismissInvite() {
    TourMemory.markSeen(_tourId);
    if (_showInvite) setState(() => _showInvite = false);
  }

  Widget withTourInvite(Widget child, {double top = 12}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (_showInvite)
          Positioned(
            top: top,
            left: 12,
            right: 12,
            child: Center(
              child: TourInvite(
                modeLabel: shell.mode.label,
                onStart: startTour,
                onDismiss: _dismissInvite,
              ),
            ),
          ),
      ],
    );
  }

  Widget tourScope(Widget child) => EditorTourScope(host: this, child: child);

  Future<void> settle(bool changed, Duration duration) async {
    if (!changed) return;
    await Future<void>.delayed(MediaQuery.disableAnimationsOf(context) ? const Duration(milliseconds: 16) : duration);
  }
}
