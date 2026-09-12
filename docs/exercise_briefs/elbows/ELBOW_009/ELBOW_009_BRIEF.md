# ELBOW_009 — Віджимання від стіни

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_009`  
**Slug:** `wall_push_up`  
**Primary zone:** `elbows`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter  
**Position:** standing  
**Equipment / environment:** stable wall  
**Movement type:** bilateral elbow flexion / extension with wall support  
**Framing:** `FULL_SAFE`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач стоїть обличчям до стіни на комфортній відстані, ставить долоні на стіну приблизно на рівні грудей / плечей. З прямого положення рук плавно згинає лікті, наближаючи корпус до стіни, а потім плавно випрямляє руки.

Це звичайний рух без додаткового обладнання. Він використовується в застосунку як проста вправа для розділу `Лікті`.

---

## 2. Стартове положення

- стати обличчям до стіни;
- долоні поставити на стіну приблизно на рівні грудей / плечей;
- руки випрямлені, але без жорсткого блокування ліктів;
- стопи повністю на підлозі;
- корпус тримати рівно;
- вибрати таку відстань від стіни, щоб рух був комфортним.

---

## 3. Рух

### Phase A — arms extended
Руки випрямлені, долоні залишаються на стіні.

### Phase B — elbows bent
Плавно зігнути лікті та наблизити корпус до стіни без ривка.

### Return
Плавно випрямити руки і повернутися до Phase A.

### Canonical cycle
`A → B → A`

---

## 4. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested cycle: approximately `4–6 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 5. Framing

Use `FULL_SAFE`.

Mandatory:
- entire body visible;
- hands fully visible where they contact the wall;
- feet fully visible;
- do not crop through shoulders, elbows, wrists, knees or ankles;
- keep a safe margin around the body;
- Motion A and Motion B must use the same camera direction and comparable crop.

---

## 6. Production images

- `setup_full_safe.png`
- `motion_01_arms_extended_wall_full_safe.png`
- `motion_02_elbows_bent_wall_full_safe.png`
- `preview.png`

Folder:
`assets/exercises/ELBOW_009/images/`

---

## 7. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/ELBOW_009/setup.m4a`  
Suggested text: `Станьте обличчям до стіни. Поставте долоні на стіну й тримайте корпус рівно.`

`audio/uk/exercises/ELBOW_009/start_movement.m4a`  
Suggested text: `Плавно зігніть руки, наблизьтеся до стіни й випряміть руки назад.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 8. Simple safety / usability cues

- використовувати стійку вертикальну стіну;
- стопи не повинні ковзати;
- не робити різких рухів;
- не опускати голову до стіни окремо від корпусу;
- обрати комфортну відстань і амплітуду;
- зупинитися, якщо рух викликає біль.

---

## 9. QA checklist

- [ ] Стартове положення зрозуміле без тексту.
- [ ] Долоні видно повністю.
- [ ] Стопи видно повністю.
- [ ] Лікті помітно згинаються у Phase B.
- [ ] Корпус рухається як єдине ціле.
- [ ] Немає тексту, стрілок, номерів, UI або watermark у production images.
- [ ] Visual brief використовує actual production images.
- [ ] YAML paths відповідають реальним файлам.
