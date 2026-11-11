local mod_gui = require("mod-gui")

local FRAME = "atmos_faster_start_frame"
local TOP_BUTTON = "atmos_faster_start_button"

local RAW_ITEM_COST = 1
local RAW_FLUID_COST = 0.1
local TILE_FLUID_COST = 0.01
local ENERGY_COST = 0.05
local MAX_PASSES = 100

local EXCLUDED_RECIPE_CATEGORIES = {
  ["recycling"] = true,
  ["recycling-or-hand-crafting"] = true,
}

-- Same contents as the original Faster Start pack.
local DEFAULT_PACK = {
  items = {
    { "coal", 150 },
    { "iron-plate", 500 },
    { "copper-plate", 300 },
    { "iron-gear-wheel", 100 },
    { "electronic-circuit", 100 },
    { "fast-transport-belt", 2000 },
    { "fast-underground-belt", 200 },
    { "fast-splitter", 50 },
    { "pipe-to-ground", 50 },
    { "pipe", 50 },
    { "fast-inserter", 500 },
    { "steel-chest", 50 },
    { "construction-robot", 10 },
    { "steel-furnace", 50 },
    { "assembling-machine-2", 100 },
    { "electric-mining-drill", 50 },
    { "medium-electric-pole", 200 },
    { "big-electric-pole", 50 },
    { "boiler", 10 },
    { "steam-engine", 20 },
    { "offshore-pump", 5 },
    { "submachine-gun", 1 },
    { "piercing-rounds-magazine", 50 },
  },
  armor = "power-armor",
  equipment = {
    "fission-reactor-equipment",
    "exoskeleton-equipment",
    "personal-roboport-equipment",
  },
}

local function safe_get(object, key)
  local ok, value = pcall(function()
    return object[key]
  end)
  if ok then
    return value
  end
  return nil
end

-- Pricing -------------------------------------------------------------------

local function expected_amount(product)
  local amount = product.amount
  if not amount then
    amount = ((product.amount_min or 0) + (product.amount_max or 0)) / 2
  end
  amount = amount * (product.probability or 1)
  return amount + (product.extra_count_fraction or 0)
end

local function recipe_categories(recipe)
  local categories = safe_get(recipe, "categories")
  if type(categories) == "table" then
    return categories
  end
  local category = safe_get(recipe, "category")
  if category then
    return { category }
  end
  return {}
end

local function recipe_is_priced(recipe)
  if safe_get(recipe, "parameter") then
    return false
  end
  for _, category in pairs(recipe_categories(recipe)) do
    local name = type(category) == "table" and category.name or category
    if EXCLUDED_RECIPE_CATEGORIES[name] then
      return false
    end
  end
  return true
end

local function seed_raw_costs(costs)
  local function seed(kind, name, value)
    local bucket = costs[kind]
    if bucket and (not bucket[name] or bucket[name] > value) then
      bucket[name] = value
    end
  end

  local raw_types = { "resource", "tree", "fish", "simple-entity", "plant" }
  for _, entity_type in pairs(raw_types) do
    local ok, entities = pcall(prototypes.get_entity_filtered, { { filter = "type", type = entity_type } })
    if ok and entities then
      for _, entity in pairs(entities) do
        local mineable = safe_get(entity, "mineable_properties")
        if mineable and mineable.minable and mineable.products then
          for _, product in pairs(mineable.products) do
            if product.type == "fluid" then
              seed("fluid", product.name, RAW_FLUID_COST)
            else
              seed("item", product.name, RAW_ITEM_COST)
            end
          end
        end
      end
    end
  end

  for _, tile in pairs(prototypes.tile) do
    local fluid = safe_get(tile, "fluid")
    if fluid then
      seed("fluid", fluid.name, TILE_FLUID_COST)
    end
  end
end

-- Recipes are reduced to net inputs/outputs so catalyst loops (e.g. Kovarex) cannot drive prices to zero.
local function build_recipe_entries()
  local entries = {}
  for _, recipe in pairs(prototypes.recipe) do
    if recipe_is_priced(recipe) then
      local net = {}
      local function add(kind, name, amount)
        local key = kind .. "/" .. name
        local entry = net[key]
        if not entry then
          entry = { kind = kind, name = name, amount = 0 }
          net[key] = entry
        end
        entry.amount = entry.amount + amount
      end
      for _, ingredient in pairs(recipe.ingredients or {}) do
        add(ingredient.type, ingredient.name, -ingredient.amount)
      end
      for _, product in pairs(recipe.products or {}) do
        add(product.type, product.name, expected_amount(product))
      end

      local inputs, outputs, output_total = {}, {}, 0
      for _, entry in pairs(net) do
        if entry.amount < -1e-9 then
          inputs[#inputs + 1] = { kind = entry.kind, name = entry.name, amount = -entry.amount }
        elseif entry.amount > 1e-9 then
          outputs[#outputs + 1] = entry
          output_total = output_total + entry.amount
        end
      end
      if #outputs > 0 then
        entries[#entries + 1] = {
          inputs = inputs,
          outputs = outputs,
          output_total = output_total,
          energy = (recipe.energy or 0) * ENERGY_COST,
        }
      end
    end
  end
  return entries
end

local function compute_costs()
  local costs = { item = {}, fluid = {} }
  seed_raw_costs(costs)
  local entries = build_recipe_entries()

  for _ = 1, MAX_PASSES do
    local changed = false
    for _, entry in pairs(entries) do
      local total = entry.energy
      local complete = true
      for _, input in pairs(entry.inputs) do
        local cost = costs[input.kind] and costs[input.kind][input.name]
        if not cost then
          complete = false
          break
        end
        total = total + cost * input.amount
      end
      if complete then
        local unit = total / entry.output_total
        for _, output in pairs(entry.outputs) do
          local bucket = costs[output.kind]
          if bucket then
            local old = bucket[output.name]
            if not old or unit < old - 1e-9 then
              bucket[output.name] = unit
              changed = true
            end
          end
        end
      end
    end
    if not changed then
      break
    end
  end

  return costs.item
end

local function item_is_buyable(name)
  local proto = prototypes.item[name]
  if not proto then
    return false
  end
  return not safe_get(proto, "parameter")
end

local function unit_cost(name)
  local cost = storage.costs[name]
  if not cost then
    cost = settings.global["atmos-faster-start-unknown-cost"].value
  end
  return cost * settings.global["atmos-faster-start-cost-multiplier"].value
end

local function price(name, count)
  return math.max(1, math.ceil(unit_cost(name) * count - 1e-6))
end

local function pack_cost()
  local total = 0
  local function add(name, count)
    if prototypes.item[name] then
      total = total + unit_cost(name) * count
    end
  end
  for _, entry in pairs(DEFAULT_PACK.items) do
    add(entry[1], entry[2])
  end
  add(DEFAULT_PACK.armor, 1)
  for _, name in pairs(DEFAULT_PACK.equipment) do
    add(name, 1)
  end
  return math.ceil(total - 1e-6)
end

local function starting_points()
  local configured = settings.global["atmos-faster-start-points"].value
  if configured > 0 then
    return configured
  end
  return pack_cost()
end

-- State ---------------------------------------------------------------------

local function player_state(player_index)
  storage.players = storage.players or {}
  local state = storage.players[player_index]
  if not state then
    state = { points = starting_points(), pack_taken = false, count = 1 }
    storage.players[player_index] = state
  end
  return state
end

local function refresh_costs()
  storage.costs = compute_costs()
end

-- GUI -----------------------------------------------------------------------

local function get_frame(player)
  local frame = player.gui.screen[FRAME]
  if frame and frame.valid then
    return frame
  end
  return nil
end

local function update_top_button(player)
  local flow = mod_gui.get_button_flow(player)
  local button = flow[TOP_BUTTON]
  if not button then
    button = flow.add({
      type = "sprite-button",
      name = TOP_BUTTON,
      style = mod_gui.button_style,
      tooltip = { "atmos-faster-start.button-tooltip" },
      tags = { afs = "toggle" },
    })
  end
  button.sprite = "virtual-signal/atmos-faster-start-settings-button"
  button.number = player_state(player.index).points
end

local function update_frame(player)
  local frame = get_frame(player)
  if not frame then
    return
  end
  local state = player_state(player.index)
  local body = frame.body

  body.points.caption = { "atmos-faster-start.points", state.points }

  local cost = pack_cost()
  local pack = body.pack_flow.pack
  pack.caption = { "atmos-faster-start.take-pack", cost }
  pack.enabled = (not state.pack_taken) and state.points >= cost
  if state.pack_taken then
    pack.tooltip = { "atmos-faster-start.pack-taken" }
  else
    pack.tooltip = { "atmos-faster-start.pack-tooltip" }
  end

  local buy_flow = body.buy_flow
  local item = buy_flow.item.elem_value
  local count = tonumber(buy_flow.count.text) or 0
  count = math.floor(count)
  local buy = buy_flow.buy
  if item and count > 0 and item_is_buyable(item) then
    local total = price(item, count)
    local known = storage.costs[item] ~= nil
    buy_flow.cost.caption = { "atmos-faster-start.cost", total }
    buy_flow.cost.tooltip = {
      known and "atmos-faster-start.unit-cost" or "atmos-faster-start.unit-cost-unknown",
      string.format("%.2f", unit_cost(item)),
    }
    buy.enabled = total <= state.points
  else
    buy_flow.cost.caption = { "atmos-faster-start.cost", "-" }
    buy_flow.cost.tooltip = nil
    buy.enabled = false
  end

  update_top_button(player)
end

local function open_frame(player)
  if get_frame(player) then
    update_frame(player)
    return
  end
  local state = player_state(player.index)

  local frame = player.gui.screen.add({ type = "frame", name = FRAME, direction = "vertical" })
  frame.auto_center = true

  local title_bar = frame.add({ type = "flow", direction = "horizontal" })
  title_bar.drag_target = frame
  title_bar.add({ type = "label", caption = { "atmos-faster-start.title" }, style = "frame_title", ignored_by_interaction = true })
  local filler = title_bar.add({ type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true })
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  title_bar.add({
    type = "sprite-button",
    sprite = "utility/close",
    style = "frame_action_button",
    tags = { afs = "close" },
  })

  local body = frame.add({ type = "frame", name = "body", direction = "vertical", style = "inside_shallow_frame_with_padding" })
  body.add({ type = "label", name = "points", style = "caption_label" })

  local pack_flow = body.add({ type = "flow", name = "pack_flow", direction = "horizontal" })
  pack_flow.add({ type = "button", name = "pack", tags = { afs = "pack" } })

  body.add({ type = "line" })
  body.add({ type = "label", caption = { "atmos-faster-start.buy-label" } })

  local buy_flow = body.add({ type = "flow", name = "buy_flow", direction = "horizontal" })
  buy_flow.style.vertical_align = "center"
  buy_flow.add({
    type = "choose-elem-button",
    name = "item",
    elem_type = "item",
    elem_filters = { { filter = "hidden", invert = true } },
    tags = { afs = "item" },
  })
  local count = buy_flow.add({
    type = "textfield",
    name = "count",
    text = tostring(state.count or 1),
    numeric = true,
    allow_decimal = false,
    allow_negative = false,
    tags = { afs = "count" },
  })
  count.style.width = 80
  buy_flow.add({ type = "button", caption = { "atmos-faster-start.stack" }, style = "tool_button", tags = { afs = "stack" } }).style.width = 60
  buy_flow.add({ type = "label", name = "cost" })
  buy_flow.add({ type = "button", name = "buy", caption = { "atmos-faster-start.buy" }, style = "confirm_button", tags = { afs = "buy" } })

  update_frame(player)
  player.opened = frame
end

local function close_frame(player)
  local frame = get_frame(player)
  if frame then
    frame.destroy()
  end
end

-- Purchases -----------------------------------------------------------------

local function require_character(player)
  if player.character and player.character.valid then
    return true
  end
  player.print({ "atmos-faster-start.no-character" })
  return false
end

local function give_or_spill(player, name, count)
  local inserted = player.insert({ name = name, count = count })
  if inserted < count then
    player.surface.spill_item_stack({
      position = player.position,
      stack = { name = name, count = count - inserted },
      enable_looted = true,
      allow_belts = false,
    })
  end
end

local function buy_pack(player)
  local state = player_state(player.index)
  local cost = pack_cost()
  if state.pack_taken or state.points < cost or not require_character(player) then
    return
  end
  state.points = state.points - cost
  state.pack_taken = true

  for _, entry in pairs(DEFAULT_PACK.items) do
    if prototypes.item[entry[1]] then
      give_or_spill(player, entry[1], entry[2])
    end
  end

  if prototypes.item[DEFAULT_PACK.armor] then
    local armor_inventory = player.get_inventory(defines.inventory.character_armor)
    local stack
    if armor_inventory and armor_inventory.is_empty() then
      armor_inventory.insert({ name = DEFAULT_PACK.armor, count = 1 })
      stack = armor_inventory.find_item_stack(DEFAULT_PACK.armor)
      if stack and stack.valid_for_read and not stack.grid then
        pcall(stack.create_grid)
      end
    end
    if stack and stack.valid_for_read and stack.grid then
      for _, name in pairs(DEFAULT_PACK.equipment) do
        if prototypes.equipment[name] and not stack.grid.put({ name = name }) then
          give_or_spill(player, name, 1)
        end
      end
    else
      give_or_spill(player, DEFAULT_PACK.armor, 1)
      for _, name in pairs(DEFAULT_PACK.equipment) do
        if prototypes.item[name] then
          give_or_spill(player, name, 1)
        end
      end
    end
  end

  player.print({ "atmos-faster-start.pack-bought", cost, state.points })
end

local function buy_item(player)
  local frame = get_frame(player)
  if not frame then
    return
  end
  local buy_flow = frame.body.buy_flow
  local name = buy_flow.item.elem_value
  local count = math.floor(tonumber(buy_flow.count.text) or 0)
  if not (name and count > 0 and item_is_buyable(name)) or not require_character(player) then
    return
  end
  local state = player_state(player.index)
  local cost = price(name, count)
  if cost > state.points then
    return
  end

  local inserted = player.insert({ name = name, count = count })
  if inserted <= 0 then
    player.print({ "atmos-faster-start.inventory-full" })
    return
  end
  local paid = price(name, inserted)
  state.points = state.points - paid
  if inserted < count then
    player.print({ "atmos-faster-start.partial", inserted, count })
  end
  player.print({ "atmos-faster-start.item-bought", inserted, "[item=" .. name .. "]", paid, state.points })
end

-- Events --------------------------------------------------------------------

local function init_player(player)
  player_state(player.index)
  update_top_button(player)
end

local function on_init()
  storage.players = {}
  refresh_costs()
  if settings.startup["atmos-faster-start-skip-crash-site"].value and remote.interfaces["freeplay"] then
    pcall(remote.call, "freeplay", "set_disable_crashsite", true)
    pcall(remote.call, "freeplay", "set_skip_intro", true)
  end
  for _, player in pairs(game.players) do
    init_player(player)
  end
end

script.on_init(on_init)

script.on_configuration_changed(function()
  storage.players = storage.players or {}
  refresh_costs()
  for _, player in pairs(game.players) do
    init_player(player)
    update_frame(player)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  local player = game.get_player(event.player_index)
  if player then
    init_player(player)
    open_frame(player)
  end
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  local player = game.get_player(event.player_index)
  if player then
    init_player(player)
  end
end)

script.on_event(defines.events.on_player_removed, function(event)
  if storage.players then
    storage.players[event.player_index] = nil
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid and element.tags and element.tags.afs) then
    return
  end
  local player = game.get_player(event.player_index)
  if not player then
    return
  end
  local action = element.tags.afs
  if action == "toggle" then
    if get_frame(player) then
      close_frame(player)
    else
      open_frame(player)
    end
  elseif action == "close" then
    close_frame(player)
  elseif action == "pack" then
    buy_pack(player)
    update_frame(player)
  elseif action == "buy" then
    buy_item(player)
    update_frame(player)
  elseif action == "stack" then
    local frame = get_frame(player)
    local name = frame and frame.body.buy_flow.item.elem_value
    if name and prototypes.item[name] then
      local count = prototypes.item[name].stack_size
      frame.body.buy_flow.count.text = tostring(count)
      player_state(player.index).count = count
      update_frame(player)
    end
  end
end)

script.on_event(defines.events.on_gui_elem_changed, function(event)
  local element = event.element
  if element and element.valid and element.tags and element.tags.afs == "item" then
    local player = game.get_player(event.player_index)
    if player then
      update_frame(player)
    end
  end
end)

script.on_event(defines.events.on_gui_text_changed, function(event)
  local element = event.element
  if element and element.valid and element.tags and element.tags.afs == "count" then
    local player = game.get_player(event.player_index)
    if player then
      player_state(player.index).count = math.floor(tonumber(element.text) or 1)
      update_frame(player)
    end
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  local element = event.element
  if element and element.valid and element.name == FRAME then
    element.destroy()
  end
end)

script.on_event(defines.events.on_runtime_mod_setting_changed, function(event)
  if string.find(event.setting, "atmos-faster-start-", 1, true) then
    for _, player in pairs(game.players) do
      update_frame(player)
    end
  end
end)

-- Commands ------------------------------------------------------------------

local function command_caller(command)
  if not command.player_index then
    return nil, true
  end
  local player = game.get_player(command.player_index)
  return player, player and player.admin
end

local function reply(caller, message)
  if caller then
    caller.print(message)
  else
    log(message)
  end
end

local function resolve_targets(target_name, caller)
  if not target_name or target_name == "" then
    if caller then
      return { caller }
    end
    return {}
  end
  if target_name == "all" then
    local list = {}
    for _, player in pairs(game.players) do
      list[#list + 1] = player
    end
    return list
  end
  local player = game.get_player(target_name)
  if player then
    return { player }
  end
  return nil
end

local function split_args(parameter)
  local args = {}
  for word in string.gmatch(parameter or "", "%S+") do
    args[#args + 1] = word
  end
  return args
end

commands.add_command("atmos-start-add-points", { "atmos-faster-start.command-add-help" }, function(command)
  local caller, allowed = command_caller(command)
  if not allowed then
    reply(caller, { "atmos-faster-start.admin-only" })
    return
  end
  local args = split_args(command.parameter)
  local amount, target_name
  if tonumber(args[1]) then
    amount, target_name = tonumber(args[1]), args[2]
  else
    target_name, amount = args[1], tonumber(args[2])
  end
  amount = amount and math.floor(amount)
  if not amount then
    reply(caller, { "atmos-faster-start.command-add-help" })
    return
  end
  local targets = resolve_targets(target_name, caller)
  if not targets then
    reply(caller, { "atmos-faster-start.unknown-player", target_name })
    return
  end
  for _, player in pairs(targets) do
    local state = player_state(player.index)
    state.points = math.max(0, state.points + amount)
    update_top_button(player)
    update_frame(player)
    player.print({ "atmos-faster-start.points-changed", state.points })
  end
end)

commands.add_command("atmos-start-reset-points", { "atmos-faster-start.command-reset-help" }, function(command)
  local caller, allowed = command_caller(command)
  if not allowed then
    reply(caller, { "atmos-faster-start.admin-only" })
    return
  end
  local args = split_args(command.parameter)
  local targets = resolve_targets(args[1], caller)
  if not targets then
    reply(caller, { "atmos-faster-start.unknown-player", args[1] })
    return
  end
  local points = starting_points()
  for _, player in pairs(targets) do
    local state = player_state(player.index)
    state.points = points
    state.pack_taken = false
    update_top_button(player)
    update_frame(player)
    player.print({ "atmos-faster-start.points-changed", state.points })
  end
end)

commands.add_command("atmos-start", { "atmos-faster-start.command-open-help" }, function(command)
  local player = command.player_index and game.get_player(command.player_index)
  if player then
    open_frame(player)
  end
end)
