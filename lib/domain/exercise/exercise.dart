/// Normalized exercise model.
///
/// Parsed from the compiled content bundle (`assets/content/exercises/*.json`),
/// which `scripts/build_content.py` generates from the authoring YAML.
/// Nothing here is exercise-specific: the Exercise Engine renders whatever the
/// data describes (docs/EXERCISE_ENGINE.md).
library;

enum ClinicalStatus {
  draft,
  pendingReview,
  approved,
  retired;

  static ClinicalStatus parse(String? raw) {
    switch (raw) {
      case 'approved':
        return ClinicalStatus.approved;
      case 'pending_review':
        return ClinicalStatus.pendingReview;
      case 'retired':
        return ClinicalStatus.retired;
      default:
        return ClinicalStatus.draft;
    }
  }
}

enum ProgressBasis {
  completedRepetitions,
  sequenceTime;

  static ProgressBasis parse(String? raw) => raw == 'completed_repetitions'
      ? ProgressBasis.completedRepetitions
      : ProgressBasis.sequenceTime;
}

enum BodySide {
  left,
  right;

  static BodySide? parse(String? raw) {
    switch (raw) {
      case 'left':
        return BodySide.left;
      case 'right':
        return BodySide.right;
      default:
        return null;
    }
  }

  String get id => name;
}

/// Catalog-level metadata. The list UI uses only this; the player loads the
/// full record for the selected and next exercise (docs/EXERCISE_ENGINE.md).
class ExerciseSummary {
  const ExerciseSummary({
    required this.id,
    required this.title,
    required this.cardDescription,
    required this.primaryZone,
    required this.clinicalStatus,
    required this.collections,
    required this.tags,
    required this.previewAsset,
    required this.estimatedActiveSeconds,
    required this.requiresPro,
  });

  factory ExerciseSummary.fromJson(Map<String, dynamic> json) {
    return ExerciseSummary(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['id'] as String,
      cardDescription: json['cardDescription'] as String? ?? '',
      primaryZone: json['primaryZone'] as String? ?? '',
      clinicalStatus: ClinicalStatus.parse(json['clinicalStatus'] as String?),
      collections: _stringList(json['collections']),
      tags: _stringList(json['tags']),
      previewAsset: json['preview'] as String?,
      estimatedActiveSeconds:
          (json['estimatedActiveSeconds'] as num?)?.toInt() ?? 0,
      requiresPro: json['requiresPro'] as bool? ?? false,
    );
  }

  final String id;
  final String title;
  final String cardDescription;
  final String primaryZone;
  final ClinicalStatus clinicalStatus;
  final List<String> collections;
  final List<String> tags;
  final String? previewAsset;
  final int estimatedActiveSeconds;
  final bool requiresPro;
}

class Exercise {
  const Exercise({
    required this.id,
    required this.slug,
    required this.clinicalStatus,
    required this.primaryZone,
    required this.collections,
    required this.text,
    required this.labels,
    required this.timing,
    required this.progress,
    required this.repetitionModel,
    required this.movementPhases,
    required this.sequence,
    required this.frames,
    required this.previewAsset,
    required this.reducedMotionFallback,
    required this.audioEvents,
    required this.audioMix,
    required this.flow,
    required this.accessibilitySummary,
    required this.requiresPro,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> animation = _map(json['animation']);
    final Map<String, dynamic> audio = _map(json['audio']);
    final Map<String, dynamic> accessibility = _map(json['accessibility']);

    return Exercise(
      id: json['id'] as String,
      slug: json['slug'] as String? ?? json['id'] as String,
      clinicalStatus: ClinicalStatus.parse(json['clinicalStatus'] as String?),
      primaryZone: json['primaryZone'] as String? ?? '',
      collections: _stringList(json['collections']),
      text: ExerciseText.fromJson(_map(json['text'])),
      labels: <String, String>{
        for (final MapEntry<String, dynamic> entry in _map(
          json['labels'],
        ).entries)
          entry.key: '${entry.value}',
      },
      timing: ExerciseTiming.fromJson(_map(json['timing'])),
      progress: ProgressSettings.fromJson(_map(json['progress'])),
      repetitionModel: RepetitionModel.fromJson(_map(json['repetitionModel'])),
      movementPhases: <MovementPhase>[
        for (final dynamic p in _list(json['movementPhases']))
          MovementPhase.fromJson(_map(p)),
      ],
      sequence: ExerciseSequence.fromJson(_map(json['sequence'])),
      frames: <String, ExerciseFrame>{
        for (final dynamic f in _list(animation['frames']))
          (_map(f)['id'] as String): ExerciseFrame.fromJson(_map(f)),
      },
      previewAsset: animation['preview'] as String?,
      reducedMotionFallback: animation['reducedMotionFallback'] as String?,
      audioEvents: <AudioEvent>[
        for (final dynamic e in _list(audio['events']))
          AudioEvent.fromJson(_map(e)),
      ],
      audioMix: AudioMix.fromJson(_map(audio['mix'])),
      flow: FlowSettings.fromJson(_map(json['flow'])),
      accessibilitySummary: accessibility['summary'] as String?,
      requiresPro: _map(json['pro'])['requiresPro'] as bool? ?? false,
    );
  }

  final String id;
  final String slug;
  final ClinicalStatus clinicalStatus;
  final String primaryZone;
  final List<String> collections;
  final ExerciseText text;

  /// Label overrides from the exercise's `ui` block, keyed by label name
  /// (`side`, `repetition`, ...). Empty means "use the common key".
  final Map<String, String> labels;
  final ExerciseTiming timing;
  final ProgressSettings progress;
  final RepetitionModel repetitionModel;
  final List<MovementPhase> movementPhases;
  final ExerciseSequence sequence;
  final Map<String, ExerciseFrame> frames;
  final String? previewAsset;
  final String? reducedMotionFallback;
  final List<AudioEvent> audioEvents;
  final AudioMix audioMix;
  final FlowSettings flow;
  final String? accessibilitySummary;
  final bool requiresPro;

  AudioEvent? audioEventById(String id) {
    for (final AudioEvent event in audioEvents) {
      if (event.id == id) return event;
    }
    return null;
  }

  String? phaseName(String? phaseId) {
    if (phaseId == null) return null;
    for (final MovementPhase phase in movementPhases) {
      if (phase.id == phaseId) return phase.name;
    }
    return null;
  }
}

class ExerciseText {
  const ExerciseText({
    required this.title,
    required this.shortTitle,
    required this.cardDescription,
    required this.purpose,
    required this.startPositionTitle,
    required this.startPosition,
    required this.instructionsTitle,
    required this.instructions,
    required this.techniqueTipsTitle,
    required this.techniqueTips,
    required this.safetyLabel,
    required this.safety,
    required this.completion,
  });

  factory ExerciseText.fromJson(Map<String, dynamic> json) {
    return ExerciseText(
      title: json['title'] as String? ?? '',
      shortTitle: json['shortTitle'] as String?,
      cardDescription: json['cardDescription'] as String? ?? '',
      purpose: json['purpose'] as String?,
      startPositionTitle: json['startPositionTitle'] as String?,
      startPosition: json['startPosition'] as String?,
      instructionsTitle: json['instructionsTitle'] as String?,
      instructions: <String>[
        for (final dynamic i in _list(json['instructions']))
          _map(i)['text'] as String? ?? '',
      ],
      techniqueTipsTitle: json['techniqueTipsTitle'] as String?,
      techniqueTips: _stringList(json['techniqueTips']),
      safetyLabel: json['safetyLabel'] as String?,
      safety: json['safety'] as String?,
      completion: json['completion'] as String?,
    );
  }

  final String title;
  final String? shortTitle;
  final String cardDescription;
  final String? purpose;
  final String? startPositionTitle;
  final String? startPosition;
  final String? instructionsTitle;
  final List<String> instructions;
  final String? techniqueTipsTitle;
  final List<String> techniqueTips;
  final String? safetyLabel;
  final String? safety;
  final String? completion;
}

class ExerciseTiming {
  const ExerciseTiming({
    required this.prepCountdownSeconds,
    required this.restAfterSeconds,
    required this.completionMode,
    required this.estimatedActiveSeconds,
  });

  factory ExerciseTiming.fromJson(Map<String, dynamic> json) {
    return ExerciseTiming(
      prepCountdownSeconds:
          (json['prepCountdownSeconds'] as num?)?.toInt() ?? 5,
      restAfterSeconds: (json['restAfterSeconds'] as num?)?.toInt() ?? 10,
      completionMode:
          json['completionMode'] as String? ?? 'prescribed_repetitions',
      estimatedActiveSeconds:
          (json['estimatedActiveSeconds'] as num?)?.toInt() ?? 0,
    );
  }

  final int prepCountdownSeconds;
  final int restAfterSeconds;
  final String completionMode;
  final int estimatedActiveSeconds;
}

class ProgressSettings {
  const ProgressSettings({
    required this.basis,
    required this.showElapsedTime,
    required this.showProgressBar,
    required this.showRepetitionCounter,
    required this.showSideLabel,
    required this.showSetCounter,
  });

  factory ProgressSettings.fromJson(Map<String, dynamic> json) {
    return ProgressSettings(
      basis: ProgressBasis.parse(json['basis'] as String?),
      showElapsedTime: json['showElapsedTime'] as bool? ?? true,
      showProgressBar: json['showProgressBar'] as bool? ?? true,
      showRepetitionCounter: json['showRepetitionCounter'] as bool? ?? false,
      showSideLabel: json['showSideLabel'] as bool? ?? false,
      showSetCounter: json['showSetCounter'] as bool? ?? false,
    );
  }

  final ProgressBasis basis;
  final bool showElapsedTime;
  final bool showProgressBar;
  final bool showRepetitionCounter;
  final bool showSideLabel;
  final bool showSetCounter;
}

class RepetitionModel {
  const RepetitionModel({
    required this.type,
    required this.sets,
    required this.repetitionsPerBlock,
    required this.switchSideAutomatically,
    required this.resetCounterOnSideChange,
  });

  factory RepetitionModel.fromJson(Map<String, dynamic> json) {
    return RepetitionModel(
      type: json['type'] as String? ?? 'sequence_time',
      sets: (json['sets'] as num?)?.toInt() ?? 1,
      repetitionsPerBlock: (json['repetitionsPerBlock'] as num?)?.toInt() ?? 1,
      switchSideAutomatically: json['switchSideAutomatically'] as bool? ?? true,
      resetCounterOnSideChange:
          json['resetCounterOnSideChange'] as bool? ?? false,
    );
  }

  final String type;
  final int sets;
  final int repetitionsPerBlock;
  final bool switchSideAutomatically;
  final bool resetCounterOnSideChange;
}

class MovementPhase {
  const MovementPhase({
    required this.id,
    required this.name,
    required this.type,
  });

  factory MovementPhase.fromJson(Map<String, dynamic> json) => MovementPhase(
    id: json['id'] as String,
    name: json['name'] as String?,
    type: json['type'] as String?,
  );

  final String id;
  final String? name;
  final String? type;
}

class ExerciseSequence {
  const ExerciseSequence({required this.blocks});

  factory ExerciseSequence.fromJson(Map<String, dynamic> json) =>
      ExerciseSequence(
        blocks: <SequenceBlock>[
          for (final dynamic b in _list(json['blocks']))
            SequenceBlock.fromJson(_map(b)),
        ],
      );

  final List<SequenceBlock> blocks;
}

class SequenceBlock {
  const SequenceBlock({
    required this.side,
    required this.repeat,
    required this.steps,
  });

  factory SequenceBlock.fromJson(Map<String, dynamic> json) => SequenceBlock(
    side: BodySide.parse(json['side'] as String?),
    repeat: (json['repeat'] as num?)?.toInt() ?? 1,
    steps: <SequenceStep>[
      for (final dynamic s in _list(json['steps']))
        SequenceStep.fromJson(_map(s)),
    ],
  );

  final BodySide? side;
  final int repeat;
  final List<SequenceStep> steps;
}

class SequenceStep {
  const SequenceStep({
    required this.id,
    required this.phase,
    required this.side,
    required this.frameId,
    required this.frameTransition,
    required this.durationMs,
    required this.voiceEvent,
  });

  factory SequenceStep.fromJson(Map<String, dynamic> json) {
    final dynamic transition = json['frameTransition'];
    return SequenceStep(
      id: json['id'] as String,
      phase: json['phase'] as String?,
      side: BodySide.parse(json['side'] as String?),
      frameId: json['frameId'] as String?,
      frameTransition: transition == null
          ? null
          : FrameTransition.fromJson(_map(transition)),
      durationMs: (json['durationMs'] as num).toInt(),
      voiceEvent: json['voiceEvent'] as String?,
    );
  }

  final String id;
  final String? phase;
  final BodySide? side;
  final String? frameId;
  final FrameTransition? frameTransition;
  final int durationMs;
  final String? voiceEvent;
}

class FrameTransition {
  const FrameTransition({
    required this.from,
    required this.via,
    required this.to,
  });

  factory FrameTransition.fromJson(Map<String, dynamic> json) =>
      FrameTransition(
        from: json['from'] as String?,
        via: json['via'] as String?,
        to: json['to'] as String?,
      );

  final String? from;
  final String? via;
  final String? to;

  /// Frames in playback order, skipping the optional intermediate frame.
  List<String> get frameIds => <String>[
    if (from != null) from!,
    if (via != null) via!,
    if (to != null) to!,
  ];
}

class ExerciseFrame {
  const ExerciseFrame({
    required this.id,
    required this.file,
    required this.altText,
  });

  factory ExerciseFrame.fromJson(Map<String, dynamic> json) => ExerciseFrame(
    id: json['id'] as String,
    file: json['file'] as String,
    altText: json['altText'] as String?,
  );

  final String id;
  final String file;
  final String? altText;
}

class AudioEvent {
  const AudioEvent({
    required this.id,
    required this.type,
    required this.priority,
    required this.interruptible,
    required this.playOncePerSide,
    required this.text,
    required this.assetKey,
    required this.assetFile,
    required this.trigger,
  });

  factory AudioEvent.fromJson(Map<String, dynamic> json) => AudioEvent(
    id: json['id'] as String,
    type: json['type'] as String?,
    priority: (json['priority'] as num?)?.toInt() ?? 50,
    interruptible: json['interruptible'] as bool? ?? true,
    playOncePerSide: json['playOncePerSide'] as bool? ?? false,
    text: json['text'] as String?,
    assetKey: json['assetKey'] as String?,
    assetFile: json['assetFile'] as String?,
    trigger: AudioTrigger.fromJson(_map(json['trigger'])),
  );

  final String id;
  final String? type;
  final int priority;
  final bool interruptible;
  final bool playOncePerSide;
  final String? text;
  final String? assetKey;
  final String? assetFile;
  final AudioTrigger trigger;
}

class AudioTrigger {
  const AudioTrigger({
    required this.event,
    required this.phase,
    required this.side,
    required this.percent,
    required this.repetitionNumber,
    required this.relativePosition,
    required this.offsetMs,
  });

  factory AudioTrigger.fromJson(Map<String, dynamic> json) => AudioTrigger(
    event: json['event'] as String? ?? '',
    phase: json['phase'] as String?,
    side: BodySide.parse(json['side'] as String?),
    percent: (json['percent'] as num?)?.toInt(),
    repetitionNumber: (json['repetitionNumber'] as num?)?.toInt(),
    relativePosition: json['relativePosition'] as String?,
    offsetMs: (json['offsetMs'] as num?)?.toInt(),
  );

  final String event;
  final String? phase;
  final BodySide? side;
  final int? percent;
  final int? repetitionNumber;
  final String? relativePosition;
  final int? offsetMs;
}

class AudioMix {
  const AudioMix({
    required this.voiceLevel,
    required this.musicLevel,
    required this.dynamicDucking,
  });

  factory AudioMix.fromJson(Map<String, dynamic> json) => AudioMix(
    voiceLevel: (json['voiceLevel'] as num?)?.toDouble() ?? 1.0,
    musicLevel: (json['musicLevel'] as num?)?.toDouble() ?? 0.5,
    dynamicDucking: json['dynamicDucking'] as bool? ?? false,
  );

  final double voiceLevel;
  final double musicLevel;
  final bool dynamicDucking;
}

class FlowSettings {
  const FlowSettings({
    required this.autoNextEnabled,
    required this.restSeconds,
    required this.incrementCounterOnCompletion,
  });

  factory FlowSettings.fromJson(Map<String, dynamic> json) => FlowSettings(
    autoNextEnabled: json['autoNextEnabled'] as bool? ?? true,
    restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 10,
    incrementCounterOnCompletion:
        json['incrementCounterOnCompletion'] as bool? ?? true,
  );

  final bool autoNextEnabled;
  final int restSeconds;
  final bool incrementCounterOnCompletion;
}

// ------------------------------------------------------------------ helpers

Map<String, dynamic> _map(dynamic value) =>
    value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

List<dynamic> _list(dynamic value) => value is List ? value : const <dynamic>[];

List<String> _stringList(dynamic value) => value is List
    ? value.map((dynamic e) => e.toString()).toList()
    : <String>[];
