import 'package:flutter/material.dart';

class AppColors {
  // Brand & Palette colors (Slate and Sky theme)
  static const Color primary = Color(0xFF0F172A);      // Slate 900 (Main Deep Navy)
  static const Color primaryLight = Color(0xFF1E293B); // Slate 800 (Sub Dark)
  static const Color secondary = Color(0xFF0EA5E9);    // Sky 500 (Point Accent Sky Blue)
  
  static const Color background = Color(0xFFF8FAFC);   // Slate 50 (App base bg)
  static const Color cardBackground = Colors.white;
  
  // Neutral Text
  static const Color textPrimary = Color(0xFF0F172A);  // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color textLight = Color(0xFF94A3B8);     // Slate 400
  
  // UI Borders & dividers
  static const Color border = Color(0xFFE2E8F0);       // Slate 200
  static const Color borderFocus = Color(0xFF0EA5E9);  // Sky 500
  
  // Feedback states
  static const Color success = Color(0xFF10B981);     // Emerald 500
  static const Color warning = Color(0xFFF59E0B);     // Amber 500
  static const Color error = Color(0xFFEF4444);       // Red 500
  
  // Glassmorphism overlays
  static const Color overlay = Color(0x0A0F172A);     // Translucent Slate overlay
}
