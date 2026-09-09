/// Reads the compiled content bundle shipped with the app.
///
/// Authoring is YAML; the app only ever sees validated JSON
/// (docs/TECHNICAL_SPEC.md 5 and 22).
library;

import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/exercise/exercise.dart';

class BodyZone {
  const BodyZone({required this.id, required this.title, required this.order});

  factory BodyZone.fromJson(Map<String, dynamic> json) => BodyZone(
    id: json['id'] as String,
    title: json['title'] as String? ?? json['id'] as String,
    order: (json['order'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String title;
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

class BodyHotspot {
  const BodyHotspot({
    required this.id,
    required this.zoneId,
    required this.view,
    required this.labelKey,
    required this.priority,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.collectionId,
  });

  factory BodyHotspot.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rect = (json['rect'] as Map)
        .cast<String, dynamic>();
    final Map<String, dynamic> action = (json['action'] as Map)
        .cast<String, dynamic>();
    return BodyHotspot(
      id: json['id'] as String,
      zoneId: json['zoneId'] as String,
      view: json['view'] as String,
      labelKey: json['labelKey'] as String,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      left: (rect['x'] as num).toDouble(),
      top: (rect['y'] as num).toDouble(),
      width: (rect['width'] as num).toDouble(),
      height: (rect['height'] as num).toDouble(),
      collectionId: action['collectionId'] as String?,
    );
  }

  final String id;
  final String zoneId;

  /// `front` or `back`.
  final String view;
  final String labelKey;
  final int priority;

  /// Normalized 0..1 against the rendered artwork bounds — never device pixels
  /// (docs/BODY_MAP_SPEC.md).
  final double left;
  final double top;
  final double width;
  final double height;
  final String? collectionId;
}

class ContentBundle {
  const ContentBundle({
    required this.defaultLocale,
    required this.exercises,
    required this.collections,
    required this.zones,
    required this.hotspots,
  });

  static const String indexAsset = 'assets/content/index.json';

  final String defaultLocale;
  final List<ExerciseSummary> exercises;
  final List<ExerciseCollection> collections;
  final List<BodyZone> zones;
  final List<BodyHotspot> hotspots;

  static Future<ContentBundle> load({AssetBundle? bundle}) async {
    final AssetBundle assets = bundle ?? rootBundle;
    final Map<String, dynamic> json =
        jsonDecode(await assets.loadString(indexAsset)) as Map<String, dynamic>;
    final Map<String, dynamic> bodyMap = (json['bodyMap'] as Map)
        .cast<String, dynamic>();

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
      hotspots: <BodyHotspot>[
        for (final dynamic h in bodyMap['hotspots'] as List<dynamic>)
          BodyHotspot.fromJson((h as Map).cast<String, dynamic>()),
      ],
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

  List<BodyHotspot> hotspotsForView(String view) {
    final List<BodyHotspot> result = <BodyHotspot>[
      for (final BodyHotspot spot in hotspots)
        if (spot.view == view) spot,
    ];
    // Higher priority last so a small area sits on top of a large one.
    result.sort(
      (BodyHotspot a, BodyHotspot b) => a.priority.compareTo(b.priority),
    );
    return result;
  }
}
