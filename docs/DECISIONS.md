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
41. **Остання вправа підборки завершується, а не відпочиває.** `SessionMachine`
    отримав `hasNextExercise`: без нього `autoNextEnabled` заводив сесію в
    `AUTO_REST`, відлік доходив до нуля і `AutoStartNext` не мав куди вести —
    екран залишався на «Відпочинок 0» назавжди. Тепер за відсутності
    наступної вправи стан лишається `COMPLETED`, і його малює окремий екран
    завершення (`UX_FLOW.md` F).
42. **Плеєр показує один великий час, а не чотири рівні метрики.** Годинник —
    єдине число, на яке дивляться під час руху, тому він винесений з
    `_MetricsRow` окремим блоком з табулярними цифрами; повтор і сторона
    лишились дрібними підписами. Керування — круглі кнопки: Пауза вдвічі
    більша за решту, назва кнопки водночас її tooltip, тому вона доступна
    скрінрідеру й тестам (`find.byTooltip`).
43. **Колір зони — спільна нитка між екранами.** Чіп «Працюють · Коліна» у
    плеєрі, смуга прогресу і бейдж завершення беруть той самий
    `Tokens.zoneColor`, що й точка на body map, тому зона впізнається без
    підпису.
44. **Кадри генеруються як edit майстер-кадру, а не з тексту.** Одна вправа —
    це та сама сцена з переставленою кінцівкою, а текстові промпти дрифтують.
    `generate_frames.py` створює перший кадр із нуля, решту — як edit цього
    кадру з ним же як reference; `back.png` body map — edit `front.png`, щоб
    обидві фігури мали однаковий масштаб під спільні hotspot-и. Промпти беруться
    з тих самих функцій, що пишуть `IMAGE_BRIEFS.md`: API і людина отримують
    дослівно одне й те саме.
45. **Генератор нічого не надсилає без `--yes`.** Типовий запуск друкує план і
    промпти. Плюс `--budget`, і наявний файл не перезаписується без `--force`:
    зображення коштують грошей, а вибраний кадр не має тихо зникати.

46. **Домашній екран — за HOME_SCREEN_REPOSITORY_PACK_v1, без нижньої
    навігації.** Пакет позначений `approved for repository setup`, і його
    макет заміняє і таб-шелл із `MENU_AND_NAVIGATION.md`, і мій попередній
    екран «Де турбує?» з підписами зон. Тепер: шапка (меню, зарезервований
    блок заголовка, налаштування), інтерактивна мапа тіла (велика фігура
    спереду + маленька ззаду), 2x2 картки Тіло / Очі / Ранок / Засидівся.
    Те, що давали таби, переїхало: ситуації — у картки, «Моя активність» — у
    drawer. `MENU_AND_NAVIGATION.md` у частині нижньої навігації застарів.
47. **ARB із пакета не підключаємо; рядки імпортовані у YAML-пайплайн.**
    Бриф рекомендує `lib/l10n/*.arb` + gen-l10n, але жорсткі вимоги (текст не
    у зображеннях, ручний вибір мови перекриває системну, вибір зберігається,
    коректний fallback) уже виконує наявний пайплайн
    YAML -> JSON -> `AppStrings` (`TECHNICAL_SPEC.md` 22, `LOCALIZATION.md`).
    Два джерела істини для рядків були б гіршою платою за формат. Доставлені
    ARB лежать у `docs/ui/home/l10n/` як запис хендофу, з якого зроблено
    імпорт.
48. **`AppStrings` тепер стакає пакет мови поверх fallback-пакета.** Польська
    доставлена лише на домашній екран і назви зон (22 рядки зі 110), і без
    per-key fallback решта екранів показувала б сирі ключі. Тепер відсутній
    ключ бере англійський рядок. Тест `localization_test.dart` перевіряє, що
    частковий пакет не вигадує власних ключів і що кожен потрібний ключ
    розв'язується.
49. **Координати hotspot-ів відкалібровані під доставлений артворк.** Чернові
    значення з пакета ставили точку шиї на рот, колін — на верх гомілки, а
    стоп — під ноги. `scripts/tune_hotspots.py` малює оверлей на реальному
    PNG; `content_rect` (де фігура насправді лежить у файлі) винесений у дані,
    бо обидва PNG мають широкі порожні поля — застосунок кропає до нього, а
    build перераховує координати в цей самий простір. `check_assets.py`
    переміряє PNG і падає, якщо `content_rect` розійшовся з артворком.
50. **Тап по фігурі розв'язується найближчим центром, не hit-test'ом.**
    Дев'ятнадцять точок на одній фігурі означають, що їхні 56-px цілі
    перекриваються; інакше тап між коліном і гомілкою дістався б тому віджету,
    який намалювався останнім. Радіус — `tap_resolution.max_distance_px`.
51. **Застосунок світлий на всіх екранах і не слухає системну тему.**
    Артворк тіла несе в собі майже білий фон, і затверджений референс ставить
    кожен елемент — картки, текст, іконки — на той самий білий. У темній темі
    фігура сиділа на яскравій плиті. `MaterialApp` більше не отримує
    `darkTheme`, тому системне перемикання не може перевернути екрани з
    артворком. Seed (`#3F7F76`) лишається акцентом дій; поверхні й текст на
    світлій темі беруться з референсу (білий `pageWhite`, темно-синій
    `textStrong`, синій акцент мапи `hotspot`).
52. **Меню й «Налаштування» лишаються темними.** Це chrome, а не контент:
    у них нічого не лежить на білому артворку, і темна панель зверху світлого
    екрана читається як шар над ним. Обидва обгорнуті локальним
    `Theme(data: AppTheme.dark())`, тому `dark()` не мертвий код.
53. **Нові вправи тримають артворк у `assets/exercises/<ID>/images/`.**
    Пакет `ELBOW_001_009_repository_pack_v6` приніс власну структуру
    (`docs/REPOSITORY_EXERCISE_STRUCTURE.md`): бриф окремо від runtime-даних,
    ізольована тека зображень на вправу, спільні голосові репліки один раз на
    мову. Дев'ять ліктьових вправ пішли саме так; чотири старі теки без
    підпапки лишилися як є, бо в них ще немає жодного файлу, і перейменування
    нічого не дало б. `check_assets.py` читає теку з `assets.folder`, тому
    обидві форми валідні.
54. **Правило «однаковий кроп на всіх кадрах» замінено на framing v2.**
    Старе правило змушувало або обрізати підняту руку, або показувати
    сидячу вправу здалеку. Тепер setup frame може бути ширшим, а спільний
    кроп обов'язковий лише всередині motion-послідовності; головна вимога —
    жодна робоча кінцівка не обрізана і має запас ≥5%. Це те, що пакет
    називає `FULL_SAFE` / `MID_SAFE`.
55. **Ліктьові вправи — часові, а не на повтори.** Брифи задають
    «completion basis: elapsed active time», 60 с і цикл ~4 с, тому
    `sequence` має два блоки без сторони: поза setup показується один раз
    (на ній і стоїть відлік підготовки), далі цикл A→B→A крутиться 15 разів.
    Лічильник повторів і підпис сторони вимкнені — на екрані лишається
    таймер.
56. **`ELBOW_009` не потрапив у колекцію `standing`.** YAML із пакета
    посилався на неї, але такої колекції в `data/collections/collections.yaml`
    немає, а заводити колекцію з однією вправою зарано. Вправа лежить у
    `body_elbows`, `computer_break` і `after_sitting`; `standing` варто додати
    разом із рештою вправ стоячи.
57. **Майстри 1254 px зменшені до 1024 px.** П'ять із дев'яти вправ
    прийшли більшими за майстер-розмір `docs/IMAGE_ASSET_SPEC.md` 2. Замість
    того щоб послабити спец, кадри масштабовані до 1024×1024 (LANCZOS) — це
    заразом зняло ~14 МБ з бандла. `preview.png` не копіювався з пакета:
    його, як і раніше, робить `scripts/make_previews.py` із setup-кадру.

