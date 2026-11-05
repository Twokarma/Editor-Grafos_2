import 'package:flutter/material.dart';
import 'package:graph_maker_app_2/theme/app_colors.dart';

class ResultBox extends StatelessWidget {
  final String? error;
  final String? placeholder;
  final Widget? child;

  const ResultBox({super.key, this.error, this.placeholder, this.child});

  @override
  Widget build(BuildContext context) {
    final bool isError = error != null;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: ShapeDecoration(
        color: AppColors.gray.withAlpha(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isError ? const BorderSide(color: AppColors.orange, width: 1.5) : BorderSide.none,
        ),
      ),
      child: isError || child == null
          ? Text(
              error ?? placeholder ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isError ? Theme.of(context).colorScheme.error : AppColors.gray,
                fontSize: 15,
                fontWeight: isError ? FontWeight.w600 : FontWeight.normal,
              ),
            )
          : child,
    );
  }
}

class ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const ResultRow({super.key, required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    final TextStyle style = TextStyle(
      color: AppColors.darkBlue,
      fontSize: 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}
