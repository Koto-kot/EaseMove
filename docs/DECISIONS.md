# Locked Product Decisions

1. Free не має onboarding questionnaire.
2. Головні входи: Тіло / Комп’ютер / Ліжко / Очі.
3. Exercise cards великі; приблизно 3 видно одразу.
4. Exercise controls: Previous / Start-Pause / Stop / Next.
5. Manual Start → 5 sec prep.
6. Recommended sequence задає app metadata.
7. Stop дозволений будь-коли.
8. Після normal completion → 10 sec rest → auto-next.
9. Немає Skip Rest у auto-flow.
10. Previous/Next під час rest скасовує auto-flow.
11. Музика ≈ 50% voice; ducking off.
12. Lifetime exercise count не обнуляється.
13. Reminders opt-in, без guilt.
14. App language ≠ store country.
15. Manual language selection available.
16. Pro visible to Free, але locked.
17. Development Pro unlocked.
18. Exercises data-driven YAML.
19. One exercise може бути в many collections.
20. Production exercises require clinical `approved`.
21. AI may only select from approved library.

22. Flutter + Dart є обов’язковим стеком застосунку.

23. Body Map artwork і hotspot interaction layer зберігаються окремо.
24. Exercise production images не містять тексту, стрілок або UI.
25. Exercise frames використовують централізовані visual/subject profiles.

## Code kickoff decisions (v0.2, MVP slice)

26. **State management: Riverpod.** Обрано за критеріями `FLUTTER_ARCHITECTURE.md`
    (testability, deterministic transitions, мінімум boilerplate, підтримка
    feature flags / entitlement state). Один стандарт на весь проєкт; BLoC
    не використовується паралельно.
27. **Content pipeline: `scripts/build_content.py`.** YAML → validate →
    `assets/content/*.json`. Застосунок не парсить YAML у runtime. Згенерований
    bundle комітиться, а CI перевіряє, що він синхронний із `data/`.
28. **Localization через той самий bundle, а не ARB.** `data/localization/<locale>/common.yaml`
    компілюється в `assets/content/localization/<locale>.json`; UI звертається
    по ключах (`AppStrings`). Причина: один authoring pipeline для UI-рядків і
    контенту вправ, без дублювання перекладів у двох форматах.
    `flutter_localizations` підключено для системних Material/Cupertino рядків.
29. **`en` pack створено одразу** як fallback-мова (`LOCALIZATION.md`), authoring
    мова залишається `uk`.
30. **Sequence normalization.** Три authoring-форми (`side_blocks`,
    `steps + repeat`, `steps + repeat_cycles`) зводяться build-кроком до однієї
    runtime-форми `blocks[]`. Exercise Engine не має гілок під конкретну вправу.
31. **Voice cues розв'язуються заздалегідь у timeline.** Тригери
    (`sequence_phase_started`, `repetition_started`, `side_block_completed`,
    `progress_crossed`) перетворюються на `ScheduledCue` з абсолютним offset.
    Немає окремих таймерів для аудіо — виконується правило single timeline.
32. **Environment — compile-time** (`--dart-define=ENV=production`). Release-збірка
    не може отримати development-флаги в runtime.
33. **Early stop не збільшує lifetime counter** за замовчуванням; політика
    централізована (`SessionMachine.countEarlyStopInLifetime`), не per-exercise.
34. **Billing і voice packs — заглушки.** `EntitlementsService` працює локально,
    `AudioService` логує cue замість відтворення (voice packs ще не записані,
    `recording_spec.current_status: not_recorded`).
35. **Assets ще немає → плейсхолдери.** Кадри вправ і body-map artwork
    рендеряться через `AssetImageOrPlaceholder` / нейтральний силует; поява
    реальних PNG не потребує змін у коді.
36. **`body_map_hotspot_ids` у вправах — редакторська підказка, не навігація.**
    Навігація йде через `collections` і `hotspot.action.collection_id`.
    Build-крок попереджає про неспівпадіння id (напр. `left_knee` vs
    `left_knee_front`), але не падає.

37. **Голос вправ — TTS до появи voice packs.** `TtsAudioService` озвучує
    `text_uk` з audio events через `flutter_tts`. `LOCALIZATION.md` прямо
    допускає «voice pack або TTS fallback». Записане аудіо потім замінює лише
    цей клас: `AudioService` і `SessionAudioController` не змінюються.
    Швидкість мовлення 0.45 — відповідає `voice_style_uk`
    («спокійний, без поспіху»).
38. **Музика лишається no-op**, доки в `music/` немає треків: TTS не може дати
    фон, а тиша краще за помилку відтворення.
39. **Reduced motion використовує `TimelineStep.keyFrameId`** — один статичний
    кадр на крок замість проходу кадрів переходу
    (`VISUAL_STYLE_GUIDE.md` 11, `TECHNICAL_SPEC.md` 18).
40. **Situation-колекції навігації валідуються build-кроком.** `eyes_basic`
    існував у навігації, але не в даних; тепер `NAVIGATION_COLLECTIONS`
    у `build_content.py` не дає таб з'явитися без колекції.
