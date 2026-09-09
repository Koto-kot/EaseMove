# Feature Flags

## Мета

Розробка й тестування не повинні залежати від реальної оплати.
Водночас production Free-користувач має бачити Pro, але не мати доступу.

## Canonical flags

Див. `config/feature_flags.yaml`.

### Development / test

```yaml
pro:
  visible_to_free: true
  access_mode: unlocked
```

Усі Pro-функції працюють без billing entitlement.

### Production

```yaml
pro:
  visible_to_free: true
  access_mode: paywall
```

Free бачить Pro-функції, але натискання перевіряє entitlement.

## Access modes

- `unlocked` — усе Pro відкрите.
- `paywall` — потрібен entitlement.
- `tester` — Pro лише tester allowlist/debug entitlement.
- `disabled` — emergency mode; не використовувати як звичайну Free-стратегію.

## Незавершені функції

Кожна велика функція може мати окремий flag:
- `pro_today_plan`
- `pro_advanced_stats`
- `pro_audio_customization`
- `pro_smart_reminders`
- `pro_ai_assistant`

Це відрізняється від entitlement:
**visibility flag визначає, чи функція існує в поточній збірці; entitlement визначає доступ.**

## Clinical content

Development:
`show_pending_review: true`

Production:
`approved_only: true`

## Developer menu

Тільки non-production build:
- Pro mode
- Reset stats
- Reset profile
- Skip countdown
- Timing multiplier
- Show exercise IDs
- Show pending clinical content
- Change locale
