# HOME_SCREEN_REPOSITORY_PACK_v1

This package contains the complete repository skeleton for the approved Home / Body Map screen.

## Production assets

### Body artwork
- `assets/ui/home/body/body_front.png`
- `assets/ui/home/body/body_back_mini.png`

### Card icons
- `assets/ui/home/cards/icon_body.svg`
- `assets/ui/home/cards/icon_eyes.svg`
- `assets/ui/home/cards/icon_morning.svg`
- `assets/ui/home/cards/icon_sitting.svg`

The card backgrounds and all card text must be rendered in Flutter.
Do not use the reference card PNGs as production buttons.

## Configuration
- `data/ui/home/home_screen.yaml`
- `data/ui/body_map/body_hotspots.yaml`

## Localization
- `lib/l10n/app_uk.arb`
- `lib/l10n/app_en.arb`
- `lib/l10n/app_pl.arb`

Priority:
1. manually selected app language;
2. supported device language;
3. fallback locale.

## Design references
- `docs/ui/home/reference/HOME_SCREEN_REFERENCE.png`
- `docs/ui/home/reference/card_*_reference.png`

Reference images are for design comparison only and must not be used as complete runtime UI.

## Documentation
- `docs/ui/home/HOME_SCREEN_REPOSITORY_BRIEF.md`
- `docs/ui/home/HOME_SCREEN_LAYOUT_SPEC.md`

## Flutter registration
Use `pubspec_assets_snippet.yaml` as the asset-registration reference.

## Important
Hotspot coordinates are normalized and are an initial draft. They must be visually tuned after the final body images are displayed at the exact Flutter layout size.
