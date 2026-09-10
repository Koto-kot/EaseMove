/// One of the four cards under the body map.
///
/// Composed in Flutter from an icon asset plus localized text — never a raster
/// button with the words baked in, so the copy can change, translate and scale
/// with the system font (docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md 7).
library;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/design_tokens.dart';
import '../../../data/content_bundle.dart';

class HomeSectionCard extends StatelessWidget {
  const HomeSectionCard({
    required this.section,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final HomeSection section;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius = BorderRadius.circular(22);

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: ExcludeSemantics(
        child: Material(
          color: Tokens.cardTint(section.tint, scheme),
          borderRadius: radius,
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(
                  color: Tokens.cardBorder(section.tint, scheme),
                ),
              ),
              child: Row(
                children: <Widget>[
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: SvgPicture.asset(
                      section.icon,
                      // A missing icon must not take the card down with it.
                      placeholderBuilder: (BuildContext context) =>
                          const SizedBox.shrink(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Flexible(
                          child: Text(
                            subtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
