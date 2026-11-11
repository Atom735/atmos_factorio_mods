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
data:extend({ settings_button_signal("atmos-faster-start-settings-button", { icon = "__base__/graphics/icons/power-armor.png" }) })
