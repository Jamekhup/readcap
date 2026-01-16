import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTextStyles {
  static TextTheme get textTheme {
    final base = GoogleFonts.spaceGroteskTextTheme();
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -1.2,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: -0.4,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
