data:extend({
  {
    type = "int-setting",
    name = "atmos-faster-start-points",
    setting_type = "runtime-global",
    default_value = 0,
    minimum_value = 0,
    order = "a",
  },
  {
    type = "double-setting",
    name = "atmos-faster-start-cost-multiplier",
    setting_type = "runtime-global",
    default_value = 1,
    minimum_value = 0.01,
    maximum_value = 100,
    order = "b",
  },
  {
    type = "int-setting",
    name = "atmos-faster-start-unknown-cost",
    setting_type = "runtime-global",
    default_value = 1000,
    minimum_value = 1,
    order = "c",
  },
  {
    type = "bool-setting",
    name = "atmos-faster-start-skip-crash-site",
    setting_type = "startup",
    default_value = true,
    order = "d",
  },
})
