/// Body map home screen: "Де турбує?"
///
/// Front and back are shown together, so the whole body is visible at once.
/// Markers are placed from normalized hotspot rects scaled to each figure's
/// rendered box — never hard-coded here (docs/BODY_MAP_SPEC.md 3,
/// docs/TECHNICAL_SPEC.md 23).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_tokens.dart';
import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/exercise_repository.dart';
import '../exercise_catalog/catalog_screen.dart';
import '../home/home_actions.dart';

class BodyMapScreen extends ConsumerWidget {
  const BodyMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: homeActions(context),
      ),
      body: SafeArea(
        bottom: false,
        child: repository.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) =>
              Center(child: Text(t('app.common.error'))),
          data: (ExerciseRepository repo) => _Content(repo: repo),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.repo});

  final ExerciseRepository repo;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    final Map<String, String> zoneLabels = <String, String>{
      for (final BodyZone zone in repo.bundle.zones) zone.id: zone.shortTitle,
    };
    final Set<String> zonesWithContent = <String>{
      for (final ExerciseCollection collection
          in repo.nonEmptyZoneCollections())
        if (collection.primaryZone != null) collection.primaryZone!,
    };
    final List<ExerciseCollection> situations = <ExerciseCollection>[
      for (final ExerciseCollection collection in repo.bundle.collections)
        if (collection.isSituation) collection,
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Tokens.gutter),
      children: <Widget>[
        const SizedBox(height: 8),
        Text(
          t('app.body_map.question'),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          t('app.body_map.subtitle'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Tokens.gutter),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _LabelledFigure(
                view: 'front',
                labelsOnLeft: true,
                hotspots: repo.bundle.hotspotsForView('front'),
                zoneLabels: zoneLabels,
                zonesWithContent: zonesWithContent,
                onZone: (String zoneId) => _openZone(context, repo, zoneId),
              ),
            ),
            Expanded(
              child: _LabelledFigure(
                view: 'back',
                labelsOnLeft: false,
                hotspots: repo.bundle.hotspotsForView('back'),
                zoneLabels: zoneLabels,
                zonesWithContent: zonesWithContent,
                onZone: (String zoneId) => _openZone(context, repo, zoneId),
              ),
            ),
          ],
        ),
        const SizedBox(height: Tokens.gutter),
        if (situations.isNotEmpty) ...<Widget>[
          Text(
            t('app.body_map.situations'),
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Tokens.gap),
          // Situation entry points sit beside the map by design
          // (docs/BODY_MAP_SPEC.md 1).
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Tokens.gap,
            crossAxisSpacing: Tokens.gap,
            childAspectRatio: 2.4,
            children: <Widget>[
              for (final ExerciseCollection situation in situations)
                _SituationTile(
                  collection: situation,
                  count: repo.byCollection(situation.id).length,
                  onTap: () => _open(context, situation.id),
                ),
            ],
          ),
        ],
        const SizedBox(height: Tokens.gutter),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(Tokens.chipRadius),
            ),
            // Flexible, because this line is translated and the longest
            // wording must not overflow a narrow phone.
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Flexible(
                  child: Text(
                    t('app.body_map.footer'),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.favorite,
                  size: 16,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: Tokens.gutter),
        Text(
          t('app.disclaimer'),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Tokens.gutter),
      ],
    );
  }

  void _openZone(BuildContext context, ExerciseRepository repo, String zoneId) {
    final AppStrings t = AppStrings.of(context);
    for (final ExerciseCollection collection in repo.bundle.collections) {
      if (collection.isBodyZone && collection.primaryZone == zoneId) {
        if (repo.byCollection(collection.id).isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${collection.title} — ${t('app.body_map.zone_empty')}',
              ),
            ),
          );
          return;
        }
        _open(context, collection.id);
        return;
      }
    }
  }

  void _open(BuildContext context, String collectionId) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CatalogScreen(collectionId: collectionId),
      ),
    );
  }
}

/// One body view with its markers and the labels beside it, joined by leader
/// lines. Labels are tappable too, so every zone has a comfortable target even
/// though the dots themselves are small (docs/BODY_MAP_SPEC.md 5).
class _LabelledFigure extends StatelessWidget {
  const _LabelledFigure({
    required this.view,
    required this.labelsOnLeft,
    required this.hotspots,
    required this.zoneLabels,
    required this.zonesWithContent,
    required this.onZone,
  });

  /// `front` or `back`.
  final String view;
  final bool labelsOnLeft;
  final List<BodyHotspot> hotspots;
  final Map<String, String> zoneLabels;
  final Set<String> zonesWithContent;
  final void Function(String zoneId) onZone;

  /// Share of the width taken by the figure; the rest holds the labels.
  /// Kept low because a translated label like "Щиколотки" must fit on one
  /// line beside the figure on a narrow phone.
  static const double _figureFraction = 0.45;

  /// Minimum vertical distance between two label chips.
  static const double _labelSpacing = 30;

  /// Half a chip's height, used to centre it on its leader line.
  static const double _labelHalfHeight = 13;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double figureWidth = width * _figureFraction;
        final double figureHeight = figureWidth / Tokens.figureAspectRatio;
        final double figureLeft = labelsOnLeft ? width - figureWidth : 0;
        final double labelWidth = width - figureWidth - 6;

        // The box has to be tall enough for every label to sit on its own
        // line; otherwise the spreading pass pushes the first ones off the top
        // and they collide with the screen header.
        final double boxHeight = math.max(
          figureHeight,
          _zoneCount() * _labelSpacing + 2 * _labelHalfHeight,
        );
        final double figureTop = (boxHeight - figureHeight) / 2;
        // Proportional to the body, so the dots mark a zone instead of
        // covering it.
        final double markerSize = (figureWidth * 0.17).clamp(
          9.0,
          Tokens.markerSize,
        );

        final List<_ZoneAnchor> anchors = _anchors(
          figureWidth,
          figureHeight,
          figureLeft,
          figureTop,
        );
        _spreadLabels(anchors, boxHeight);

        return SizedBox(
          height: boxHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              // Leader lines first, so markers and chips sit on top.
              Positioned.fill(
                child: CustomPaint(
                  painter: _LeaderLinePainter(
                    anchors: anchors,
                    labelsOnLeft: labelsOnLeft,
                    labelEdge: labelsOnLeft ? labelWidth : width - labelWidth,
                    scheme: theme.colorScheme,
                    zonesWithContent: zonesWithContent,
                  ),
                ),
              ),
              Positioned(
                left: figureLeft,
                top: figureTop,
                width: figureWidth,
                height: figureHeight,
                child: _Figure(view: view),
              ),
              for (final _ZoneAnchor anchor in anchors)
                for (final Offset dot in anchor.dots)
                  Positioned(
                    left: dot.dx - markerSize / 2,
                    top: dot.dy - markerSize / 2,
                    child: _Marker(
                      size: markerSize,
                      color: anchor.enabled
                          ? Tokens.zoneColor(anchor.zoneId, theme.colorScheme)
                          : Tokens.mutedZoneColor(theme.colorScheme),
                      enabled: anchor.enabled,
                      label: anchor.label,
                      onTap: () => onZone(anchor.zoneId),
                    ),
                  ),
              for (final _ZoneAnchor anchor in anchors)
                Positioned(
                  left: labelsOnLeft ? 0 : width - labelWidth,
                  top: anchor.labelY - _labelHalfHeight,
                  width: labelWidth,
                  child: _ZoneLabel(
                    text: anchor.label,
                    color: Tokens.zoneColor(anchor.zoneId, theme.colorScheme),
                    enabled: anchor.enabled,
                    alignEnd: labelsOnLeft,
                    onTap: () => onZone(anchor.zoneId),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Groups this view's hotspots by zone: several dots (left and right knee),
  /// one label.
  int _zoneCount() => hotspots.map((BodyHotspot h) => h.zoneId).toSet().length;

  List<_ZoneAnchor> _anchors(
    double figureWidth,
    double figureHeight,
    double figureLeft,
    double figureTop,
  ) {
    final Map<String, List<BodyHotspot>> byZone = <String, List<BodyHotspot>>{};
    for (final BodyHotspot spot in hotspots) {
      byZone.putIfAbsent(spot.zoneId, () => <BodyHotspot>[]).add(spot);
    }

    final List<_ZoneAnchor> anchors = <_ZoneAnchor>[];
    byZone.forEach((String zoneId, List<BodyHotspot> spots) {
      final List<Offset> dots = <Offset>[
        for (final BodyHotspot spot in spots)
          Offset(
            figureLeft + (spot.left + spot.width / 2) * figureWidth,
            figureTop + (spot.top + spot.height / 2) * figureHeight,
          ),
      ];
      final double meanY =
          dots.map((Offset d) => d.dy).reduce((double a, double b) => a + b) /
          dots.length;
      anchors.add(
        _ZoneAnchor(
          zoneId: zoneId,
          label: zoneLabels[zoneId] ?? zoneId,
          enabled: zonesWithContent.contains(zoneId),
          dots: dots,
          anchorY: meanY,
          labelY: meanY,
        ),
      );
    });
    anchors.sort(
      (_ZoneAnchor a, _ZoneAnchor b) => a.anchorY.compareTo(b.anchorY),
    );
    return anchors;
  }

  /// Pushes labels apart so two zones at a similar height stay readable.
  static void _spreadLabels(List<_ZoneAnchor> anchors, double height) {
    for (int i = 1; i < anchors.length; i++) {
      final double minY = anchors[i - 1].labelY + _labelSpacing;
      if (anchors[i].labelY < minY) {
        anchors[i].labelY = minY;
      }
    }
    // If the pass overflowed the bottom, pull the tail back up.
    final double overflow = anchors.isEmpty
        ? 0
        : anchors.last.labelY - (height - _labelHalfHeight);
    if (overflow > 0) {
      for (int i = anchors.length - 1; i >= 0; i--) {
        anchors[i].labelY -= overflow;
        if (i > 0 &&
            anchors[i].labelY - anchors[i - 1].labelY >= _labelSpacing) {
          break;
        }
      }
    }
  }
}

class _ZoneAnchor {
  _ZoneAnchor({
    required this.zoneId,
    required this.label,
    required this.enabled,
    required this.dots,
    required this.anchorY,
    required this.labelY,
  });

  final String zoneId;
  final String label;
  final bool enabled;
  final List<Offset> dots;

  /// Vertical centre of the zone's markers.
  final double anchorY;

  /// Where the label ended up after collision spreading.
  double labelY;
}

class _LeaderLinePainter extends CustomPainter {
  _LeaderLinePainter({
    required this.anchors,
    required this.labelsOnLeft,
    required this.labelEdge,
    required this.scheme,
    required this.zonesWithContent,
  });

  final List<_ZoneAnchor> anchors;
  final bool labelsOnLeft;
  final double labelEdge;
  final ColorScheme scheme;
  final Set<String> zonesWithContent;

  @override
  void paint(Canvas canvas, Size size) {
    for (final _ZoneAnchor anchor in anchors) {
      if (anchor.dots.isEmpty) continue;
      // Link the label to the nearest dot, which keeps lines from crossing.
      final Offset target = labelsOnLeft
          ? anchor.dots.reduce((Offset a, Offset b) => a.dx <= b.dx ? a : b)
          : anchor.dots.reduce((Offset a, Offset b) => a.dx >= b.dx ? a : b);

      final Paint paint = Paint()
        ..color = anchor.enabled
            ? Tokens.zoneColor(anchor.zoneId, scheme).withValues(alpha: 0.75)
            : scheme.outlineVariant
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      final Offset start = Offset(labelEdge, anchor.labelY);
      final Path path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(target.dx, target.dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_LeaderLinePainter oldDelegate) => true;
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.size,
    required this.color,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final double size;
  final Color color;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).colorScheme.surface,
              width: 1.5,
            ),
            boxShadow: enabled ? Tokens.glow(color) : null,
          ),
        ),
      ),
    );
  }
}

class _ZoneLabel extends StatelessWidget {
  const _ZoneLabel({
    required this.text,
    required this.color,
    required this.enabled,
    required this.alignEnd,
    required this.onTap,
  });

  final String text;
  final Color color;
  final bool enabled;
  final bool alignEnd;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Align(
      alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
      child: Material(
        color: enabled
            ? color.withValues(alpha: 0.14)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(Tokens.chipRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(Tokens.chipRadius),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: enabled
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.outline,
                fontWeight: enabled ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.view});

  final String view;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return Image.asset(
      'assets/body-map/$view.png',
      fit: BoxFit.contain,
      semanticLabel: t(
        view == 'front' ? 'app.body_map.view_front' : 'app.body_map.view_back',
      ),
      // Artwork is still to be produced (docs/generated/IMAGE_BRIEFS.md);
      // a neutral silhouette keeps the screen usable meanwhile.
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          CustomPaint(
            painter: _SilhouettePainter(
              Tokens.figureColor(theme.colorScheme),
              back: view == 'back',
            ),
          ),
    );
  }
}

/// Deliberately simple: a neutral shape, not an anatomical poster
/// (docs/VISUAL_STYLE_GUIDE.md 12).
class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.color, {required this.back});

  final Color color;
  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final double w = size.width;
    final double h = size.height;

    void rounded(
      double left,
      double top,
      double right,
      double bottom,
      double radius,
    ) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(left * w, top * h, right * w, bottom * h),
          Radius.circular(radius),
        ),
        paint,
      );
    }

    canvas.drawCircle(Offset(w * 0.5, h * 0.065), w * 0.105, paint);
    rounded(0.46, 0.11, 0.54, 0.155, 6); // neck
    rounded(0.31, 0.15, 0.69, 0.30, 22); // chest / upper back
    rounded(0.33, 0.29, 0.67, 0.46, 20); // waist / hips
    rounded(0.19, 0.17, 0.31, 0.50, 14); // arm
    rounded(0.69, 0.17, 0.81, 0.50, 14); // arm
    rounded(0.36, 0.44, 0.48, 0.72, 16); // thigh
    rounded(0.52, 0.44, 0.64, 0.72, 16); // thigh
    rounded(0.37, 0.70, 0.47, 0.94, 12); // lower leg
    rounded(0.53, 0.70, 0.63, 0.94, 12); // lower leg
    rounded(0.35, 0.93, 0.48, 0.99, 6); // foot
    rounded(0.52, 0.93, 0.65, 0.99, 6); // foot
  }

  @override
  bool shouldRepaint(_SilhouettePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.back != back;
}

class _SituationTile extends StatelessWidget {
  const _SituationTile({
    required this.collection,
    required this.count,
    required this.onTap,
  });

  final ExerciseCollection collection;
  final int count;
  final VoidCallback onTap;

  static const Map<String, IconData> _icons = <String, IconData>{
    'computer_break': Icons.desktop_windows_outlined,
    'after_sitting': Icons.chair_outlined,
    'bed_basic': Icons.bed_outlined,
    'bed_legs': Icons.airline_seat_flat_outlined,
    'eyes_basic': Icons.visibility_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ready = count > 0;

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(Tokens.cardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(Tokens.cardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: <Widget>[
              Icon(
                _icons[collection.id] ?? Icons.self_improvement,
                color: ready
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  collection.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: ready
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
