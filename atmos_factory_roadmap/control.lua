local mod_gui = require("mod-gui")

local BUTTON = "atmos_roadmap_button"
local FRAME = "atmos_roadmap_frame"
local UPDATE_TICKS = 300

-- Goal kinds: build = entities placed by the force, research = technology done,
-- produce = total items crafted by the force (all surfaces, all time).
local STAGES = {
  {
    key = "start",
    goals = {
      { "build", "burner-mining-drill", 8 },
      { "build", "stone-furnace", 6 },
    },
  },
  {
    key = "power",
    goals = {
      { "build", "offshore-pump", 1 },
      { "build", "boiler", 1 },
      { "build", "steam-engine", 2 },
      { "build", "lab", 1 },
      { "build", "assembling-machine-1", 3 },
      { "research", "automation" },
    },
  },
  {
    key = "smelting",
    goals = {
      { "build", "electric-mining-drill", 12 },
      { "build", "stone-furnace", 36 },
      { "produce", "iron-plate", 2000 },
      { "produce", "copper-plate", 1000 },
    },
  },
  {
    key = "mini_mall",
    goals = {
      { "build", "assembling-machine-1", 10 },
      { "produce", "iron-gear-wheel", 500 },
      { "produce", "electronic-circuit", 300 },
      { "produce", "transport-belt", 300 },
      { "produce", "inserter", 100 },
      { "research", "logistics" },
    },
  },
  {
    key = "science",
    goals = {
      { "build", "electric-mining-drill", 30 },
      { "build", "stone-furnace", 72 },
      { "build", "lab", 10 },
      { "research", "logistic-science-pack" },
      { "produce", "automation-science-pack", 500 },
      { "produce", "logistic-science-pack", 300 },
      { "research", "automation-2" },
    },
  },
  {
    key = "power2",
    goals = {
      { "build", "boiler", 5 },
      { "build", "steam-engine", 10 },
      { "build", "assembling-machine-2", 10 },
    },
  },
  {
    key = "military",
    goals = {
      { "research", "steel-processing" },
      { "research", "military-2" },
      { "research", "stone-wall" },
      { "produce", "steel-plate", 500 },
      { "produce", "stone-wall", 200 },
      { "produce", "military-science-pack", 200 },
      { "build", "gun-turret", 10 },
    },
  },
  {
    key = "oil",
    goals = {
      { "research", "oil-processing" },
      { "build", "pumpjack", 4 },
      { "build", "oil-refinery", 1 },
      { "build", "chemical-plant", 4 },
      { "produce", "plastic-bar", 500 },
      { "produce", "sulfur", 200 },
      { "build", "electric-mining-drill", 60 },
    },
  },
  {
    key = "chemical",
    goals = {
      { "build", "steel-furnace", 24 },
      { "produce", "advanced-circuit", 500 },
      { "produce", "engine-unit", 200 },
      { "produce", "chemical-science-pack", 300 },
      { "research", "advanced-oil-processing" },
      { "build", "steam-engine", 30 },
    },
  },
  {
    key = "production",
    goals = {
      { "research", "production-science-pack" },
      { "build", "electric-furnace", 12 },
      { "produce", "production-science-pack", 300 },
      { "build", "assembling-machine-2", 40 },
      { "research", "solar-energy" },
    },
  },
  {
    key = "utility",
    goals = {
      { "research", "utility-science-pack" },
      { "produce", "processing-unit", 500 },
      { "produce", "low-density-structure", 200 },
      { "produce", "utility-science-pack", 300 },
      { "research", "nuclear-power" },
    },
  },
  {
    key = "rocket",
    goals = {
      { "research", "rocket-silo" },
      { "build", "rocket-silo", 1 },
      { "produce", "rocket-part", 50 },
    },
  },
}

local function goal_valid(goal)
  local kind, name = goal[1], goal[2]
  if kind == "build" then return prototypes.entity[name] ~= nil end
  if kind == "research" then return prototypes.technology[name] ~= nil end
  if kind == "produce" then return prototypes.item[name] ~= nil end
  return false
end

local function goal_progress(force, goal, cache)
  local kind, name, need = goal[1], goal[2], goal[3] or 1
  if kind == "research" then
    local tech = force.technologies[name]
    return (tech and tech.researched) and 1 or 0, 1
  end
  local key = kind .. ":" .. name
  local value = cache[key]
  if value == nil then
    value = 0
    for _, surface in pairs(game.surfaces) do
      if kind == "build" then
        value = value + surface.count_entities_filtered({ force = force, name = name })
      else
        value = value + force.get_item_production_statistics(surface).get_input_count(name)
      end
    end
    cache[key] = value
  end
  return value, need
end

local function evaluate(force)
  local cache = {}
  local result = {}
  local current
  for i, stage in ipairs(STAGES) do
    local goals, done_all = {}, true
    for _, goal in ipairs(stage.goals) do
      if goal_valid(goal) then
        local value, need = goal_progress(force, goal, cache)
        local done = value >= need
        done_all = done_all and done
        goals[#goals + 1] = { goal = goal, value = value, need = need, done = done }
      end
    end
    result[i] = { goals = goals, done = done_all }
    if not done_all and not current then current = i end
  end
  return result, current or #STAGES
end

local function goal_caption(entry)
  local kind, name = entry.goal[1], entry.goal[2]
  if kind == "research" then
    return { "atmos-roadmap.goal-research", "[technology=" .. name .. "]", prototypes.technology[name].localised_name }
  end
  local value = math.min(entry.value, entry.need)
  if kind == "build" then
    return { "atmos-roadmap.goal-build", "[entity=" .. name .. "]", prototypes.entity[name].localised_name, value, entry.need }
  end
  return { "atmos-roadmap.goal-produce", "[item=" .. name .. "]", prototypes.item[name].localised_name, value, entry.need }
end

local function player_data(player)
  storage.players = storage.players or {}
  local data = storage.players[player.index]
  if not data then
    data = {}
    storage.players[player.index] = data
  end
  return data
end

local function ensure_button(player)
  local flow = mod_gui.get_button_flow(player)
  if not flow[BUTTON] then
    flow.add({
      type = "sprite-button",
      name = BUTTON,
      sprite = "item/lab",
      style = mod_gui.button_style,
      tooltip = { "atmos-roadmap.button-tooltip" },
    })
  end
end

local function fill_frame(player, frame)
  local data = player_data(player)
  local result, current = evaluate(player.force)
  data.view = data.view or current
  if data.follow ~= false then data.view = current end
  local index = math.max(1, math.min(data.view, #STAGES))
  local stage, state = STAGES[index], result[index]

  local body = frame.atmos_roadmap_body
  if body then body.destroy() end
  body = frame.add({ type = "frame", name = "atmos_roadmap_body", direction = "vertical", style = "inside_shallow_frame_with_padding" })
  body.style.maximal_width = 460

  local nav = body.add({ type = "flow", direction = "horizontal" })
  nav.style.vertical_align = "center"
  nav.add({ type = "sprite-button", name = "atmos_roadmap_prev", sprite = "utility/left_arrow", style = "tool_button", enabled = index > 1 })
  local title = nav.add({
    type = "label",
    caption = { "atmos-roadmap.stage-header", index, #STAGES, { "atmos-roadmap.stage-" .. stage.key .. "-title" } },
    style = "caption_label",
  })
  title.style.horizontally_stretchable = true
  nav.add({ type = "sprite-button", name = "atmos_roadmap_next", sprite = "utility/right_arrow", style = "tool_button", enabled = index < #STAGES })
  nav.add({
    type = "sprite-button",
    name = "atmos_roadmap_current",
    sprite = "utility/reset",
    style = "tool_button",
    tooltip = { "atmos-roadmap.current-tooltip", current },
  })

  local status_key = state.done and "atmos-roadmap.status-done"
    or (index == current and "atmos-roadmap.status-current" or (index < current and "atmos-roadmap.status-skipped" or "atmos-roadmap.status-future"))
  body.add({ type = "label", caption = { status_key } })

  local desc = body.add({ type = "label", caption = { "atmos-roadmap.stage-" .. stage.key .. "-desc" } })
  desc.style.single_line = false

  body.add({ type = "line" })
  body.add({ type = "label", caption = { "atmos-roadmap.goals" }, style = "bold_label" })
  for _, entry in ipairs(state.goals) do
    body.add({ type = "checkbox", caption = goal_caption(entry), state = entry.done, ignored_by_interaction = true })
    if entry.goal[1] ~= "research" and not entry.done then
      local bar = body.add({ type = "progressbar", value = math.min(1, entry.value / entry.need) })
      bar.style.horizontally_stretchable = true
    end
  end

  body.add({ type = "line" })
  body.add({ type = "label", caption = { "atmos-roadmap.tips" }, style = "bold_label" })
  local tips = body.add({ type = "label", caption = { "atmos-roadmap.stage-" .. stage.key .. "-tips" } })
  tips.style.single_line = false
end

local function open_frame(player)
  local screen = player.gui.screen
  if screen[FRAME] then return screen[FRAME] end
  local frame = screen.add({ type = "frame", name = FRAME, direction = "vertical" })
  local bar = frame.add({ type = "flow", direction = "horizontal" })
  bar.drag_target = frame
  bar.add({ type = "label", caption = { "atmos-roadmap.title" }, style = "frame_title", ignored_by_interaction = true })
  local filler = bar.add({ type = "empty-widget", style = "draggable_space_header", ignored_by_interaction = true })
  filler.style.horizontally_stretchable = true
  filler.style.height = 24
  bar.add({ type = "sprite-button", name = "atmos_roadmap_close", sprite = "utility/close", style = "frame_action_button" })

  local data = player_data(player)
  if data.location then frame.location = data.location else frame.auto_center = true end
  fill_frame(player, frame)
  return frame
end

local function close_frame(player)
  local frame = player.gui.screen[FRAME]
  if frame then
    player_data(player).location = frame.location
    frame.destroy()
  end
end

local function refresh(player)
  local frame = player.gui.screen[FRAME]
  if frame then fill_frame(player, frame) end
end

local function check_force_progress(force)
  storage.force_stage = storage.force_stage or {}
  local _, current = evaluate(force)
  local last = storage.force_stage[force.index]
  if last and current > last then
    for i = last, current - 1 do
      force.print({ "atmos-roadmap.stage-complete", { "atmos-roadmap.stage-" .. STAGES[i].key .. "-title" } })
    end
    force.print({ "atmos-roadmap.stage-next", { "atmos-roadmap.stage-" .. STAGES[current].key .. "-title" } })
  end
  storage.force_stage[force.index] = current
end

local function init_players()
  for _, player in pairs(game.players) do ensure_button(player) end
end

script.on_init(init_players)
script.on_configuration_changed(init_players)

script.on_event(defines.events.on_player_created, function(event)
  ensure_button(game.get_player(event.player_index))
end)

script.on_nth_tick(UPDATE_TICKS, function()
  for _, force in pairs(game.forces) do
    if #force.connected_players > 0 then check_force_progress(force) end
  end
  for _, player in pairs(game.connected_players) do refresh(player) end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local element = event.element
  if not (element and element.valid) then return end
  local player = game.get_player(event.player_index)
  local name = element.name
  if name == BUTTON then
    if player.gui.screen[FRAME] then close_frame(player) else open_frame(player) end
  elseif name == "atmos_roadmap_close" then
    close_frame(player)
  elseif name == "atmos_roadmap_prev" or name == "atmos_roadmap_next" then
    local data = player_data(player)
    data.follow = false
    data.view = math.max(1, math.min(#STAGES, (data.view or 1) + (name == "atmos_roadmap_next" and 1 or -1)))
    refresh(player)
  elseif name == "atmos_roadmap_current" then
    player_data(player).follow = true
    refresh(player)
  end
end)
