if vim.g.loaded_floating_cursor then
  return
end
vim.g.loaded_floating_cursor = 1

vim.api.nvim_create_user_command("FloatingCursorToggle", function()
  require("floating_cursor").toggle()
end, { desc = "Toggle the floating cursor" })

vim.api.nvim_create_user_command("FloatingCursorEnable", function()
  require("floating_cursor").enable()
end, { desc = "Enable the floating cursor" })

vim.api.nvim_create_user_command("FloatingCursorDisable", function()
  require("floating_cursor").disable()
end, { desc = "Disable the floating cursor" })

vim.api.nvim_create_user_command("FloatingCursorOcean", function()
  require("floating_cursor").toggle_ocean()
end, { desc = "Toggle the bottom swell overlay" })

-- Start on VimEnter so the overlay is visible while editing, even if the
-- user has not called setup() from their config yet.
vim.api.nvim_create_autocmd("VimEnter", {
  group = vim.api.nvim_create_augroup("FloatingCursorAutoStart", { clear = true }),
  once = true,
  callback = function()
    if vim.g.floating_cursor_disable_auto or vim.g.floating_cursor_setup_done then
      return
    end
    require("floating_cursor").setup()
  end,
})
