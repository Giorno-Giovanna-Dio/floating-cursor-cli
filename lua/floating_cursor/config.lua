local M = {}

M.defaults = {
  enabled = true,
  -- Spring: lower stiffness / higher damping = more drift.
  stiffness = 0.22,
  damping = 0.32,
  fps = 50,
  trail_length = 12,
  -- Screen cells of cursor travel before a surf-wave path is used.
  surf_distance = 8,
  surf_min_duration = 0.14,
  surf_max_duration = 0.55,
  surf_duration_scale = 0.016,
  wave_amplitude = 4.6,
  wave_cycles = 2.5,
  -- Bottom swell overlay inside Neovim. Off by default; :FloatingCursorOcean
  ocean = false,
  ocean_height = 7,
  bob_amplitude = 0.42,
  bob_hz = 1.35,
  idle_threshold = 1.15,
  hide_real_cursor = true,
  ascii = false,
  enabled_in_terminal = false,
  disabled_filetypes = {
    "TelescopePrompt",
    "lazy",
    "mason",
    "alpha",
    "dashboard",
    "neo-tree",
    "NvimTree",
    "oil",
    "notify",
    "noice",
  },
  glyphs = {
    head = { n = "●", i = "│", v = "◈", r = "▄" },
    trail = { "≈", "∽", "~", "·" },
    ascii_head = { n = "O", i = "|", v = "X", r = "=" },
    ascii_trail = { "~", "-", ".", " " },
  },
}

function M.merge(opts)
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
end

return M
