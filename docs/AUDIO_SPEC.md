# Audio Specification

## Mix

Default:
- Voice = 100%
- Music = 50% relative to voice
- dynamic ducking = OFF

Музика не повинна автоматично ставати тихішою під час voice cue.

## Типи аудіо

### Common reusable
- 5,4,3,2,1
- Тримайте
- Поверніться в центр
- Тепер інша нога
- Половину виконано
- Останній повтор
- Готово

### Exercise-specific
- Поверніть голову ліворуч
- Повільно випряміть ногу
- Ковзайте п’ятою до себе
- тощо

## Recording pipeline

Master:
- WAV
- normalized
- trimmed silence

App delivery:
- M4A/AAC або інший platform-efficient format, обраний на implementation stage.

## Voice style

- спокійний;
- доброзичливий;
- чіткий;
- без поспіху;
- короткі фрази;
- не говорити поверх критичної movement command.

## Collision policy

Movement cue має більший priority, ніж progress cue.

При конфлікті:
- critical movement cue грає зараз;
- progress cue затримується або пропускається згідно metadata.

## Future Pro

- voice packs;
- minimal cues;
- movement words;
- counting;
- no voice;
- separate interface/voice language.
