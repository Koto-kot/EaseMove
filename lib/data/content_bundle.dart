/// Reads the compiled content bundle shipped with the app.
///
/// Authoring is YAML; the app only ever sees validated JSON
/// (docs/TECHNICAL_SPEC.md 5 and 22).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/exercise/exercise.dart';

class BodyZone {
  const BodyZone({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.order,
  });

  factory BodyZone.fromJson(Map<String, dynamic> json) {
    final String title = json['title'] as String? ?? json['id'] as String;
    return BodyZone(
      id: json['id'] as String,
      title: title,
      shortTitle: json['shortTitle'] as String? ?? title,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String title;

  /// Label used beside the body map, where a full title like
  /// "Гомілковостопні суглоби" does not fit on a phone.
  final String shortTitle;
  final int order;
}

class ExerciseCollection {
  const ExerciseCollection({
    required this.id,
    required this.title,
    required this.type,
    required this.primaryZone,
  });

  factory ExerciseCollection.fromJson(Map<String, dynamic> json) =>
      ExerciseCollection(
        id: json['id'] as String,
        title: json['title'] as String? ?? json['id'] as String,
        type: json['type'] as String? ?? 'theme',
        primaryZone: json['primaryZone'] as String?,
      );

  final String id;
  final String title;
  final String type;
  final String? primaryZone;

  bool get isBodyZone => type == 'body_zone';
  bool get isSituation => type == 'situation';
}

/// One tappable body zone on the home screen's map.
class BodyHotspot {
  const BodyHotspot({
    required this.id,
    required this.view,
    required this.group,
    required this.zoneId,
    required this.collectionId,
    required this.highlightTargets,
    required this.cx,
    required this.cy,
    required this.w,
    required this.h,
  });

  factory BodyHotspot.fromJson(Map<String, dynamic> json) => BodyHotspot(
    id: json['id'] as String,
    view: json['view'] as String,
    group: json['group'] as String,
    zoneId: json['zoneId'] as String,
    collectionId: json['collectionId'] as String,
    highlightTargets: <String>[
      for (final dynamic t in json['highlightTargets'] as List<dynamic>)
        t as String,
    ],
    cx: (json['cx'] as num).toDouble(),
    cy: (json['cy'] as num).toDouble(),
    w: (json['w'] as num).toDouble(),
    h: (json['h'] as num).toDouble(),
  );

  final String id;

  /// `front` or `back_mini`.
  final String view;

  /// Symmetrical zones share a group: tapping one knee highlights both
  /// (docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 5.3).
  final String group;
  final String zoneId;
  final String collectionId;

  /// Which hotspots light up when this one is tapped, this one included.
  final List<String> highlightTargets;

  /// Centre and extent, normalized 0..1 against the *cropped figure* rather
  /// than the artwork file: the build converts the authored artwork
  /// coordinates into this space, so the widget does no arithmetic beyond
  /// scaling to its own box.
  final double cx;
  final double cy;
  final double w;
  final double h;
}

/// One body figure, plus where the figure actually sits inside its PNG.
class BodyMapArtwork {
  const BodyMapArtwork({
    required this.asset,
    required this.widthPx,
    required this.heightPx,
    required this.contentLeft,
    required this.contentTop,
    required this.contentWidth,
    required this.contentHeight,
  });

  factory BodyMapArtwork.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> content = (json['content'] as Map)
        .cast<String, dynamic>();
    return BodyMapArtwork(
      asset: json['asset'] as String,
      widthPx: (json['widthPx'] as num).toDouble(),
      heightPx: (json['heightPx'] as num).toDouble(),
      contentLeft: (content['left'] as num).toDouble(),
      contentTop: (content['top'] as num).toDouble(),
      contentWidth: (content['width'] as num).toDouble(),
      contentHeight: (content['height'] as num).toDouble(),
    );
  }

  final String asset;
  final double widthPx;
  final double heightPx;

  /// The figure's bounds inside the artwork, as fractions of the file. Both
  /// PNGs carry wide empty margins, so drawing the whole file would leave the
  /// figure tiny; the widget crops to this rect.
  final double contentLeft;
  final double contentTop;
  final double contentWidth;
  final double contentHeight;

  /// Aspect ratio of the figure itself, which is what the layout must respect.
  double get aspectRatio =>
      (widthPx * contentWidth) / (heightPx * contentHeight);
}

class BodyMapRules {
  const BodyMapRules({
    required this.pairedHighlight,
    required this.pulseDuration,
    required this.coreDiameter,
    required this.haloDiameter,
    required this.minimumTouchTarget,
    required this.tapMaxDistance,
  });

  factory BodyMapRules.fromJson(Map<String, dynamic> json) => BodyMapRules(
    pairedHighlight: json['pairedHighlight'] as bool? ?? true,
    pulseDuration: Duration(
      milliseconds: (json['pulseDurationMs'] as num?)?.toInt() ?? 300,
    ),
    coreDiameter: (json['coreDiameter'] as num?)?.toDouble() ?? 22,
    haloDiameter: (json['haloDiameter'] as num?)?.toDouble() ?? 52,
    minimumTouchTarget: (json['minimumTouchTarget'] as num?)?.toDouble() ?? 56,
    tapMaxDistance: (json['tapMaxDistance'] as num?)?.toDouble() ?? 44,
  );

  final bool pairedHighlight;

  /// The zone pulses, then navigates (brief 5.2).
  final Duration pulseDuration;
  final double coreDiameter;
  final double haloDiameter;
  final double minimumTouchTarget;

  /// Nineteen dots on one figure overlap, so a tap resolves to the nearest
  /// centre within this distance instead of to whatever widget is on top.
  final double tapMaxDistance;
}

class BodyMapConfig {
  const BodyMapConfig({
    required this.artwork,
    required this.hotspots,
    required this.rules,
  });

  factory BodyMapConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> artwork = (json['artwork'] as Map)
        .cast<String, dynamic>();
    return BodyMapConfig(
      artwork: <String, BodyMapArtwork>{
        for (final MapEntry<String, dynamic> entry in artwork.entries)
          entry.key: BodyMapArtwork.fromJson(
            (entry.value as Map).cast<String, dynamic>(),
          ),
      },
      hotspots: <BodyHotspot>[
        for (final dynamic h in json['hotspots'] as List<dynamic>)
          BodyHotspot.fromJson((h as Map).cast<String, dynamic>()),
      ],
      rules: BodyMapRules.fromJson(
        (json['uiRules'] as Map).cast<String, dynamic>(),
      ),
    );
  }

  final Map<String, BodyMapArtwork> artwork;
  final List<BodyHotspot> hotspots;
  final BodyMapRules rules;

  List<BodyHotspot> forView(String view) => <BodyHotspot>[
    for (final BodyHotspot spot in hotspots)
      if (spot.view == view) spot,
  ];

  BodyHotspot? byId(String id) {
    for (final BodyHotspot spot in hotspots) {
      if (spot.id == id) return spot;
    }
    return null;
  }
}

/// One of the four cards under the body map.
class HomeSection {
  const HomeSection({
    required this.id,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.tint,
    required this.targetType,
    required this.targetCollectionId,
  });

  factory HomeSection.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> target = (json['target'] as Map)
        .cast<String, dynamic>();
    return HomeSection(
      id: json['id'] as String,
      icon: json['icon'] as String,
      titleKey: json['titleKey'] as String,
      subtitleKey: json['subtitleKey'] as String,
      tint: json['tint'] as String? ?? '',
      targetType: target['type'] as String,
      targetCollectionId: target['collectionId'] as String?,
    );
  }

  final String id;
  final String icon;
  final String titleKey;
  final String subtitleKey;

  /// Named tint, resolved to a colour by the theme rather than by the data
  /// (brief 7.2: exact colours belong in theme tokens).
  final String tint;

  /// `zones` opens the zone index; `collection` opens one collection.
  final String targetType;
  final String? targetCollectionId;

  bool get opensZones => targetType == 'zones';
}

class HomeConfig {
  const HomeConfig({
    required this.menuButton,
    required this.settingsButton,
    required this.showSubtitle,
    required this.titleKey,
    required this.subtitleKey,
    required this.hintKey,
    required this.sections,
  });

  factory HomeConfig.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> header = (json['header'] as Map)
        .cast<String, dynamic>();
    return HomeConfig(
      menuButton: header['menuButton'] as bool? ?? true,
      settingsButton: header['settingsButton'] as bool? ?? true,
      showSubtitle: header['showSubtitle'] as bool? ?? true,
      titleKey: header['titleKey'] as String,
      subtitleKey: header['subtitleKey'] as String,
      hintKey: json['hintKey'] as String?,
      sections: <HomeSection>[
        for (final dynamic s in json['sections'] as List<dynamic>)
          HomeSection.fromJson((s as Map).cast<String, dynamic>()),
      ],
    );
  }

  final bool menuButton;
  final bool settingsButton;

  /// The header always reserves its block (brief 3.2); this says whether the
  /// explanatory second line is drawn in it.
  final bool showSubtitle;
  final String titleKey;
  final String subtitleKey;

  /// Shown under the back figure rather than in the header, where the
  /// right-hand column is otherwise empty.
  final String? hintKey;
  final List<HomeSection> sections;
}

class ContentBundle {
  const ContentBundle({
    required this.defaultLocale,
    required this.exercises,
    required this.collections,
    required this.zones,
    required this.bodyMap,
    required this.home,
  });

  static const String indexAsset = 'assets/content/index.json';

  final String defaultLocale;
  final List<ExerciseSummary> exercises;
  final List<ExerciseCollection> collections;
  final List<BodyZone> zones;
  final BodyMapConfig bodyMap;
  final HomeConfig home;

  static Future<ContentBundle> load({AssetBundle? bundle}) async {
    final AssetBundle assets = bundle ?? rootBundle;
    final Map<String, dynamic> json =
        jsonDecode(await assets.loadString(indexAsset)) as Map<String, dynamic>;

    return ContentBundle(
      defaultLocale: json['defaultLocale'] as String? ?? 'uk',
      exercises: <ExerciseSummary>[
        for (final dynamic e in json['exercises'] as List<dynamic>)
          ExerciseSummary.fromJson((e as Map).cast<String, dynamic>()),
      ],
      collections: <ExerciseCollection>[
        for (final dynamic c in json['collections'] as List<dynamic>)
          ExerciseCollection.fromJson((c as Map).cast<String, dynamic>()),
      ],
      zones: <BodyZone>[
        for (final dynamic z in json['zones'] as List<dynamic>)
          BodyZone.fromJson((z as Map).cast<String, dynamic>()),
      ],
      bodyMap: BodyMapConfig.fromJson(
        (json['bodyMap'] as Map).cast<String, dynamic>(),
      ),
      home: HomeConfig.fromJson((json['home'] as Map).cast<String, dynamic>()),
    );
  }

  static Future<Exercise> loadExercise(String id, {AssetBundle? bundle}) async {
    final AssetBundle assets = bundle ?? rootBundle;
    final String raw = await assets.loadString(
      'assets/content/exercises/$id.json',
    );
    return Exercise.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  ExerciseCollection? collectionById(String id) {
    for (final ExerciseCollection collection in collections) {
      if (collection.id == id) return collection;
    }
    return null;
  }

  BodyZone? zoneById(String id) {
    for (final BodyZone zone in zones) {
      if (zone.id == id) return zone;
    }
    return null;
  }
}
