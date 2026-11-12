# Atmos Faster Start

Every player gets **virtual start points** (not items) and spends them in a GUI:

- **Default pack** - the classic [Faster Start](https://mods.factorio.com/mod/faster-start) kit, one time per player.
- **Any item** - pick it with the item selector, set the amount, buy. Prices are computed at runtime from the game's recipes and raw resources (ore, wood, fish, crude oil, water...). Recycling recipes are ignored, catalyst loops are reduced to net inputs/outputs.

The mod does **not** add or change recipes or other prototypes.

## Settings (map)

| Setting | Default | |
| --- | --- | --- |
| Start points per player | 0 | 0 = exactly the default pack price |
| Price multiplier | 1 | |
| Price of items without a recipe chain | 1000 | |
| Skip crash site and intro (startup) | on | |

## Commands (admin)

- `/atmos-start-add-points <amount> [player|all]` - add points (negative removes). No player = yourself.
- `/atmos-start-reset-points [player|all]` - reset to the starting value and allow the default pack again.
- `/atmos-start` - open the window (any player). The top-left button does the same.

## Credits

Based on [Faster Start](https://mods.factorio.com/mod/faster-start) by trad_emark (MIT).

---

# Atmos Faster Start

Каждый игрок получает **виртуальные стартовые очки** (не предметы) и тратит их в окне:

- **Стандартный набор** - классический набор [Faster Start](https://mods.factorio.com/mod/faster-start), один раз на игрока.
- **Любой предмет** - выберите его в селекторе, укажите количество, купите. Цены считаются в рантайме по рецептам игры и сырью (руда, дерево, рыба, нефть, вода...). Рецепты переработки игнорируются, циклы с катализатором сводятся к чистым входам/выходам.

Мод **не** добавляет и не меняет рецепты и другие прототипы.

## Настройки (карты)

| Настройка | По умолчанию | |
| --- | --- | --- |
| Стартовые очки на игрока | 0 | 0 = ровно цена стандартного набора |
| Множитель цен | 1 | |
| Цена предметов без цепочки рецептов | 1000 | |
| Пропустить место крушения и интро (startup) | вкл | |

## Команды (админ)

- `/atmos-start-add-points <количество> [игрок|all]` - добавить очки (отрицательное число отнимает). Без игрока = себе.
- `/atmos-start-reset-points [игрок|all]` - сбросить до начального значения и снова разрешить стандартный набор.
- `/atmos-start` - открыть окно (любой игрок). Кнопка слева сверху делает то же.

## Благодарности

Основан на [Faster Start](https://mods.factorio.com/mod/faster-start) от trad_emark (MIT).
