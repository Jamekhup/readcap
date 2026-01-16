import 'package:flutter/material.dart';

class AppColors {
  static const Color midnight = Color(0xFF0C1021);
  static const Color deepSpace = Color(0xFF11162B);
  static const Color neonCyan = Color(0xFF4DEEEA);
  static const Color neonOrange = Color(0xFFFF7B4A);
  static const Color neonPink = Color(0xFFFF4D93);
  static const Color softWhite = Color(0xFFF4F6FB);
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color coolGray = Color(0xFFB6C1E1);
  static const Color darkGlass = Color(0x66070A17);

  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF11162B), Color(0xFF21183C), Color(0xFF2B1440)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [neonCyan, neonPink],
  );
}
