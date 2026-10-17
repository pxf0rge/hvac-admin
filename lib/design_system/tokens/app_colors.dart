import 'package:flutter/material.dart';

/// Arctic HVAC brand palette (Phase 01).
///
/// Cool, ice-tinted dark surfaces plus a glacier-cyan primary so the product
/// reads as a single owned visual identity instead of a stock dark theme.
/// Semantic status colors stay distinct (assigned / on the way / completed /
/// danger) and AA-readable on their muted chip backgrounds.
abstract final class AppColors {
  // --- Arctic surfaces (cool slate, ice-tinted) ---
  static const background = Color(0xFF0D1319);
  static const surface = Color(0xFF151D25);
  static const surfaceHover = Color(0xFF1E2831);
  static const sidebarBg = Color(0xFF0A0F14);
  static const drawerBg = Color(0xFF10171E);
  static const overlay = Color(0x99000000);

  // --- Borders ---
  static const border = Color(0xFF25313C);
  static const borderLight = Color(0xFF32404D);

  // --- Text (icy whites / slate blues) ---
  static const textPrimary = Color(0xFFEAF0F6);
  static const textSecondary = Color(0xFF9DAEBD);
  static const textMuted = Color(0xFF64748B);

  // --- Brand / semantic ---
  /// Glacier cyan — interactive text, icons, focus, selected accents on dark.
  static const primary = Color(0xFF22D3EE);

  /// Deep glacier — selected/emphasis backgrounds behind [primary] content.
  static const primaryMuted = Color(0xFF164E63);

  /// Strong glacier — filled CTA backgrounds (white text stays AA ≥ 4.5:1).
  static const primaryStrong = Color(0xFF0E7490);

  /// Aurora mint — subtle highlight accents (sparkles, live badges).
  static const accent = Color(0xFF5EEAD4);

  static const success = Color(0xFF34D399);
  static const successMuted = Color(0xFF0F3D2E);
  static const warning = Color(0xFFFBBF24);
  static const warningMuted = Color(0xFF78350F);
  static const danger = Color(0xFFFCA5A5);
  static const dangerMuted = Color(0xFF7F1D1D);

  // --- Avatars (Arctic-tinted but still distinguishable) ---
  static const avatarColors = [
    Color(0xFF22D3EE),
    Color(0xFFA78BFA),
    Color(0xFF5EEAD4),
    Color(0xFF34D399),
    Color(0xFFFBBF24),
    Color(0xFFF87171),
    Color(0xFF7DD3FC),
    Color(0xFFF472B6),
  ];
}
