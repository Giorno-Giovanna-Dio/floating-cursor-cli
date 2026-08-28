local highlight = require("floating_cursor.highlight")

local M = {}

local pool = {}

local function make_slot()
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false
  vim.bo[buf].undolevels = -1
  local win = vim.api.nvim_open_win(buf, false, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 1,
    height = 1,
    focusable = false,
    style = "minimal",
    noautocmd = true,
    zindex = 200,
    border = "none",
    hide = true,
  })
  return { buf = buf, win = win }
end

local function valid_slot(slot)
  return slot
    and slot.buf
    and slot.win
    and vim.api.nvim_buf_is_valid(slot.buf)
    and vim.api.nvim_win_is_valid(slot.win)
end

local function ensure_slot(i)
  local slot = pool[i]
  if valid_slot(slot) then
    return slot
  end
  local ok, created = pcall(make_slot)
  if not ok then
    return nil
  end
  pool[i] = created
  return created
end

function M.clear()
  for _, slot in ipairs(pool) do
    if slot.win and vim.api.nvim_win_is_valid(slot.win) then
      pcall(vim.api.nvim_win_close, slot.win, true)
    end
    if slot.buf and vim.api.nvim_buf_is_valid(slot.buf) then
      pcall(vim.api.nvim_buf_delete, slot.buf, { force = true })
    end
  end
  pool = {}
end

local function hide_slot(slot)
  if not valid_slot(slot) then
    return
  end
  pcall(vim.api.nvim_win_set_config, slot.win, {
    relative = "editor",
    row = 0,
    col = 0,
    width = 1,
    height = 1,
    hide = true,
    border = "none",
  })
end

local function place(slot, row, col, glyph, hl, zindex, blend)
  if not valid_slot(slot) then
    return
  end
  pcall(function()
    vim.bo[slot.buf].modifiable = true
    vim.api.nvim_buf_set_lines(slot.buf, 0, -1, false, { glyph })
    vim.api.nvim_win_set_config(slot.win, {
      relative = "editor",
      row = row,
      col = col,
      width = 1,
      height = 1,
      focusable = false,
      style = "minimal",
      noautocmd = true,
      zindex = zindex,
      border = "none",
      hide = false,
    })
    vim.api.nvim_set_option_value("winhighlight", "Normal:" .. hl .. ",FloatBorder:" .. hl, { win = slot.win })
    vim.api.nvim_set_option_value("winblend", blend, { win = slot.win })
  end)
end

local function trail_glyph(cfg, index, total)
  local glyphs = cfg.ascii and cfg.glyphs.ascii_trail or cfg.glyphs.trail
  if total <= 1 then
    return glyphs[1]
  end
  local t = (index - 1) / (total - 1)
  local i = 1 + math.floor(t * (#glyphs - 1) + 0.5)
  return glyphs[i] or glyphs[#glyphs]
end

function M.render(particles, cfg, mode)
  local max_row = vim.o.lines - 2
  local max_col = vim.o.columns - 1
  local heads = cfg.ascii and cfg.glyphs.ascii_head or cfg.glyphs.head
  local head_glyph = heads.n
  if type(mode) == "string" then
    if mode:find("i") then
      head_glyph = heads.i
    elseif mode:find("R") then
      head_glyph = heads.r
    elseif mode:find("[vV\22]") then
      head_glyph = heads.v
    end
  end

  local trail_count = 0
  for _, p in ipairs(particles) do
    if p.kind == "trail" then
      trail_count = trail_count + 1
    end
  end

  local used = 0
  local trail_i = 0
  for _, p in ipairs(particles) do
    local row = p.y - 1
    local col = p.x - 1
    if row >= 0 and col >= 0 and row <= max_row and col <= max_col then
      used = used + 1
      local slot = ensure_slot(used)
      if not slot then
        used = used - 1
      elseif p.kind == "head" then
        place(slot, row, col, head_glyph, "FloatingCursorHead", 310, 0)
      else
        trail_i = trail_i + 1
        local hl = highlight.trail_group(trail_i, math.max(trail_count, 1))
        local blend = highlight.trail_blend(trail_i, math.max(trail_count, 1))
        place(slot, row, col, trail_glyph(cfg, trail_i, math.max(trail_count, 1)), hl, 300 - trail_i, blend)
      end
    end
  end

  for i = used + 1, #pool do
    hide_slot(pool[i])
  end
end

return M
