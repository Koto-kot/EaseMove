# ELBOW_008 — Дві руки над головою: зігнути — випрямити

**Document type:** Exercise Production Brief  
**Exercise ID:** `ELBOW_008`  
**Slug:** `seated_both_arms_overhead_bend_extend`  
**Primary zone:** `elbows`  
**Authoring language:** Ukrainian  
**Status:** `draft`  
**Asset status:** `images_included`  
**Difficulty:** easy / starter  
**Equipment:** stable chair  
**Position:** seated  
**Movement type:** bilateral overhead elbow flexion / extension  
**Template version:** `v2 FULL_SAFE`  
**Brief version:** `0.1.0`

---

## 1. Purpose

Проста вправа для рук і ліктів без обладнання. Людина сидить рівно на стільці. У стартовому положенні обидві руки зігнуті над головою: кисті знаходяться за головою / біля верхньої частини потилиці, лікті розведені в сторони. Потім людина плавно випрямляє обидві руки вгору над головою і повертає їх назад у вихідне положення.

---

## 2. Updated framing rule

Для цієї вправи застосовано шаблон кадрування `FULL_SAFE`, тому що активні руки рухаються над головою.

**Обов'язкові правила:**
- усі руки, кисті, ноги і стопи повністю в кадрі;
- жодних обрізаних кінцівок;
- запас простору навколо активних рук;
- усі motion frames мають однаковий ракурс і однаковий масштаб.

---

## 3. Repository locations

Human brief:  
`docs/exercise_briefs/elbows/ELBOW_008/ELBOW_008_BRIEF.md`

Visual brief sheet:  
`docs/exercise_briefs/elbows/ELBOW_008/ELBOW_008_brief_sheet_v1.png`

Canonical YAML path:  
`data/exercises/elbows/ELBOW_008.yaml`

Production images folder:  
`assets/exercises/ELBOW_008/images/`

---

## 4. Required images and exact filenames

- `assets/exercises/ELBOW_008/images/setup_full_safe.png`
- `assets/exercises/ELBOW_008/images/motion_01_both_arms_bent_overhead_full_safe.png`
- `assets/exercises/ELBOW_008/images/motion_02_both_arms_extended_overhead_full_safe.png`
- `assets/exercises/ELBOW_008/images/preview.png`

All production images use safe, uncropped framing.

---

## 5. Motion sequence

### Phase A
Обидві руки зігнуті над головою. Кисті за головою / біля потилиці.

### Phase B
Обидві руки випрямлені вгору над головою.

### Return
Повернутися до Phase A.

### Canonical cycle
`A → B → A`

---

## 6. Voice accompaniment

- `audio/uk/exercises/ELBOW_008/setup.m4a`  
  Text: `Сядьте рівно. Дві руки зігніть над головою.`
- `audio/uk/exercises/ELBOW_008/start_movement.m4a`  
  Text: `Плавно випряміть руки вгору і поверніть назад.`
- common:
  - `audio/uk/common/halfway.m4a`
  - `audio/uk/common/completed.m4a`

---

## 7. QA checklist

- [ ] Застосовано шаблон `FULL_SAFE`.
- [ ] Обидві активні руки повністю в кадрі в обох фазах.
- [ ] Ноги і стопи також видно повністю.
- [ ] Motion frames мають однаковий ракурс і масштаб.
- [ ] Поза спокійна, корпус рівний.
- [ ] Немає text / arrows / UI / watermark.
