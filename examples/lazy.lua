{ "Giorno-Giovanna-Dio/floating-cursor-cli",
  event = "VeryLazy",
  config = function()
    require("floating_cursor").setup({
      -- lower stiffness / higher damping = more drift
      stiffness = 0.22,
      damping = 0.32,
      surf_distance = 8,
      wave_amplitude = 4.6,
      wave_cycles = 2.5,
      hide_real_cursor = true,
    })
  end,
}
