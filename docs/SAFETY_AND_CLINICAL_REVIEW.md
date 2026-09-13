# Safety & Clinical Review

## Статус вправ

Allowed:
- `draft`
- `pending_review`
- `approved`
- `retired`

## Що показує застосунок

**Застосунок показує всю бібліотеку, незалежно від статусу.** Шлюз, який
пропускав лише `approved`, знято на рішення власника продукту (DECISIONS 88):
жодна вправа ще не має `approved`, тож поза development-збіркою застосунок був
порожній.

Статус нікуди не дівся. Вправа без `approved` показує напис «Вправа ще не
пройшла клінічне рев'ю» на своєму екрані та позначку на картці, а
`clinical.safety.requires_professional_review` лишається в даних як перелік
того, що має перевірити фахівець.

## Що повинен перевірити фахівець

Для кожної вправи:
- точність опису;
- стартову позицію;
- діапазон руху;
- repetitions/sets/hold;
- tempo;
- variants;
- equipment/environment;
- safety text;
- stop conditions;
- contraindications;
- animation frames;
- voice cues;
- Pro adaptive ranges.

## Джерела

Джерело не замінює клінічний review.
Source metadata потрібна для traceability.

## Заборонені автоматичні зміни

До окремого approval:
- AI не змінює exercise mechanics;
- Pro не збільшує repetitions;
- Pro не збільшує hold;
- Pro не змінює tempo;
- app не вимірює joint angle і не призначає target angle;
- app не робить діагноз.

## Safety language

Уникати формулювань:
- «лікує»;
- «виліковує»;
- «гарантовано знімає біль».

Використовувати нейтральні:
- рухливість;
- легкий рух;
- комфортний діапазон;
- зупиніться при незвичних симптомах.
