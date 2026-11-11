# atmos_factorio_mods

Монорепозиторий модов для Factorio **2.1**.

| Мод | Папка |
| --- | --- |
| Atmos Shotgun Tiers | [atmos_shotgun_tiers](atmos_shotgun_tiers) |
| Atmos Enemy Range Visualizer | [atmos_enemy_range_visualizer](atmos_enemy_range_visualizer) |
| Atmos Auto Heal | [atmos_auto_heal](atmos_auto_heal) |
| Atmos Auto Fire | [atmos_auto_fire](atmos_auto_fire) |
| Atmos Faster Start | [atmos_faster_start](atmos_faster_start) |
| Atmos QoL Pack (модпак) | [atmos_qol_pack](atmos_qol_pack) |

Имя мода в игре / на портале задаётся в `info.json` каждого мода (после публикации не переименовывать).

English overview: [README.md](README.md)

## Рекомендуемый компаньон

Для кругов дальности своего оружия/техники — **[Gun Range Visualizer](https://mods.factorio.com/mod/gun-range-visualizer)** (рекомендуется модом Atmos Enemy Range Visualizer).

## Иконки модов

У каждого мода есть `thumbnail_idea.md` (концепция и промпт) и `thumbnail.png` в рамке `assets/thumbnail_frame.png`:

```powershell
py -3 scripts/make_thumbnail.py <картинка> <папка_мода>
```

## Индекс сигнальных иконок

`assets/signals/` содержит индекс виртуальных сигналов Factorio (имена, локали, sprite-пути) для использования в модах. Пересборка: `py -3 scripts/index_signals.py`; сами иконки остаются в папке игры (junction `assets/factorio-data` в gitignore).

## Упаковка

```powershell
.\scripts\pack-mod.ps1 -ModDir atmos_enemy_range_visualizer
# или
py -3 scripts/pack-mod.py atmos_shotgun_tiers
```

Zip-архивы пишутся в `dist/{name}_{version}.zip`.

## Публикация / обновление (Mod Portal)

Нужен GitHub Actions secret `FACTORIO_API_KEY`.

- **Вручную:** Actions → *Publish Factorio mods* → мод или `all`
- **Тег:** `git tag atmos_shotgun_tiers/2.1.1 && git push origin atmos_shotgun_tiers/2.1.1`
- **Локально:** `py -3 scripts/publish-mod.py atmos_shotgun_tiers` (нужны `FACTORIO_API_KEY` и `pip install requests`)
