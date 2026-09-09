/// Body map home screen.
///
/// Hotspots are normalized 0..1 and scaled against the artwork's *rendered*
/// bounds, never hard-coded in the widget (docs/BODY_MAP_SPEC.md,
/// docs/TECHNICAL_SPEC.md 23).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/localization/app_strings.dart';
import '../../data/content_bundle.dart';
import '../../data/exercise_repository.dart';
import '../exercise_catalog/catalog_screen.dart';

class BodyMapScreen extends ConsumerStatefulWidget {
  const BodyMapScreen({super.key});

  @override
  ConsumerState<BodyMapScreen> createState() => _BodyMapScreenState();
}

class _BodyMapScreenState extends ConsumerState<BodyMapScreen> {
  static const double _artworkAspectRatio = 0.42;

  String _view = 'front';

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final AsyncValue<ExerciseRepository> repository = ref.watch(
      exerciseRepositoryProvider,
    );

    return Scaffold(
      appBar: AppBar(title: Text(t('app.nav.body'))),
      body: repository.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) =>
            Center(child: Text(t('app.common.error'))),
        data: (ExerciseRepository repo) => _content(context, t, repo),
      ),
    );
  }

  Widget _content(BuildContext context, AppStrings t, ExerciseRepository repo) {
    final ThemeData theme = Theme.of(context);
    final List<BodyHotspot> hotspots = repo.bundle.hotspotsForView(_view);
    final Set<String> zonesWithContent = <String>{
      for (final ExerciseCollection collection
          in repo.nonEmptyZoneCollections())
        if (collection.primaryZone != null) collection.primaryZone!,
    };

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text(t('app.body_map.title'), style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(t('app.body_map.hint'), style: theme.textTheme.bodyMedium),
        const SizedBox(height: 16),
        Center(
          child: SegmentedButton<String>(
            segments: <ButtonSegment<String>>[
              ButtonSegment<String>(
                value: 'front',
                label: Text(t('app.body_map.view_front')),
              ),
              ButtonSegment<String>(
                value: 'back',
                label: Text(t('app.body_map.view_back')),
              ),
            ],
            selected: <String>{_view},
            onSelectionChanged: (Set<String> selection) =>
                setState(() => _view = selection.first),
          ),
        ),
        const SizedBox(height: 16),
        // Height-driven, not width-driven: a full-body figure is much taller
        // than it is wide, so letting the width dictate the size would push
        // the zone list far below the fold.
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.55,
          child: Center(
            child: AspectRatio(
              aspectRatio: _artworkAspectRatio,
              child: _BodyMapArtwork(
                view: _view,
                hotspots: hotspots,
                zonesWithContent: zonesWithContent,
                onTap: (BodyHotspot spot) => _openZone(context, t, repo, spot),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Zone list as an accessible, non-visual path to the same content.
        for (final ExerciseCollection collection
            in repo.nonEmptyZoneCollections())
          ListTile(
            title: Text(collection.title),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openCollection(context, collection),
          ),
        const SizedBox(height: 24),
        Text(t('app.disclaimer'), style: theme.textTheme.bodySmall),
      ],
    );
  }

  void _openZone(
    BuildContext context,
    AppStrings t,
    ExerciseRepository repo,
    BodyHotspot spot,
  ) {
    final String? collectionId = spot.collectionId;
    final ExerciseCollection? collection = collectionId == null
        ? null
        : repo.bundle.collectionById(collectionId);
    if (collection == null) return;
    if (repo.byCollection(collection.id).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${collection.title} — ${t('app.catalog.empty')}'),
        ),
      );
      return;
    }
    _openCollection(context, collection);
  }

  void _openCollection(BuildContext context, ExerciseCollection collection) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            CatalogScreen(collectionId: collection.id),
      ),
    );
  }
}

class _BodyMapArtwork extends StatelessWidget {
  const _BodyMapArtwork({
    required this.view,
    required this.hotspots,
    required this.zonesWithContent,
    required this.onTap,
  });

  final String view;
  final List<BodyHotspot> hotspots;
  final Set<String> zonesWithContent;
  final void Function(BodyHotspot) onTap;

  @override
  Widget build(BuildContext context) {
    final AppStrings t = AppStrings.of(context);
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: Image.asset(
                'assets/body-map/$view.png',
                fit: BoxFit.contain,
                semanticLabel: t('app.body_map.title'),
                // Artwork is still to be produced (docs/ASSET_PIPELINE.md);
                // a neutral silhouette keeps the screen usable meanwhile.
                errorBuilder:
                    (BuildContext context, Object error, StackTrace? stack) =>
                        CustomPaint(
                          painter: _SilhouettePainter(
                            theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
              ),
            ),
            for (final BodyHotspot spot in hotspots)
              Positioned(
                left: spot.left * width,
                top: spot.top * height,
                width: spot.width * width,
                height: spot.height * height,
                child: _HotspotTarget(
                  spot: spot,
                  enabled: zonesWithContent.contains(spot.zoneId),
                  label: t(spot.labelKey),
                  onTap: () => onTap(spot),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HotspotTarget extends StatelessWidget {
  const _HotspotTarget({
    required this.spot,
    required this.enabled,
    required this.label,
    required this.onTap,
  });

  final BodyHotspot spot;
  final bool enabled;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: enabled
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: FittedBox(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: enabled
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.outline,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Deliberately simple: a neutral shape, not an anatomical poster
/// (docs/VISUAL_STYLE_GUIDE.md 12).
class _SilhouettePainter extends CustomPainter {
  _SilhouettePainter(this.color);

  final Color color;

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

    canvas.drawCircle(Offset(w * 0.5, h * 0.07), w * 0.11, paint);
    rounded(0.46, 0.12, 0.54, 0.17, 8); // neck
    rounded(0.30, 0.16, 0.70, 0.46, 24); // torso
    rounded(0.18, 0.18, 0.30, 0.52, 16); // left arm
    rounded(0.70, 0.18, 0.82, 0.52, 16); // right arm
    rounded(0.36, 0.44, 0.48, 0.78, 18); // left leg
    rounded(0.52, 0.44, 0.64, 0.78, 18); // right leg
    rounded(0.34, 0.76, 0.48, 0.98, 14); // left lower leg
    rounded(0.52, 0.76, 0.66, 0.98, 14); // right lower leg
  }

  @override
  bool shouldRepaint(_SilhouettePainter oldDelegate) =>
      oldDelegate.color != color;
}
