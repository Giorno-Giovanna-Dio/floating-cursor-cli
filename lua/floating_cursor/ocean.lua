local M = {}

local win
local buf
local timer
local start
local cfg

local function valid()
  return buf and win and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win)
end

local function wave_y(x, phase, amplitude)
  local primary = math.sin(x * 0.22 + phase)
  local harmonic = math.sin(x * 0.22 * 2.15 + phase * 1.37)
  return (primary + 0.55 * harmonic) * amplitude
end

local function water_row(height, offset)
  local row = math.floor(height / 2 + offset + 0.5)
  if row < 0 then
    return 0
  end
  if row > height - 1 then
    return height - 1
  end
  return row
end

local function glyph(depth, ascii, x, row)
  if ascii then
    if depth == 0 then
      if (x + row) % 4 == 0 then
        return "-"
      end
      return "~"
    end
    if depth == 1 then
      return "."
    end
    return ":"
  end
  if depth == 0 then
    local k = (x + row) % 5
    if k == 0 then
      return "≈"
    end
    if k == 2 then
      return "∽"
    end
    return "~"
  end
  if depth == 1 then
    return "░"
  end
  if depth < 4 then
    return "▒"
  end
  return "▓"
end

function M.frame(width, height, elapsed, ascii)
  if width < 8 then
    width = 8
  end
  if height < 3 then
    height = 3
  end
  local amp = (height - 1) / 2 * 0.92
  if amp < 1.2 then
    amp = 1.2
  end
  local phase = elapsed * 1.6
  local span = math.max(width - 1, 1)
  local sx = math.floor(elapsed * 12) % span
  local surface_at = {}
  for x = 0, width - 1 do
    surface_at[x] = water_row(height, wave_y(x, phase, amp))
  end
  local sy = math.max(surface_at[sx] - 1, 0)
  local lines = {}
  for y = 0, height - 1 do
    local cols = {}
    for x = 0, width - 1 do
      local surface = surface_at[x]
      if y == sy and x == sx then
        cols[x + 1] = ascii and ">" or "▲"
      elseif y >= surface then
        cols[x + 1] = glyph(y - surface, ascii, x, y)
      else
        cols[x + 1] = " "
      end
    end
    lines[y + 1] = table.concat(cols)
  end
  return lines
end

local function paint()
  if not valid() then
    return
  end
  local width = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local elapsed = (vim.uv.hrtime() - start) / 1e9
  local lines = M.frame(width, height, elapsed, cfg.ascii)
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function layout()
  local height = math.max(4, math.min(cfg.ocean_height or 7, math.floor(vim.o.lines / 3)))
  local row = math.max(0, vim.o.lines - height - 1)
  return {
    relative = "editor",
    row = row,
    col = 0,
    width = vim.o.columns,
    height = height,
    focusable = false,
    style = "minimal",
    noautocmd = true,
    zindex = 80,
    border = "none",
  }
end

function M.is_open()
  return valid()
end

function M.close()
  if timer then
    timer:stop()
    timer:close()
    timer = nil
  end
  if win and vim.api.nvim_win_is_valid(win) then
    pcall(vim.api.nvim_win_close, win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
  end
  win, buf = nil, nil
end

function M.open(opts)
  cfg = opts or {}
  M.close()
  buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  local ok, created = pcall(vim.api.nvim_open_win, buf, false, layout())
  if not ok then
    return
  end
  win = created
  vim.api.nvim_set_option_value("winhighlight", "Normal:FloatingCursorTrail1", { win = win })
  start = vim.uv.hrtime()
  paint()
  timer = vim.uv.new_timer()
  timer:start(0, 80, vim.schedule_wrap(function()
    if not valid() then
      M.close()
      return
    end
    pcall(vim.api.nvim_win_set_config, win, layout())
    paint()
  end))
end

function M.toggle(opts)
  if M.is_open() then
    M.close()
  else
    M.open(opts)
  end
end

return M
