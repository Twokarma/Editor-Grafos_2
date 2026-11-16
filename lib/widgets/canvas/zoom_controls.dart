import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pressable.dart';

class ZoomControls extends StatelessWidget {
  final double scale;
  final Axis axis;
  final VoidCallback? onZoomIn;
  final VoidCallback? onZoomOut;
  final VoidCallback onReset;
  final VoidCallback onFit;

  const ZoomControls({
    super.key,
    required this.scale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onReset,
    required this.onFit,
    this.axis = Axis.horizontal,
  });

  @override
  Widget build(BuildContext context) {
    final bool vertical = axis == Axis.vertical;
    final Widget gap = vertical ? const SizedBox(height: 2) : const SizedBox(width: 2);
    final List<Widget> zoomButtons = [
      _ZoomButton(icon: Icons.remove, tooltip: 'Alejar', onTap: onZoomOut),
      gap,
      _ZoomLabel(scale: scale, onTap: onReset),
      gap,
      _ZoomButton(icon: Icons.add, tooltip: 'Acercar', onTap: onZoomIn),
    ];
    final List<Widget> children = [
      ...(vertical ? zoomButtons.reversed : zoomButtons),
      vertical
          ? Container(width: 22, height: 1, margin: const EdgeInsets.symmetric(vertical: 4), color: AppColors.marfil)
          : Container(width: 1, height: 22, margin: const EdgeInsets.symmetric(horizontal: 4), color: AppColors.marfil),
      _ZoomButton(icon: Icons.fit_screen_outlined, tooltip: 'Ajustar a la vista', onTap: onFit),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: AppColors.white,
        shape: const StadiumBorder(),
        shadows: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Flex(
        direction: axis,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _ZoomButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        hoverLift: 0,
        child: Opacity(
          opacity: onTap != null ? 1 : 0.35,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, size: 20, color: AppColors.darkBlue),
          ),
        ),
      ),
    );
  }
}

class _ZoomLabel extends StatelessWidget {
  final double scale;
  final VoidCallback onTap;

  const _ZoomLabel({required this.scale, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Restablecer al 100%',
      child: Pressable(
        onTap: onTap,
        hoverLift: 0,
        child: SizedBox(
          width: 48,
          height: 36,
          child: Center(
            child: Text(
              '${(scale * 100).round()}%',
              style: const TextStyle(
                color: AppColors.darkBlue,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
