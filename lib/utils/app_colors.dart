import 'package:flutter/material.dart';

/// Mari App Color Palette
/// Inspired by the dark green theme from the design mockups
class AppColors {
  // Primary Colors - Professional Navy Blue
  static const Color primaryDark = Color(
    0xFF0A1929,
  ); // Very deep navy, almost black
  static const Color primaryNavy = Color(0xFF1E3A5F); // Deep navy blue
  static const Color primaryMedium = Color(0xFF2E5077); // Medium navy
  static const Color primaryLight = Color(0xFF4A7BA7); // Lighter blue

  // Accent Colors - Sky Blue (Minimal, Subtle)
  static const Color accentBright = Color(0xFF60A5FA); // Bright sky blue
  static const Color accentLight = Color(0xFF93C5FD); // Light sky blue
  static const Color accentGlow = Color(0xFF3B82F6); // Vibrant blue

  // Background Colors - Deep Blue-Grey
  static const Color backgroundDark = Color(
    0xFF030712,
  ); // Almost black with blue tint
  static const Color backgroundCard = Color(0xFF0F1926); // Dark blue-grey card
  static const Color backgroundOverlay = Color(
    0x60000000,
  ); // Semi-transparent overlay

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC); // Off-white
  static const Color textSecondary = Color(0xFFCBD5E1); // Light blue-grey
  static const Color textMuted = Color(0xFF64748B); // Muted blue-grey

  // Status Colors (kept functional)
  static const Color success = Color(0xFF10B981); // Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // Red
  static const Color info = Color(0xFF3B82F6); // Blue

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E3A5F), Color(0xFF0A1929)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF93C5FD), Color(0xFF60A5FA), Color(0xFF3B82F6)],
  );

  // Subtle Glow Gradients (Professional, not flashy)
  static const RadialGradient ambientGlow = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0x2060A5FA), // Very subtle blue glow
      Color(0x0060A5FA), // Transparent
    ],
    stops: [0.0, 0.7],
  );

  static const LinearGradient bottomGlow = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Color(0x302E5077), // Subtle navy glow at bottom
      Colors.transparent,
    ],
    stops: [0.0, 0.6],
  );

  static const LinearGradient glowGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0x2060A5FA), Color(0x00000000)],
  );

  // Shadow Colors
  static const Color shadowLight = Color(0x2060A5FA); // Light blue shadow
  static const Color shadowMedium = Color(0x402E5077); // Medium navy shadow
  static const Color shadowDark = Color(0x80000000); // Dark shadow
}
