# Atmos Auto Heal

Factorio **2.1** mod that automatically eats fish, healing capsules, or any other self-healing item from your inventory when your health drops below a threshold.

## Features

- Detects every capsule with a self-heal effect at runtime (vanilla fish and modded items)
- Per-player priority list: reorder items and disable the ones you want to keep
- Toggle via shortcut bar or **Ctrl+Shift+H**
- Priority panel: **Ctrl+Shift+J** or the fish button (gear + heart badges) in the mod button bar
- Respects each item's use cooldown
- Optional "avoid wasting heals" mode: prefers items that fit the missing health

## Settings (per player)

- Heal below health (%), default 70
- Avoid wasting heals, default on

## Compatibility

Incompatible with **Auto Fish and Heal** (`auto-fish`). Both mods do the same job, and `auto-fish` 1.1.0 crashes on Factorio 2.x (`game.active_mods` was moved to `script.active_mods`).

## License

MIT

---

# Atmos Auto Heal

Мод для Factorio **2.1**: автоматически съедает рыбу, лечебные капсулы или любой другой предмет самолечения из инвентаря, когда здоровье падает ниже порога.

## Возможности

- Находит все капсулы с эффектом самолечения во время игры (ванильная рыба и предметы из модов)
- Индивидуальный список приоритетов: меняйте порядок и отключайте предметы, которые хотите сохранить
- Переключение шорткатом или **Ctrl+Shift+H**
- Панель приоритетов: **Ctrl+Shift+J** или кнопка с рыбой (шестерёнка + сердце) в панели кнопок модов
- Учитывает кулдаун использования предмета
- Режим «не тратить лечение впустую»: предпочитает предметы, которые не превышают недостающее здоровье

## Настройки (для каждого игрока)

- Лечить ниже здоровья (%), по умолчанию 70
- Не тратить лечение впустую, по умолчанию включено

## Совместимость

Несовместим с **Auto Fish and Heal** (`auto-fish`). Оба мода делают одно и то же, а `auto-fish` 1.1.0 падает на Factorio 2.x (`game.active_mods` перенесён в `script.active_mods`).

## Лицензия

MIT
