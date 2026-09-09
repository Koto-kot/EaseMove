/// Production frames and body-map artwork are not generated yet
/// (docs/ASSET_PIPELINE.md). Every image goes through here so a missing asset
/// degrades into a readable placeholder instead of a broken screen — and so
/// the app keeps working the moment the real PNGs land.
library;

import 'package:flutter/material.dart';

class AssetImageOrPlaceholder extends StatelessWidget {
  const AssetImageOrPlaceholder({
    required this.assetPath,
    required this.placeholderLabel,
    this.semanticLabel,
    this.caption,
    this.fit = BoxFit.contain,
    super.key,
  });

  final String? assetPath;
  final String placeholderLabel;
  final String? semanticLabel;

  /// Shown inside the placeholder — the pose description keeps the screen
  /// usable before artwork exists.
  final String? caption;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final String? path = assetPath;
    if (path == null) {
      return _Placeholder(label: placeholderLabel, caption: caption);
    }
    return Image.asset(
      path,
      fit: fit,
      semanticLabel: semanticLabel,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          _Placeholder(label: placeholderLabel, caption: caption),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.label, this.caption});

  final String label;
  final String? caption;

  /// Below this the box only has room for the icon — a card thumbnail or the
  /// small next-exercise preview.
  static const double _compactBelow = 160;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double shortestSide = constraints.biggest.shortestSide.isFinite
            ? constraints.biggest.shortestSide
            : 200;
        final bool compact = shortestSide < _compactBelow;

        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: compact
                ? Center(
                    child: Icon(
                      Icons.accessibility_new,
                      size: shortestSide * 0.45,
                      color: theme.colorScheme.outline,
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.accessibility_new,
                          size: 40,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          label,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (caption != null) ...<Widget>[
                          const SizedBox(height: 8),
                          Flexible(
                            child: Text(
                              caption!,
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
        );
      },
    );
  }
}
