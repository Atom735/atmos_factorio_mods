local icons = {
  {
    icon = "__base__/graphics/icons/small-worm.png",
    icon_size = 64,
    tint = { r = 1, g = 0.35, b = 0.35, a = 1 },
  },
}

data:extend({
  {
    type = "custom-input",
    name = "atmos-enemy-range-toggle",
    action = "lua",
    key_sequence = "CONTROL + SHIFT + R",
    order = "a",
  },
  {
    type = "custom-input",
    name = "atmos-enemy-range-panel",
    action = "lua",
    key_sequence = "CONTROL + SHIFT + E",
    order = "b",
  },
  {
    type = "shortcut",
    name = "atmos-enemy-range-toggle",
    localised_name = { "shortcut-name.atmos-enemy-range-toggle" },
    icons = icons,
    small_icons = icons,
    action = "lua",
    associated_control_input = "atmos-enemy-range-toggle",
    order = "c[toggles]-d[enemy-range]",
    toggleable = true,
  },
})

-- Top-bar settings button: mod icon with corner badges (gear top-right, optional signal top-left).
-- GUI ignores sprite layer shifts, so the composition is an icon of a hidden virtual signal.
local function settings_button_signal(name, base, left_badge)
  local gear = "__base__/graphics/icons/iron-gear-wheel.png"
  local icons = {
    { icon = base.icon, icon_size = 64, tint = base.tint },
    { icon = gear, icon_size = 64, scale = 0.3, shift = { 8, -8 }, tint = { r = 0, g = 0, b = 0, a = 0.85 } },
    { icon = gear, icon_size = 64, scale = 0.24, shift = { 8, -8 } },
  }
  if left_badge then
    icons[#icons + 1] = { icon = left_badge, icon_size = 64, scale = 0.3, shift = { -8, -8 }, tint = { r = 0, g = 0, b = 0, a = 0.85 } }
    icons[#icons + 1] = { icon = left_badge, icon_size = 64, scale = 0.24, shift = { -8, -8 } }
  end
  return {
    type = "virtual-signal",
    name = name,
    icons = icons,
    subgroup = "virtual-signal",
    order = "z[atmos]-" .. name,
    hidden = true,
    hidden_in_factoriopedia = true,
  }
end
data:extend({ settings_button_signal("atmos-enemy-range-settings-button", { icon = "__base__/graphics/icons/small-worm.png", tint = { r = 1, g = 0.35, b = 0.35, a = 1 } }) })
