# Localization

## Default behavior

1. При першому запуску застосунок використовує найкращу підтримувану app/device language.
2. Якщо мова не підтримується — fallback `en`.
3. Користувач може вручну змінити мову.
4. Країна App Store/Google Play **не визначає** мову застосунку.

## UI strings

У коді не повинно бути hard-coded user-visible strings.

Погано:
`Text("Старт")`

Добре:
`Text(t("common.control.start"))`

## Exercise strings

Exercise містить keys і/або authoring locale:

- title;
- card description;
- instructions;
- safety;
- voice text.

## Interface language vs voice language

За замовчуванням однакові.

Pro може дозволяти:
- Interface: Українська
- Voice: English

## Common keys

Див. `data/localization/uk/common.yaml`.

## New language checklist

1. Додати language metadata.
2. Перекласти common UI.
3. Перекласти exercise content.
4. Додати voice pack або TTS fallback.
5. Перевірити довгі написи на малих екранах.
6. Перевірити accessibility labels.
7. Не змінювати exercise IDs/sequence.
