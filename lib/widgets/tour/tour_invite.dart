import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';
import 'package:graph_maker_app_2/widgets/ui/pill_button.dart';

class TourInvite extends StatelessWidget {
  final String modeLabel;
  final VoidCallback onStart;
  final VoidCallback onDismiss;

  const TourInvite({super.key, required this.modeLabel, required this.onStart, required this.onDismiss});

  static const double _wideFrom = 440;

  @override
  Widget build(BuildContext context) {
    final Widget message = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '¿Primera vez en $modeLabel?',
          style: const TextStyle(color: AppColors.darkBlue, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        const Text(
          'Un recorrido corto te muestra cómo funciona.',
          style: TextStyle(color: AppColors.gray, fontSize: 13),
        ),
      ],
    );
    final Widget close = IconButton(
      tooltip: 'Ahora no',
      onPressed: onDismiss,
      icon: const Icon(Icons.close, color: AppColors.gray),
    );
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: ShapeDecoration(
          color: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.lightBlue, width: 1.5),
          ),
          shadows: [
            BoxShadow(color: AppColors.black.withValues(alpha: 0.10), blurRadius: 18, offset: const Offset(0, 6)),
          ],
        ),
        child: LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth >= _wideFrom) {
            return Row(
              children: [
                const Icon(Icons.explore_outlined, color: AppColors.blue),
                const SizedBox(width: 10),
                Expanded(child: message),
                const SizedBox(width: 8),
                PillButton(label: 'Ver recorrido', style: AppButtonStyle.accent, onTap: onStart),
                close,
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.explore_outlined, color: AppColors.blue),
                  const SizedBox(width: 10),
                  Expanded(child: message),
                  close,
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PillButton(label: 'Ver recorrido', style: AppButtonStyle.accent, onTap: onStart, fullWidth: true),
              ),
            ],
          );
        }),
      ),
    );
  }
}
