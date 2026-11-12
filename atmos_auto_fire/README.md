# Atmos Auto Fire

Factorio 2.1 mod that automatically fires the weapon in the player's hands: shotgun, pistol, SMG, rocket launcher, or any modded gun.

The character itself pulls the trigger: the mod sets the character's shooting state at the chosen target, so spread, range, cooldown, ammo use, and research bonuses are exactly those of the held gun.

## Behavior

- Active while the selected gun is checked in the **Weapons** column and the shortcut is on. All guns are on by default; **All on** / **All off** buttons switch every gun at once.
- A target is picked every 5 ticks; the trigger is held every tick while that target stays valid and in range.
- While a target is held, it overrides manual aiming. With no target, manual shooting works as usual.

## Allow / forbid lists

Allow rows are checked from top to bottom. Each row can be:

- ★ All enemies
- An entity type (spawners, combat robots, units, worm/turret type, spider units, segmented units)
- A specific game entity (choose-elem picker)

Each allow row has a range slider and an `m` / `%` switch:

- `m` — absolute meters
- `%` — percent of the held weapon's firing range

Forbid entries are never selected as targets and also block the line of fire.

Default allow order:

1. All at 10% range
2. Spawners
3. Combat robots
4. Worms behemoth → small
5. Spitters behemoth → small
6. Biters behemoth → small
7. All at 100% range

Default forbid: gun turret, laser turret, flamethrower turret.

Avoid-own-buildings line-of-fire check is on by default: a target is skipped while the shot cone toward it crosses an own or allied building (or a forbidden entity).

The "Show debug overlay" checkbox draws ranges, candidates with their allow row, shot cones, and blocking buildings.

## Controls

- Mod button bar (top-left): shotgun button with gear and damage badges opens or closes the settings window.
- Shortcut bar: toggles auto-fire. Default key `CONTROL + ALT + G`.

## License

MIT

---

# Atmos Auto Fire

Мод для Factorio 2.1: автоматическая стрельба из оружия в руках игрока: дробовик, пистолет, автомат, ракетница или любое оружие из модов.

Стреляет сам персонаж: мод выставляет ему состояние стрельбы по выбранной цели, поэтому разброс, дальность, кулдаун, расход патронов и бонусы исследований — ровно как у оружия в руках.

## Поведение

- Работает, когда оружие в выбранном слоте отмечено в столбце **Оружие** и автоогонь включён. По умолчанию включено всё оружие; кнопки **Вкл все** / **Выкл все** переключают его разом.
- Цель выбирается раз в 5 тиков; спуск удерживается каждый тик, пока цель жива и в зоне досягаемости.
- Пока есть цель, она перекрывает ручное прицеливание. Без цели ручная стрельба работает как обычно.

## Списки разрешений и запрета

Строки разрешений проверяются сверху вниз. В строке может быть:

- ★ Все враги
- Тип сущности (гнёзда, боевые дроны, юниты, черви/турели, паучьи, сегментированные)
- Конкретная игровая сущность (выбор через choose-elem)

У каждой строки разрешений есть слайдер дальности и переключатель `м` / `%`:

- `м` — абсолютные метры
- `%` — процент от дальности оружия в руках

Сущности из запрета никогда не выбираются целью и перекрывают линию огня.

Порядок разрешений по умолчанию:

1. Все на 10% дальности
2. Гнёзда
3. Боевые дроны
4. Черви от бегемота к малому
5. Плеваки от бегемота к малому
6. Кусаки от бегемота к малому
7. Все на 100% дальности

Запрет по умолчанию: турель, лазерная турель, огнемётная турель.

Тугл «не стрелять через свои постройки» по умолчанию включён: цель пропускается, пока конус выстрела к ней задевает свою или союзную постройку (или запрещённую сущность).

Галочка «Показывать отладочную информацию» рисует дальности, кандидатов с номером строки разрешений, конусы выстрела и мешающие постройки.

## Управление

- Панель кнопок модов (слева сверху): кнопка дробовика с шестерёнкой и значком урона открывает и закрывает окно настроек.
- Нижняя панель быстрых действий: переключатель автоогня. Клавиша по умолчанию `CONTROL + ALT + G`.

## Лицензия

MIT
