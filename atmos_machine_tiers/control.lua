-- Must match data-final-fixes.lua.
local TIER_PATTERN = "%-atmos%-t(%d+)$"

local tier_cache = nil

local function tier_of(name)
  tier_cache = tier_cache or {}
  local tier = tier_cache[name]
  if tier == nil then
    tier = tonumber(string.match(name, TIER_PATTERN)) or false
    tier_cache[name] = tier
  end
  return tier
end

local function tier_entity_names()
  local names = {}
  for name in pairs(prototypes.entity) do
    if tier_of(name) then
      names[#names + 1] = name
    end
  end
  return names
end

local function badge_sprite(tier)
  if tier >= settings.startup["atmos-machine-tiers-max-tier"].value then
    return "virtual-signal/signal-star"
  end
  return "virtual-signal/signal-" .. tier
end

local function draw_badge(entity)
  if not (entity and entity.valid) then
    return
  end
  local tier = tier_of(entity.name)
  if not tier or not settings.global["atmos-machine-tiers-overlay"].value then
    return
  end
  local scale = settings.global["atmos-machine-tiers-overlay-scale"].value
  local box = entity.prototype.selection_box
  local inset = 0.35 * scale
  rendering.draw_sprite({
    sprite = badge_sprite(tier),
    target = { entity = entity, offset = { box.right_bottom.x - inset, box.left_top.y + inset } },
    surface = entity.surface,
    x_scale = scale,
    y_scale = scale,
    render_layer = "entity-info-icon-above",
    only_in_alt_mode = settings.global["atmos-machine-tiers-overlay-alt-only"].value,
  })
end

local function redraw_all()
  rendering.clear(script.mod_name)
  local names = tier_entity_names()
  if #names == 0 or not settings.global["atmos-machine-tiers-overlay"].value then
    return
  end
  for _, surface in pairs(game.surfaces) do
    for _, entity in pairs(surface.find_entities_filtered({ name = names })) do
      draw_badge(entity)
    end
  end
end

script.on_init(redraw_all)
script.on_configuration_changed(redraw_all)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if string.find(event.setting, "atmos-machine-tiers-overlay", 1, true) then
    redraw_all()
  end
end)

local function on_built(event)
  draw_badge(event.entity or event.destination)
end

for _, id in pairs({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_built,
  defines.events.script_raised_revive,
  defines.events.on_entity_cloned,
}) do
  script.on_event(id, on_built)
end
