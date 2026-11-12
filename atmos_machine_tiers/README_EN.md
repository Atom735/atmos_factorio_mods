# Atmos Machine Tiers

Upgrade tiers for production machines, in the spirit of Atmos Shotgun Tiers.

- Covers every **assembling-machine** (assemblers, chemical plant, oil refinery, centrifuge, Space Age machines, modded ones), **furnace**, **mining-drill** (mining drills, big mining drill, pumpjack) and **offshore pumps**; **labs** optionally.
- Tier N+1 is crafted from **5** machines of tier N (count configurable). Recipes unlock together with the base machine.
- Defaults per tier: **+100% speed**, **+1 module slot**, **+100% energy use** (pollution scales with energy). Tier 2 = 2× speed, tier 5 = 5× speed.
- Machines keep their original graphics; a tier digit (★ for the master tier) is drawn in the top-right corner. Item icons get the same badge.
- Tiers form an upgrade chain, so the upgrade planner and fast-replace work.

## Settings

| Setting | Default |
| --- | --- |
| Number of tiers | 5 |
| Previous tier machines per upgrade | 5 |
| Bonus scaling | linear / compound |
| Speed bonus per tier | 100% |
| Energy use increase per tier | 100% |
| Extra module slots per tier | 1 |
| Scale pollution with energy | on |
| Assemblers / furnaces / mining drills / offshore pumps / labs | on / on / on / on / off |
| Excluded machines (comma list) | empty |
| Tier badge: show / size / alt mode only (map, runtime) | on / 0.6 / off |