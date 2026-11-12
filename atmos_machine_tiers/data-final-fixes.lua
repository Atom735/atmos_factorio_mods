local startup = settings.startup

local MAX_TIER = startup["atmos-machine-tiers-max-tier"].value
local INGREDIENT_COUNT = startup["atmos-machine-tiers-ingredient-count"].value
local COMPOUND = startup["atmos-machine-tiers-scaling"].value == "compound"
local SPEED_STEP = startup["atmos-machine-tiers-speed-bonus"].value / 100
local ENERGY_STEP = startup["atmos-machine-tiers-energy-bonus"].value / 100
local MODULE_STEP = startup["atmos-machine-tiers-module-slots"].value
local SCALE_POLLUTION = startup["atmos-machine-tiers-scale-pollution"].value

-- Must match control.lua.
local TIER_SUFFIX = "-atmos-t"

local MACHINE_TYPES = {
  { type = "assembling-machine", setting = "atmos-machine-tiers-assemblers", speed = "crafting_speed" },
  { type = "furnace", setting = "atmos-machine-tiers-furnaces", speed = "crafting_speed" },
  { type = "mining-drill", setting = "atmos-machine-tiers-mining-drills", speed = "mining_speed" },
  { type = "lab", setting = "atmos-machine-tiers-labs", speed = "researching_speed" },
  { type = "offshore-pump", setting = "atmos-machine-tiers-offshore-pumps", speed = "pumping_speed", no_modules = true },
}

local ITEM_TYPES = { "item", "item-with-entity-data" }

local blacklist = {}
for name in string.gmatch(startup["atmos-machine-tiers-blacklist"].value, "[^,%s]+") do
  blacklist[name] = true
end

local function multiplier(step, tier)
  local levels = tier - 1
  if COMPOUND then
    return (1 + step) ^ levels
  end
  return 1 + step * levels
end

local function tier_name(base_name, tier)
  return base_name .. TIER_SUFFIX .. tier
end

local function previous_name(base_name, tier)
  if tier == 2 then
    return base_name
  end
  return tier_name(base_name, tier - 1)
end

local function tier_label(base_localised, tier)
  if tier == MAX_TIER then
    return { "atmos-machine-tiers.master-name", base_localised }
  end
  return { "atmos-machine-tiers.tier-name", base_localised, tostring(tier) }
end

local ENERGY_PREFIX = { [""] = 1, k = 1e3, M = 1e6, G = 1e9, T = 1e12, P = 1e15 }

local function scale_energy(value, factor)
  if type(value) ~= "string" then
    return value
  end
  local number, prefix, unit = string.match(value, "^%s*([%d%.]+)%s*([kMGTP]?)([WJ])%s*$")
  if not number then
    return value
  end
  local amount = tonumber(number) * ENERGY_PREFIX[prefix] * factor
  return string.format("%.0f%s", amount, unit)
end

local function scale_emissions(energy_source, factor)
  if type(energy_source) ~= "table" or type(energy_source.emissions_per_minute) ~= "table" then
    return
  end
  for pollutant, amount in pairs(energy_source.emissions_per_minute) do
    energy_source.emissions_per_minute[pollutant] = amount * factor
  end
end

local function tier_badge(tier)
  if tier == MAX_TIER then
    return "__base__/graphics/icons/signal/signal-star.png"
  end
  return "__base__/graphics/icons/signal/signal_" .. tier .. ".png"
end

local function tier_icons(proto, tier)
  local icons = {}
  if proto.icons then
    for _, layer in ipairs(proto.icons) do
      icons[#icons + 1] = table.deepcopy(layer)
    end
  elseif proto.icon then
    icons[1] = { icon = proto.icon, icon_size = proto.icon_size or 64 }
  else
    return nil
  end
  icons[#icons + 1] = { icon = tier_badge(tier), icon_size = 64, scale = 0.25, shift = { 8, -8 } }
  return icons
end

local function apply_icons(proto, tier)
  local icons = tier_icons(proto, tier)
  if icons then
    proto.icon = nil
    proto.icon_size = nil
    proto.icons = icons
  end
end

local function find_item(name)
  for _, item_type in pairs(ITEM_TYPES) do
    local item = data.raw[item_type] and data.raw[item_type][name]
    if item then
      return item
    end
  end
  return nil
end

local function placing_item(entity)
  local minable = entity.minable
  if not minable then
    return nil
  end
  local result = minable.result
  if not result and type(minable.results) == "table" and minable.results[1] then
    result = minable.results[1].name
  end
  if not result then
    return nil
  end
  local item = find_item(result)
  if item and item.place_result == entity.name then
    return item
  end
  return nil
end

local function find_recipe(item_name)
  local recipe = data.raw.recipe[item_name]
  if recipe then
    return recipe
  end
  for _, candidate in pairs(data.raw.recipe) do
    for _, result in pairs(candidate.results or {}) do
      if result.name == item_name and (result.type or "item") == "item" then
        return candidate
      end
    end
  end
  return nil
end

local function unlocking_technologies(recipe_name)
  local list = {}
  for _, technology in pairs(data.raw.technology) do
    for _, effect in pairs(technology.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe_name then
        list[#list + 1] = technology
        break
      end
    end
  end
  return list
end

local function make_entity(base, spec, tier, item_name)
  local proto = table.deepcopy(base)
  proto.name = tier_name(base.name, tier)
  proto.localised_name = tier_label(base.localised_name or { "entity-name." .. base.name }, tier)
  proto.localised_description = base.localised_description or { "entity-description." .. base.name }
  proto.minable = table.deepcopy(base.minable)
  proto.minable.result = item_name
  proto.minable.results = nil
  proto.placeable_by = nil
  proto.next_upgrade = tier < MAX_TIER and tier_name(base.name, tier + 1) or nil
  proto.fast_replaceable_group = base.fast_replaceable_group or base.name
  apply_icons(proto, tier)

  local speed = proto[spec.speed]
  if type(speed) == "number" then
    proto[spec.speed] = speed * multiplier(SPEED_STEP, tier)
  end

  local energy_factor = multiplier(ENERGY_STEP, tier)
  proto.energy_usage = scale_energy(proto.energy_usage, energy_factor)
  if SCALE_POLLUTION then
    scale_emissions(proto.energy_source, energy_factor)
  end

  -- An explicit empty allowed_effects forbids modules; slots there fail prototype setup.
  local effects = proto.allowed_effects
  local effects_allowed = type(effects) ~= "table" or next(effects) ~= nil
  if MODULE_STEP > 0 and not spec.no_modules and effects_allowed then
    proto.module_slots = (proto.module_slots or 0) + MODULE_STEP * (tier - 1)
  end
  return proto
end

local function make_item(base_item, tier, entity_name)
  local proto = table.deepcopy(base_item)
  proto.name = tier_name(base_item.name, tier)
  proto.localised_name = tier_label(base_item.localised_name or { "entity-name." .. base_item.place_result }, tier)
  proto.place_result = entity_name
  proto.order = (base_item.order or base_item.name) .. string.format("-t%02d", tier)
  apply_icons(proto, tier)
  return proto
end

local function make_recipe(base_item, base_recipe, tier, item_name)
  return {
    type = "recipe",
    name = item_name,
    localised_name = tier_label(base_item.localised_name or { "entity-name." .. base_item.place_result }, tier),
    categories = { "crafting" },
    subgroup = base_item.subgroup,
    order = (base_item.order or base_item.name) .. string.format("-t%02d", tier),
    energy_required = 0.5,
    enabled = base_recipe.enabled ~= false,
    allow_decomposition = false,
    allow_as_intermediate = false,
    ingredients = {
      { type = "item", name = previous_name(base_item.name, tier), amount = INGREDIENT_COUNT },
    },
    results = {
      { type = "item", name = item_name, amount = 1 },
    },
  }
end

local function create_tiers(base, spec)
  if blacklist[base.name] or base.hidden or string.find(base.name, TIER_SUFFIX, 1, true) then
    return
  end
  local base_item = placing_item(base)
  if not base_item or base_item.hidden then
    return
  end
  local base_recipe = find_recipe(base_item.name)
  if not base_recipe or base_recipe.hidden then
    return
  end
  local technologies = base_recipe.enabled == false and unlocking_technologies(base_recipe.name) or {}
  if base_recipe.enabled == false and #technologies == 0 then
    return
  end

  local new = {}
  for tier = 2, MAX_TIER do
    local item_name = tier_name(base_item.name, tier)
    local entity_name = tier_name(base.name, tier)
    new[#new + 1] = make_entity(base, spec, tier, item_name)
    new[#new + 1] = make_item(base_item, tier, entity_name)
    new[#new + 1] = make_recipe(base_item, base_recipe, tier, item_name)
    for _, technology in pairs(technologies) do
      table.insert(technology.effects, { type = "unlock-recipe", recipe = item_name })
    end
  end
  data:extend(new)
end

for _, spec in pairs(MACHINE_TYPES) do
  if startup[spec.setting].value then
    local names = {}
    for name in pairs(data.raw[spec.type] or {}) do
      names[#names + 1] = name
    end
    table.sort(names)
    for _, name in pairs(names) do
      create_tiers(data.raw[spec.type][name], spec)
    end
  end
end
