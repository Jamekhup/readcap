import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isFilled = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(label),
      ],
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isFilled ? AppColors.accentGradient : null,
        borderRadius: BorderRadius.circular(18),
        border: isFilled ? null : Border.all(color: AppColors.neonCyan),
      ),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.softWhite,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          textStyle: Theme.of(context).textTheme.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: content,
      ),
    );
  }
}
