/// The interactive body map: one large front figure, one small back figure,
/// and a hotspot overlay that is never baked into the artwork
/// (docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 4-5).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/design_tokens.dart';
import '../../../data/content_bundle.dart';

typedef HotspotTap = void Function(BodyHotspot spot);

class BodyMapView extends StatefulWidget {
  const BodyMapView({
    required this.config,
    required this.zoneTitles,
    required this.onZoneSelected,
    super.key,
  });

  final BodyMapConfig config;

  /// Zone id to its short title, for the semantic label of each dot. Paired
  /// dots share the label, so a screen reader announces "Коліна" for either
  /// knee (brief 14).
  final Map<String, String> zoneTitles;

  /// Called after the pulse, not on touch-down: the zone lights up first, then
  /// navigation happens (brief 5.2).
  final HotspotTap onZoneSelected;

  /// The back figure is secondary, so it renders at this share of the front
  /// figure's height.
  static const double miniScale = 0.46;

  @override
  State<BodyMapView> createState() => _BodyMapViewState();
}

class _BodyMapViewState extends State<BodyMapView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: widget.config.rules.pulseDuration,
  );

  /// Which dots are lit while the pulse runs.
  Set<String> _highlighted = const <String>{};

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _select(BodyHotspot spot) async {
    if (_pulse.isAnimating) return;
    setState(() {
      _highlighted = widget.config.rules.pairedHighlight
          ? spot.highlightTargets.toSet()
          : <String>{spot.id};
    });
    try {
      await _pulse.forward(from: 0);
    } on TickerCanceled {
      return;
    }
    if (!mounted) return;
    setState(() => _highlighted = const <String>{});
    widget.onZoneSelected(spot);
  }

  @override
  Widget build(BuildContext context) {
    final BodyMapArtwork? front = widget.config.artwork['front'];
    final BodyMapArtwork? back = widget.config.artwork['back_mini'];
    if (front == null) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // The figure's height drives everything: it must never be cropped,
        // and the front figure stays centred in the full width even though
        // the mini sits to the right (brief 13). Capping its width at half
        // the box is what keeps the two figures from overlapping when the box
        // is tall and narrow.
        final double frontHeight = math.min(
          constraints.maxHeight,
          constraints.maxWidth * 0.52 / front.aspectRatio,
        );
        final double frontWidth = frontHeight * front.aspectRatio;
        final double miniHeight = frontHeight * BodyMapView.miniScale;

        return Stack(
          children: <Widget>[
            Align(
              child: SizedBox(
                width: math.min(frontWidth, constraints.maxWidth),
                height: frontHeight,
                child: _Figure(
                  artwork: front,
                  hotspots: widget.config.forView('front'),
                  rules: widget.config.rules,
                  zoneTitles: widget.zoneTitles,
                  highlighted: _highlighted,
                  pulse: _pulse,
                  onSelected: _select,
                  scale: 1,
                ),
              ),
            ),
            if (back != null)
              Positioned(
                right: 0,
                top: 0,
                child: SizedBox(
                  width: miniHeight * back.aspectRatio,
                  height: miniHeight,
                  child: _Figure(
                    artwork: back,
                    hotspots: widget.config.forView('back_mini'),
                    rules: widget.config.rules,
                    zoneTitles: widget.zoneTitles,
                    highlighted: _highlighted,
                    pulse: _pulse,
                    onSelected: _select,
                    scale: BodyMapView.miniScale,
                    framed: true,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.artwork,
    required this.hotspots,
    required this.rules,
    required this.zoneTitles,
    required this.highlighted,
    required this.pulse,
    required this.onSelected,
    required this.scale,
    this.framed = false,
  });

  final BodyMapArtwork artwork;
  final List<BodyHotspot> hotspots;
  final BodyMapRules rules;
  final Map<String, String> zoneTitles;
  final Set<String> highlighted;
  final Animation<double> pulse;
  final HotspotTap onSelected;

  /// Dots shrink with the figure, so the mini map does not look studded.
  final double scale;

  /// The mini figure sits in its own card in the approved layout.
  final bool framed;

  /// Nearest centre wins. Rect hit-testing would hand a tap between the knee
  /// and the calf to whichever dot happened to be painted last.
  void _handleTap(Offset local, Size size) {
    BodyHotspot? best;
    double bestDistance = double.infinity;
    for (final BodyHotspot spot in hotspots) {
      final double dx = spot.cx * size.width - local.dx;
      final double dy = spot.cy * size.height - local.dy;
      final double distance = math.sqrt(dx * dx + dy * dy);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = spot;
      }
    }
    if (best != null && bestDistance <= rules.tapMaxDistance * scale) {
      onSelected(best);
    }
  }

  @override
  Widget build(BuildContext context) {
    final BorderRadius radius = BorderRadius.circular(Tokens.cardRadius);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Tokens.bodyMapPanel,
        borderRadius: radius,
        border: framed
            ? Border.all(color: Tokens.hotspot.withValues(alpha: 0.18))
            : null,
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size size = constraints.biggest;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (TapUpDetails details) =>
                _handleTap(details.localPosition, size),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // Decorative: the dots carry the labels, so the artwork must
                // not repeat them to a screen reader (brief 14).
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: radius,
                    child: ExcludeSemantics(
                      child: _CroppedArtwork(artwork: artwork, box: size),
                    ),
                  ),
                ),
                for (final BodyHotspot spot in hotspots)
                  Positioned(
                    left: spot.cx * size.width - rules.haloDiameter * scale / 2,
                    top: spot.cy * size.height - rules.haloDiameter * scale / 2,
                    child: _Hotspot(
                      key: ValueKey<String>('hotspot.${spot.id}'),
                      label: zoneTitles[spot.zoneId] ?? spot.zoneId,
                      rules: rules,
                      scale: scale,
                      lit: highlighted.contains(spot.id),
                      pulse: pulse,
                      onActivate: () => onSelected(spot),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Draws only the part of the PNG the figure occupies, scaled to fill the box.
///
/// Both delivered artworks carry wide empty margins; fitting the whole file
/// would leave the figure at under half the available width.
class _CroppedArtwork extends StatelessWidget {
  const _CroppedArtwork({required this.artwork, required this.box});

  final BodyMapArtwork artwork;
  final Size box;

  @override
  Widget build(BuildContext context) {
    final double scale =
        box.height / (artwork.heightPx * artwork.contentHeight);
    final double fullWidth = artwork.widthPx * scale;
    final double fullHeight = artwork.heightPx * scale;

    return OverflowBox(
      alignment: Alignment.topLeft,
      maxWidth: double.infinity,
      maxHeight: double.infinity,
      child: Transform.translate(
        offset: Offset(
          -artwork.contentLeft * fullWidth,
          -artwork.contentTop * fullHeight,
        ),
        child: Image.asset(
          artwork.asset,
          width: fullWidth,
          height: fullHeight,
          fit: BoxFit.fill,
          filterQuality: FilterQuality.medium,
          errorBuilder: (BuildContext context, Object error, StackTrace? s) =>
              const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A bright core inside a soft halo, which brightens and swells while the
/// zone pulses (brief 5.1-5.2).
class _Hotspot extends StatelessWidget {
  const _Hotspot({
    required this.label,
    super.key,
    required this.rules,
    required this.scale,
    required this.lit,
    required this.pulse,
    required this.onActivate,
  });

  final String label;
  final BodyMapRules rules;
  final double scale;
  final bool lit;
  final Animation<double> pulse;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final double halo = rules.haloDiameter * scale;
    final double core = rules.coreDiameter * scale;

    return Semantics(
      button: true,
      label: label,
      onTap: onActivate,
      // The tap itself is resolved by the figure below, by nearest centre.
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: pulse,
          builder: (BuildContext context, Widget? child) {
            // A half-sine, so the pulse swells and settles inside one run.
            final double t = lit ? math.sin(pulse.value * math.pi) : 0;
            return SizedBox(
              width: halo,
              height: halo,
              child: Center(
                child: Container(
                  width: halo * (0.72 + 0.28 * t),
                  height: halo * (0.72 + 0.28 * t),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Tokens.hotspot.withValues(alpha: 0.16 + 0.24 * t),
                  ),
                  child: Center(
                    child: Container(
                      width: core * (1 - 0.12 * t),
                      height: core * (1 - 0.12 * t),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Tokens.hotspot,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: math.max(1, 2 * scale),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
