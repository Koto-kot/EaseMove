# HOME SCREEN LAYOUT SPEC — v1

## Approved structure

1. Top controls:
   - menu left
   - settings right
   - reserved title + subtitle zone in center

2. Body Map:
   - large front figure visually centered
   - smaller back figure to the right
   - hotspots are Flutter overlay controls, not baked into artwork

3. Main sections:
   - 2×2 grid
   - Body
   - Eyes
   - Morning
   - Sitting

4. No bottom navigation in MVP.
5. No Relax card in MVP.
6. No motivational bottom slogan in MVP.

## Responsive priority

When screen height is limited:
1. reduce vertical whitespace,
2. reduce Body Map height slightly,
3. preserve readable card text and accessible touch targets.

The front figure must remain visually centered even when the mini-back figure is present.
