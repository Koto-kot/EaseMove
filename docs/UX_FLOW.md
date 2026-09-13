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

`Exercise selected → Start → Setup line → «Починаємо вправу через п'ять» → 4·3·2·1·0 → Active`

Усе це йде одним голосовим каналом, тож кожна частина чекає попередню — разом
не чути жодної (DECISIONS 74).

**Цифра 5 світиться від першої миті** — ще поки звучить репліка про початкове
положення. Відлік уже почався, просто його першу секунду промовляє окрема
репліка «Починаємо вправу через п'ять», а не саме число.

1. Репліка вправи про початкове положення — `timing.prep_intro_ms`, тобто
   довжина її запису (довшої з двох мов) плюс коротка пауза. Нуль означає, що
   чекати нема чого.
2. «Починаємо вправу через п'ять» — спільна репліка,
   `timing.countdown_opening_ms` (data/audio/common_lines.yaml).
3. Далі числа по секунді: 4 → 3 → 2 → 1 → 0. Нуль лунає в ту саму мить, коли
   починається рух, і одразу за ним іде перша команда вправи — саме в такому
   порядку.

На екрані весь цей час: велика стартова поза, назва вправи, «Починаємо через»
і число. Пауза заморожує будь-яку з трьох частин.

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
