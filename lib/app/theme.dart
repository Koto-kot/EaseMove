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

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  /// The approved home screen is white from edge to edge whatever the app
  /// theme is: the body artwork carries a near-white background baked into
  /// the PNG, and the reference puts every element of that screen — cards,
  /// text, icons — on that same white
  /// (docs/ui/home/reference/HOME_SCREEN_REFERENCE.png).
  static ThemeData homeLight() {
    final ThemeData base = light();
    final ColorScheme scheme = base.colorScheme.copyWith(
      surface: Tokens.bodyMapPanel,
      surfaceContainerLow: Tokens.bodyMapPanel,
      surfaceContainerHighest: Tokens.bodyMapPanel,
      onSurface: Tokens.textStrong,
      onSurfaceVariant: Tokens.textMuted,
      outline: Tokens.textMuted,
    );
    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: Tokens.bodyMapPanel,
      canvasColor: Tokens.bodyMapPanel,
      iconTheme: const IconThemeData(color: Tokens.hotspot),
      drawerTheme: const DrawerThemeData(backgroundColor: Tokens.bodyMapPanel),
    );
  }

  static ThemeData _build(Brightness brightness) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    final ThemeData base = ThemeData(colorScheme: scheme, useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.comfortable,
      materialTapTargetSize: MaterialTapTargetSize.padded,
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
