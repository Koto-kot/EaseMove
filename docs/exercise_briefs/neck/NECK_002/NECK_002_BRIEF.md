# NECK_002 — Поворот голови вліво — вправо

**Document type:** Exercise Production Brief  
**Exercise ID:** `NECK_002`  
**Slug:** `seated_head_turn_left_right`  
**Primary zone:** `neck`  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** starter / easy  
**Position:** seated  
**Movement type:** gentle cervical rotation  
**Framing:** `FULL_SAFE` + `UPPER_SAFE`  
**Schema:** Exercise Schema v1.3

---

## 1. Суть вправи

Користувач сидить рівно і плавно повертає голову вліво та вправо, щоразу повертаючись у центр. Рух спокійний, без ривків і без нахилу голови догори або донизу.

Це базова вправа на м’яку рухливість шиї.

---

## 2. Стартове положення

- сісти рівно на стілець;
- стопи стійко на підлозі;
- плечі розслаблені;
- погляд прямо;
- руки на стегнах.

---

## 3. Рух

### Phase A — turn left
Плавно повернути голову вліво.

### Phase B — turn right
Плавно повернути голову вправо.

### Return logic
Між поворотами голова проходить через нейтральне центральне положення.

### Canonical cycle
`center → left → center → right → center`

---

## 4. Timing

- preparation countdown: `5 s`
- default active duration: `60 s`
- presets: `60 / 120 / 180 / 300 s`
- suggested cycle: approximately `5–6 s`
- completion condition: elapsed active time
- pause freezes timer and animation
- Stop is available at any time
- normal completion → `10 s` rest before the next exercise

---

## 5. Framing

Use:
- `setup_full_safe.png` for the initial whole-body seated position;
- `UPPER_SAFE` for motion frames to make head rotation easier to read.

Mandatory:
- head fully visible;
- neck fully visible;
- shoulders visible;
- motion frames must use the same crop and scale;
- direction must be unambiguous: one frame left, one frame right.

---

## 6. Production images

- `setup_full_safe.png`
- `motion_01_head_turn_left_upper_safe.png`
- `motion_02_head_turn_right_upper_safe.png`
- `preview.png`

Folder:
`assets/exercises/NECK_002/images/`

---

## 7. Audio

Exercise-specific Ukrainian cues:

`audio/uk/exercises/NECK_002/setup.m4a`  
Suggested text: `Сядьте рівно. Розслабте плечі. Дивіться прямо.`

`audio/uk/exercises/NECK_002/start_movement.m4a`  
Suggested text: `Плавно поверніть голову вліво. Поверніться у центр. Потім плавно поверніть голову вправо.`

Reusable common cues:
- `audio/uk/common/halfway.m4a` — `Половину виконано.`
- `audio/uk/common/completed.m4a` — `Готово.`

---

## 8. Safety / usability cues

- не робити різких поворотів;
- не закидати голову назад;
- не нахиляти голову під час повороту;
- плечі залишаються розслабленими;
- зупинитися, якщо з’являється біль або виражений дискомфорт.

---

## 9. QA checklist

- [ ] Setup frame is full body and readable.
- [ ] Motion frames are clearly different left vs right.
- [ ] Runtime images contain no text / arrows / UI / watermark.
- [ ] Visual brief sheet includes small directional arrows.
- [ ] YAML paths match the real files.
