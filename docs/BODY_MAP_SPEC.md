# Body Map / Main Screen Specification v1.0

## 1. Призначення

Головний екран `Тіло` дозволяє користувачу вибрати зону без текстового пошуку.

Основна композиція:
- вид тіла спереду;
- вид тіла ззаду;
- великі невидимі/напівпрозорі tappable hotspots поверх ілюстрації;
- нижче або поряд можуть бути ситуаційні входи: `За комп’ютером`, `У ліжку`, `Очі`.

## 2. Візуальна модель

Body-map asset:
- спрощена доросла нейтральна фігура;
- front + back;
- не bodybuilding anatomy;
- не медична схема м’язів;
- обличчя просте, нейтральне;
- руки трохи відведені від корпусу, щоб зони плечей/ліктів/кистей не перекривались;
- ноги розставлені достатньо, щоб knees/calves/ankles/feet були окремо tappable.

## 3. Hotspot layer

Hotspots не малюються назавжди всередині картинки.
Flutter накладає окремий interaction layer з `body_hotspots.yaml`.

Це дозволяє:
- збільшити touch target без зміни картинки;
- змінити зони;
- підтримати accessibility;
- підсвітити selected/pressed zone;
- використовувати інше body image без зміни zone IDs.

## 4. Hotspot behavior

Default:
- hotspot може бути прозорим;
- при tap/press з’являється коротке підсвічування;
- tap відкриває відповідну collection.

Приклад:
`left_knee` → `body_knees`.

Ліва і права симетричні зони можуть відкривати ту саму collection.

## 5. Touch targets

Hotspot має бути більшим за точну анатомічну область.
Пріоритет — зручне натискання.

Якщо hotspots перекриваються:
1. використати priority;
2. nearest center / explicit z-order;
3. збільшувати body illustration spacing;
4. не робити крихітні touch targets.

## 6. Primary zones v1

Front/back разом підтримують:
- neck
- shoulders
- upper_back
- elbows
- wrists_hands
- lower_back
- hips
- knees
- calves
- ankles
- feet

## 7. Navigation action

Hotspot record містить:

```yaml
action:
  type: open_collection
  collection_id: body_knees
```

Body Map не містить business logic щодо списку вправ.
Він лише відкриває collection.

## 8. States

Hotspot UI state:
- idle
- pressed
- selected
- disabled (тільки якщо collection unavailable)

Locked Pro не застосовується до базових зон Body v1.

## 9. Labels

За замовчуванням labels можуть не бути постійно показані на самій фігурі, щоб не перевантажувати екран.

Accessibility:
- кожен hotspot має localized semantic label;
- screen reader може оголосити `Коліна`, `Шия`, тощо.

## 10. Responsive layout

Portrait phone:
- front/back поруч, якщо ширина дозволяє;
- або compact two-column layout.

Малі екрани:
- body map масштабується;
- hotspots масштабуються разом із rendered bounds;
- touch area не повинна ставати меншою за accessibility minimum.

Tablet:
- збільшена карта без зміни normalized coordinate data.

## 11. Data files

- `data/categories/body_zones.yaml`
- `data/categories/body_hotspots.yaml`
- `assets/body-map/README.md`
- future: `assets/body-map/body_front.svg`
- future: `assets/body-map/body_back.svg`

## 12. Acceptance criteria

- tap on neck opens `body_neck`;
- tap on either knee opens `body_knees`;
- front/back hotspots scale correctly;
- touch targets remain usable;
- pressed state visible;
- body image is not itself responsible for interaction;
- no hotspot coordinates hard-coded in Flutter widgets;
- labels come from localization;
- replacing body-map artwork does not change zone IDs.
