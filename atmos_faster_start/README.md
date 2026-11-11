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
