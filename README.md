# atmos_factorio_mods

Monorepo for Factorio **2.1** mods.

| Mod | Folder |
| --- | --- |
| Atmos Shotgun Tiers | [atmos_shotgun_tiers](atmos_shotgun_tiers) |
| Atmos Enemy Range Visualizer | [atmos_enemy_range_visualizer](atmos_enemy_range_visualizer) |
| Atmos Auto Heal | [atmos_auto_heal](atmos_auto_heal) |
| Atmos Auto Fire | [atmos_auto_fire](atmos_auto_fire) |
| Atmos Faster Start | [atmos_faster_start](atmos_faster_start) |
| Atmos QoL Pack (modpack) | [atmos_qol_pack](atmos_qol_pack) |

The in-game / portal mod id stays as in each mod's `info.json` (do not rename after publish).

Russian overview: [README_RU.md](README_RU.md)

## Recommended companion

For personal gun/vehicle range circles, use **[Gun Range Visualizer](https://mods.factorio.com/mod/gun-range-visualizer)** (recommended by Atmos Enemy Range Visualizer).

## Thumbnails

Every mod has `thumbnail_idea.md` (concept + prompt) and a `thumbnail.png` framed with `assets/thumbnail_frame.png`:

```powershell
py -3 scripts/make_thumbnail.py <art> <mod_folder>
```

## Signal icon index

`assets/signals/` indexes Factorio virtual signals (names, locales, sprite paths) for use in mods. Regenerate with `py -3 scripts/index_signals.py`; icons stay in the game install (gitignored junction `assets/factorio-data`).

## Packaging

```powershell
.\scripts\pack-mod.ps1 -ModDir atmos_enemy_range_visualizer
# or
py -3 scripts/pack-mod.py atmos_shotgun_tiers
```

Zips are written to `dist/{name}_{version}.zip`.

## Publish / update (Mod Portal)

Uses GitHub Actions secret `FACTORIO_API_KEY`.

- **Manual:** Actions → *Publish Factorio mods* → pick mod or `all`
- **Tag:** `git tag atmos_shotgun_tiers/2.1.1 && git push origin atmos_shotgun_tiers/2.1.1`
- **Local:** `py -3 scripts/publish-mod.py atmos_shotgun_tiers` (needs `FACTORIO_API_KEY` + `pip install requests`)
