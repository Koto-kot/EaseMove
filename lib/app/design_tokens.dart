/// Design tokens: the values screens share instead of each inventing its own.
///
/// Zone colour is presentation, not content, so it lives here rather than in
/// `data/` — the zone's identity is its id, which never changes.
library;

import 'package:flutter/material.dart';

abstract final class Tokens {
  // ------------------------------------------------------------------ layout

  /// Minimum interactive size in dp (docs/TECHNICAL_SPEC.md 18).
  static const double touchTarget = 48;

  static const double gutter = 20;
  static const double gap = 12;
  static const double cardRadius = 20;
  static const double chipRadius = 999;

  /// Body map figure proportions: tall, arms slightly away from the body
  /// (docs/BODY_MAP_SPEC.md 2).
  static const double figureAspectRatio = 0.42;

  /// Hotspot marker diameter. Smaller than the touch target on purpose: the
  /// dot is the visual, the tappable area around it is bigger.
  static const double markerSize = 22;

  // ------------------------------------------------------------------ colours

  /// One colour per body zone, so a dot on the figure and its label read as
  /// the same thing. Chosen to stay distinguishable in both themes and not to
  /// look like a heat map of pain.
  static const Map<String, Color> _zoneColors = <String, Color>{
    'neck': Color(0xFFE05252),
    'shoulders': Color(0xFFE8873A),
    'upper_back': Color(0xFFD9534F),
    'elbows': Color(0xFF4CA96B),
    'wrists_hands': Color(0xFF8B6DD1),
    'lower_back': Color(0xFFE0A32E),
    'hips': Color(0xFF3B8FD4),
    'knees': Color(0xFFD1495B),
    'calves': Color(0xFF3FA88A),
    'ankles': Color(0xFF7A6BD1),
    'feet': Color(0xFF9B5DA8),
  };

  /// Falls back to the theme's primary, so an unknown zone still renders.
  static Color zoneColor(String zoneId, ColorScheme scheme) =>
      _zoneColors[zoneId] ?? scheme.primary;

  /// A zone with no exercises yet is shown, but muted — it must not look
  /// tappable-and-broken.
  static Color mutedZoneColor(ColorScheme scheme) => scheme.outlineVariant;

  /// Body figure fill. `surfaceContainerHighest` sits too close to the
  /// background in the dark theme, where the figure all but disappeared.
  static Color figureColor(ColorScheme scheme) =>
      scheme.onSurfaceVariant.withValues(alpha: 0.5);

  // -------------------------------------------------------------- home cards

  /// Card tints, named in data/ui/home/home_screen.yaml and resolved here:
  /// the brief keeps exact colours out of the content and in the theme (7.2).
  static const Map<String, Color> _tints = <String, Color>{
    'blue_soft': Color(0xFF3B82F6),
    'lavender_soft': Color(0xFF8B7BD8),
    'yellow_soft': Color(0xFFF0B429),
    'mint_soft': Color(0xFF2FA97C),
  };

  /// A wash of the tint over the card surface. Light and dark need different
  /// strengths: the same alpha that reads as a pastel on white turns muddy on
  /// a dark ground.
  static Color cardTint(String name, ColorScheme scheme) {
    final Color hue = _tints[name] ?? scheme.primary;
    final bool dark = scheme.brightness == Brightness.dark;
    return Color.alphaBlend(
      hue.withValues(alpha: dark ? 0.16 : 0.10),
      scheme.surfaceContainerLow,
    );
  }

  static Color cardBorder(String name, ColorScheme scheme) {
    final Color hue = _tints[name] ?? scheme.primary;
    final bool dark = scheme.brightness == Brightness.dark;
    return hue.withValues(alpha: dark ? 0.34 : 0.22);
  }

  // ---------------------------------------------------------------- body map

  /// The artwork ships with this near-white background baked in, so the whole
  /// home screen uses it: anything else would show a seam around the figure.
  static const Color bodyMapPanel = Color(0xFFFBFCFE);

  /// Titles and card labels on the white home screen: the deep navy of the
  /// approved reference, not the theme's near-black.
  static const Color textStrong = Color(0xFF102A56);

  /// Subtitles and chevrons on the same white.
  static const Color textMuted = Color(0xFF5B6B8C);

  /// Hotspot blue, from the approved reference. Fixed rather than themed,
  /// because it sits on the light artwork panel in both themes.
  static const Color hotspot = Color(0xFF1F6FEB);

  // ------------------------------------------------------------------- glow

  /// Soft halo behind a hotspot marker.
  static List<BoxShadow> glow(Color color) => <BoxShadow>[
    BoxShadow(
      color: color.withValues(alpha: 0.35),
      blurRadius: 18,
      spreadRadius: 6,
    ),
    BoxShadow(
      color: color.withValues(alpha: 0.18),
      blurRadius: 32,
      spreadRadius: 14,
    ),
  ];
}
