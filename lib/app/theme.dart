/// Calm, friendly, non-sporty visual system (docs/VISUAL_STYLE_GUIDE.md).
///
/// Large touch targets and scalable text are accessibility requirements, not
/// preferences (docs/TECHNICAL_SPEC.md 18).
library;

import 'package:flutter/material.dart';

import 'design_tokens.dart';

abstract final class AppTheme {
  /// Minimum interactive size in dp.
  static const double minTouchTarget = 48;

  static const double cardRadius = 20;
  static const double screenPadding = 20;

  static const Color _seed = Color(0xFF3F7F76);

  /// Every screen is light and does not follow the system's dark mode: the
  /// body artwork carries a near-white background baked into the PNG, and the
  /// approved reference puts every element - cards, text, icons - on that same
  /// white (docs/ui/home/reference/HOME_SCREEN_REFERENCE.png). Under a dark
  /// theme the figure sat on a bright slab.
  static ThemeData light() => _build(Brightness.light);

  /// Applied to the two surfaces that stay dark on purpose: the menu drawer
  /// and Settings. They are chrome rather than content - nothing in them sits
  /// on the artwork's white.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final bool isLight = brightness == Brightness.light;
    final ColorScheme seeded = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    // The seed keeps the product's own accent for actions; on light the
    // surfaces and the ink come from the reference instead, so a screen is
    // white with deep navy text rather than tinted with the seed.
    final ColorScheme scheme = isLight
        ? seeded.copyWith(
            surface: Tokens.pageWhite,
            surfaceContainerLow: Tokens.pageWhite,
            surfaceContainerHighest: Tokens.surfaceQuiet,
            onSurface: Tokens.textStrong,
            onSurfaceVariant: Tokens.textMuted,
            outline: Tokens.textMuted,
            outlineVariant: Tokens.hairline,
          )
        : seeded;
    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      iconTheme: isLight
          ? const IconThemeData(color: Tokens.hotspot)
          : base.iconTheme,
      dividerTheme: isLight
          ? const DividerThemeData(color: Tokens.hairline)
          : base.dividerTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerHighest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(56),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        backgroundColor: scheme.surface,
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      listTileTheme: const ListTileThemeData(minVerticalPadding: 12),
    );
  }
}
