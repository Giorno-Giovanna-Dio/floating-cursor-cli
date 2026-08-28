local M = {}

function M.check()
  vim.health.start("floating-cursor")

  if vim.fn.has("nvim-0.9") == 1 then
    vim.health.ok("Neovim 0.9+")
  else
    vim.health.error("Neovim 0.9+ is required")
  end

  local ok, plugin = pcall(require, "floating_cursor")
  if not ok then
    vim.health.error("could not load floating_cursor")
    return
  end

  if plugin.is_enabled() then
    vim.health.ok("overlay is enabled")
  else
    vim.health.info("overlay is disabled — :FloatingCursorToggle to turn it on")
  end
end

return M
