local M = {}

local function to_hex(value)
  if type(value) == "string" then
    return value
  end
  if type(value) ~= "number" then
    return nil
  end
  return string.format("#%06x", value)
end

local function cursor_color()
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = "Cursor", link = false })
  if ok and hl then
    return to_hex(hl.bg) or to_hex(hl.fg)
  end
  return nil
end

function M.apply()
  local fg = cursor_color() or "#7fdfff"
  vim.api.nvim_set_hl(0, "FloatingCursorHead", { fg = fg, bold = true, default = false })
  vim.api.nvim_set_hl(0, "FloatingCursorTrail1", { fg = "#5ec8e8", default = false })
  vim.api.nvim_set_hl(0, "FloatingCursorTrail2", { fg = "#3a9bb5", default = false })
  vim.api.nvim_set_hl(0, "FloatingCursorTrail3", { fg = "#2a6f82", default = false })
  vim.api.nvim_set_hl(0, "FloatingCursorGone", { blend = 100, nocombine = true, default = false })
end

function M.trail_group(index, total)
  local t = 0
  if total > 1 then
    t = (index - 1) / (total - 1)
  end
  if t < 0.34 then
    return "FloatingCursorTrail1"
  end
  if t < 0.67 then
    return "FloatingCursorTrail2"
  end
  return "FloatingCursorTrail3"
end

function M.trail_blend(index, total)
  local t = 0
  if total > 1 then
    t = (index - 1) / (total - 1)
  end
  return math.min(70, math.floor(18 + t * 52))
end

return M
