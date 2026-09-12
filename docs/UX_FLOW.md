# UX Flow

## A. Browse → exercise

`Home/Body → Zone or Situation → Exercise cards → Exercise detail/player`

Картки великі, приблизно 3 у viewport, далі vertical scroll.

## A1. Екран вправи до старту

Модель, призначення вправи, попередження про безпеку — і два способи взяти
інструкцію, поруч один з одним:

- «Прослухати інструкцію» — звучить `spokenInstructions` (призначення,
  початкове положення, кроки), текст на екрані не з'являється. Поки звучить,
  та сама кнопка читає «Зупинити».
- «Прочитати інструкцію» — модель ховається, а на її місце стають початкове
  положення, пронумеровані кроки, «Зверніть увагу» і «Безпека»; нічого не
  звучить. Та сама кнопка згортає текст і повертає модель.

Жодне з двох не відбувається саме по собі, і разом вони не показуються:
текст під моделлю ламав композицію екрана, а затиснутий у залишок екрана
погано читався (DECISIONS 69). Коли голос вимкнено в налаштуваннях, кнопки
«Прослухати» немає взагалі, і «Прочитати» займає весь рядок.

## B. Manual start

`Exercise selected → Start → Setup line → Prep countdown 5 → Active`

Після «Старт» спершу звучить репліка про початкове положення — повністю, без
цифр поверх неї. Відлік починається лише коли вона закінчилася: обидві йдуть
одним голосовим каналом, і разом не чути жодної (DECISIONS 74).

Скільки чекати — це дані: `timing.prep_intro_ms` кожної вправи дорівнює
довжині її записаної репліки (довшої з двох мов) плюс коротка пауза. Нуль
означає, що чекати нема чого, і відлік стартує одразу.

Поки звучить репліка:
- велика стартова поза;
- назва вправи;
- цифр і напису «Починаємо через» ще немає.

Далі відлік:
- 5 → 4 → 3 → 2 → 1;
- після 0 запускаються animation/timer/music/voice.

Пауза під час репліки заморожує і її.

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
