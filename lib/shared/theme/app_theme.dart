import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.neonCyan,
      brightness: Brightness.dark,
      primary: AppColors.neonCyan,
      secondary: AppColors.neonPink,
      surface: AppColors.deepSpace,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.midnight,
      textTheme: AppTextStyles.textTheme.apply(
        bodyColor: AppColors.softWhite,
        displayColor: AppColors.softWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.softWhite,
        elevation: 0,
        centerTitle: false,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.neonCyan,
        inactiveTrackColor: AppColors.glassWhite,
        thumbColor: AppColors.neonPink,
        overlayColor: AppColors.neonPink.withOpacity(0.2),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkGlass,
        hintStyle: const TextStyle(color: AppColors.coolGray),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: const ChipThemeData(
        backgroundColor: AppColors.darkGlass,
        labelStyle: TextStyle(color: AppColors.softWhite),
        shape: StadiumBorder(),
      ),
    );
  }
}
