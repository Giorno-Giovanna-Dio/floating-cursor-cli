local config = require("floating_cursor.config")
local draw = require("floating_cursor.draw")
local highlight = require("floating_cursor.highlight")
local ocean = require("floating_cursor.ocean")
local physics = require("floating_cursor.physics")

local M = {}

local cfg = config.merge()
local enabled = false
local ready = false
local state
local timer
local saved_guicursor
local group = "FloatingCursor"

local function current_mode()
  return vim.fn.mode()
end

local function filetype_disabled()
  local ft = vim.bo.filetype
  for _, name in ipairs(cfg.disabled_filetypes) do
    if name == ft then
      return true
    end
  end
  return false
end

local function should_hide()
  if vim.fn.reg_executing() ~= "" then
    return true
  end
  if current_mode() == "c" then
    return true
  end
  if vim.bo.buftype == "prompt" then
    return true
  end
  if vim.bo.buftype == "terminal" and not cfg.enabled_in_terminal then
    return true
  end
  if filetype_disabled() then
    return true
  end
  return false
end

local function cursor_screen()
  local win = vim.api.nvim_get_current_win()
  if not vim.api.nvim_win_is_valid(win) then
    return nil
  end
  local cur = vim.api.nvim_win_get_cursor(win)
  local sp = vim.fn.screenpos(win, cur[1], cur[2] + 1)
  if not sp or sp.row == 0 or sp.col == 0 then
    return nil
  end
  return sp.col, sp.row
end

local function hide_real_cursor()
  if not cfg.hide_real_cursor then
    return
  end
  if saved_guicursor == nil then
    saved_guicursor = vim.o.guicursor
  end
  vim.o.guicursor = "n-v-c-sm:block-FloatingCursorGone,i-ci-ve:ver25-FloatingCursorGone,r-cr-o:hor20-FloatingCursorGone"
end

local function restore_real_cursor()
  if saved_guicursor ~= nil then
    vim.o.guicursor = saved_guicursor
    saved_guicursor = nil
  end
end

local function stop_timer()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
end

local function tick()
  if not enabled then
    return
  end
  if should_hide() then
    draw.render({}, cfg, current_mode())
    return
  end

  local x, y = cursor_screen()
  if not x then
    return
  end

  if not state then
    state = physics.new(x, y)
  end
  physics.set_target(state, x, y, cfg)
  physics.step(state, 1 / math.max(cfg.fps, 1), cfg)
  draw.render(physics.particles(state), cfg, current_mode())
end

local function start_timer()
  if timer or vim.fn.has("nvim-0.9") ~= 1 then
    return
  end
  timer = vim.uv.new_timer()
  local interval = math.max(10, math.floor(1000 / math.max(cfg.fps, 1)))
  timer:start(0, interval, vim.schedule_wrap(tick))
end

function M.is_enabled()
  return enabled
end

function M.enable()
  if vim.fn.has("nvim-0.9") ~= 1 then
    vim.notify("floating-cursor requires Neovim 0.9+", vim.log.levels.ERROR)
    return
  end
  highlight.apply()
  hide_real_cursor()
  enabled = true
  ready = true
  state = nil
  start_timer()
end

function M.disable()
  enabled = false
  stop_timer()
  draw.clear()
  restore_real_cursor()
  state = nil
end

function M.toggle()
  if not ready then
    M.setup({ enabled = true })
    return
  end
  if enabled then
    M.disable()
  else
    M.enable()
  end
end

function M.toggle_ocean()
  if not ready then
    M.setup({ enabled = enabled })
  end
  ocean.toggle(cfg)
end

function M.setup(opts)
  vim.g.floating_cursor_setup_done = true
  cfg = config.merge(opts)
  ready = true

  vim.api.nvim_create_augroup(group, { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      highlight.apply()
    end,
  })
  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      M.disable()
      ocean.close()
    end,
  })
  vim.api.nvim_create_user_command("FloatingCursorToggle", function()
    M.toggle()
  end, { desc = "Toggle the floating cursor" })
  vim.api.nvim_create_user_command("FloatingCursorEnable", function()
    M.enable()
  end, { desc = "Enable the floating cursor" })
  vim.api.nvim_create_user_command("FloatingCursorDisable", function()
    M.disable()
  end, { desc = "Disable the floating cursor" })

  vim.api.nvim_create_user_command("FloatingCursorOcean", function()
    M.toggle_ocean()
  end, { desc = "Toggle the bottom swell overlay" })

  if cfg.enabled then
    M.enable()
  end
  if cfg.ocean then
    ocean.open(cfg)
  end
  return M
end

-- Exposed for tests.
M._physics = physics
M._ocean = ocean
M._config = function()
  return cfg
end

return M
