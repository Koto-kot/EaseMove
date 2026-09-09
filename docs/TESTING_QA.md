# Testing & QA

## Content validation

`scripts/validate_library.py`

Перевіряє:
- YAML parse;
- JSON Schema;
- duplicate exercise IDs;
- duplicate slugs;
- basic collection presence;
- clinical status.

## Manual Exercise QA

- назва відповідає руху;
- frame order правильний;
- voice cue у правильний момент;
- Pause/Resume не перескакує phase;
- repetition increments у правильній точці;
- side switch автоматичний там, де треба;
- Stop працює завжди;
- next preview правильний;
- 10-sec rest;
- manual Previous/Next cancels auto;
- localization overflow;
- accessibility.

## Fast developer testing

Developer menu:
- timing multiplier 0.1x;
- skip prep;
- skip rest;
- show IDs;
- force locale;
- Pro unlocked;
- show pending clinical.

Ці опції не потрапляють у production.
