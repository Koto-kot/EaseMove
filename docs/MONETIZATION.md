# Monetization

## Model

Free + Pro.

Free залишається реально корисним.
Pro продає персоналізацію, додаткові можливості й комфорт.

## Proposed pricing — provisional

Для майбутнього A/B/store validation:

- Monthly: орієнтир €4.99
- Yearly: орієнтир €29.99
- Lifetime: орієнтир €49.99–59.99

Це не фінальні ціни. Store price tiers і локальні ціни задаються перед релізом.

## Paywall principles

- не показувати paywall одразу при першому відкритті;
- Free бачить Pro-функції;
- tap locked function → contextual paywall;
- чітко пояснювати, що відкривається;
- показувати restore purchase;
- не маскувати auto-renew;
- якщо є lifetime, чітко відрізняти його від subscription.

## Test mode

Billing не блокує розробку:
`pro.access_mode = unlocked`.

Перед release:
`pro.access_mode = paywall`.
