# UX Flow

## A. Browse → exercise

`Home/Body → Zone or Situation → Exercise cards → Exercise detail/player`

Картки великі, приблизно 3 у viewport, далі vertical scroll.

## B. Manual start

`Exercise selected → Start → Prep countdown 5 → Active`

Під час countdown:
- велика стартова поза;
- назва вправи;
- 5 → 4 → 3 → 2 → 1;
- після 0 запускаються animation/timer/music/voice.

## C. Active

На екрані:
- велика анімація;
- elapsed time;
- progress;
- за потреби repetitions/side;
- Previous;
- Start/Pause;
- Stop;
- Next.

## D. Pause

Pause:
- freeze exercise timer;
- freeze sequence;
- pause music;
- resume from same phase/repetition.

## E. Stop early

Stop:
- дозволений завжди;
- не показувати failure;
- зберегти фактичний час;
- зберегти completed repetitions/side, якщо модель вправи це підтримує;
- early stop не формулювати як «невдача».

Політика, чи early-stop збільшує lifetime exercise counter, має бути глобальною і конфігурованою.

## F. Normal completion

`Exercise complete → tracking → +1 → next preview → rest countdown 10`

Під час 10 секунд:
- наступна вправа вже видима;
- повний відпочинок;
- немає `Start now / Skip rest`.

На 0:
- next exercise start automatically.

## G. Manual change during auto-rest

Previous або Next:
- cancel rest countdown;
- cancel auto-mode;
- показати вибрану вправу;
- користувач має натиснути Start;
- після Start знову 5 секунд prep.

## H. Navigation away

Вихід з exercise flow:
- зупиняє autoplay;
- очищає active timers;
- зберігає допустиму статистику;
- повертає у browse state.

## I. Pro locked

`Tap locked PRO feature → contextual paywall → subscribe/restore/close`

У test/development entitlement bypassed feature flag.
