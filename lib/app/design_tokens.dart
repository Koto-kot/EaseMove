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
