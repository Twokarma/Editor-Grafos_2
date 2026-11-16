import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/algorithms/sorts.dart';
import 'package:graph_maker_app_2/models/velocidad.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class SortTourKeys {
  final GlobalKey count = GlobalKey();
  final GlobalKey speed = GlobalKey();
  final GlobalKey shuffle = GlobalKey();
  final GlobalKey solve = GlobalKey();
  final GlobalKey random = GlobalKey();
  final GlobalKey enter = GlobalKey();
  final GlobalKey legend = GlobalKey();
}

const TextStyle _labelStyle = TextStyle(fontSize: 14, color: AppColors.gray);
const TextStyle _valueStyle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkBlue);

String speedShortLabel(Velocidad speed) => switch (speed) {
      Velocidad.lenta => '×0.5',
      Velocidad.normal => '×1',
      Velocidad.rapida => '×2',
      Velocidad.muyRapida => '×5',
    };

class SortTimer extends StatelessWidget {
  final String time;
  final double fontSize;

  const SortTimer({super.key, required this.time, this.fontSize = 34});

  @override
  Widget build(BuildContext context) {
    return Text(
      time,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: AppColors.darkBlue,
        letterSpacing: 0.5,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class SortFunctions extends StatelessWidget {
  final SortKind kind;
  final bool showTimer;
  final String time;
  final bool running;
  final int count;
  final int maxCount;
  final ValueChanged<int> onCountChanged;
  final Velocidad speed;
  final ValueChanged<Velocidad> onSpeedChanged;
  final VoidCallback onShuffle;
  final VoidCallback onSolve;
  final VoidCallback onStop;
  final VoidCallback onRandom;
  final VoidCallback onEnter;
  final SortTourKeys? keys;

  const SortFunctions({
    super.key,
    required this.kind,
    required this.showTimer,
    required this.time,
    required this.running,
    required this.count,
    required this.maxCount,
    required this.onCountChanged,
    required this.speed,
    required this.onSpeedChanged,
    required this.onShuffle,
    required this.onSolve,
    required this.onStop,
    required this.onRandom,
    required this.onEnter,
    this.keys,
  });

  Widget _countSlider() {
    return Column(
      key: keys?.count,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Cantidad de bolos: ', style: _labelStyle),
          TextSpan(text: '$count', style: _valueStyle),
        ])),
        Slider(
          min: 1,
          max: maxCount.toDouble(),
          divisions: maxCount - 1,
          value: count.clamp(1, maxCount).toDouble(),
          label: '$count',
          activeColor: AppColors.blue,
          onChanged: running ? null : (v) => onCountChanged(v.round()),
        ),
      ],
    );
  }

  Widget _speedSelector() {
    return Column(
      key: keys?.speed,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(TextSpan(children: [
          const TextSpan(text: 'Velocidad: ', style: _labelStyle),
          TextSpan(text: speed.etiqueta, style: _valueStyle),
        ])),
        const SizedBox(height: 8),
        SegmentedButton<Velocidad>(
          showSelectedIcon: false,
          segments: [
            for (final Velocidad v in Velocidad.values)
              ButtonSegment<Velocidad>(value: v, label: Text(speedShortLabel(v)), tooltip: v.etiqueta),
          ],
          selected: {speed},
          onSelectionChanged: (s) => onSpeedChanged(s.first),
          style: SegmentedButton.styleFrom(
            selectedBackgroundColor: AppColors.blue,
            selectedForegroundColor: AppColors.white,
            foregroundColor: AppColors.darkBlue,
            side: const BorderSide(color: AppColors.darkBlue, width: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _pair(Widget a, Widget b) {
    return Row(
      children: [
        Expanded(child: a),
        const SizedBox(width: 10),
        Expanded(child: b),
      ],
    );
  }

  Widget _legend() {
    return Wrap(
      key: keys?.legend,
      spacing: 14,
      runSpacing: 8,
      children: [
        for (final SortLegendEntry entry in kind.legend)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.role.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkBlue),
                ),
              ),
              const SizedBox(width: 6),
              Text(entry.label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTimer) ...[
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: ShapeDecoration(
              color: AppColors.gray.withAlpha(30),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: SortTimer(time: time),
          ),
          const SizedBox(height: 16),
        ],
        _countSlider(),
        const SizedBox(height: 8),
        _speedSelector(),
        const SizedBox(height: 20),
        _pair(
          PillButton(
            key: keys?.shuffle,
            label: 'Mezclar',
            icon: Icons.shuffle,
            style: AppButtonStyle.outline,
            onTap: running ? null : onShuffle,
            fullWidth: true,
          ),
          running
              ? PillButton(
                  key: keys?.solve,
                  label: 'Detener',
                  icon: Icons.stop_rounded,
                  style: AppButtonStyle.dark,
                  onTap: onStop,
                  fullWidth: true,
                )
              : PillButton(
                  key: keys?.solve,
                  label: 'Resolver',
                  icon: Icons.play_arrow_rounded,
                  style: AppButtonStyle.accent,
                  onTap: onSolve,
                  fullWidth: true,
                ),
        ),
        const SizedBox(height: 10),
        _pair(
          PillButton(
            key: keys?.random,
            label: 'Aleatorio',
            icon: Icons.casino_outlined,
            style: AppButtonStyle.outline,
            onTap: running ? null : onRandom,
            fullWidth: true,
          ),
          PillButton(
            key: keys?.enter,
            label: 'Ingresar',
            icon: Icons.edit_outlined,
            style: AppButtonStyle.outline,
            onTap: running ? null : onEnter,
            fullWidth: true,
          ),
        ),
        const SizedBox(height: 18),
        _legend(),
      ],
    );
  }
}
