-- Headless tests. Run from the repo root:
--   nvim --headless -u tests/minimal_init.lua -c qa
vim.opt.runtimepath:prepend(vim.fn.getcwd())
vim.opt.termguicolors = true
vim.opt.loadplugins = false
vim.opt.shadafile = "NONE"

local function fail(err)
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end

local ok, err = xpcall(function()
  local physics = require("floating_cursor.physics")
  local config = require("floating_cursor.config")
  local cfg = vim.deepcopy(config.defaults)

  local function assert_true(cond, msg)
    if not cond then
      error(msg, 2)
    end
  end

  do
    local s = physics.new(0, 0)
    physics.set_target(s, 10, 0, cfg)
    for _ = 1, 50 do
      physics.step(s, 0.016, cfg)
    end
    assert_true(s.x > 3, string.format("spring should drift toward target, x=%.3f", s.x))
  end

  do
    local s = physics.new(0, 0)
    physics.set_target(s, 40, 12, cfg)
    assert_true(s.surfing, "long jump should start a surf path")
    local min_off, max_off = 0, 0
    local dx, dy = 40, 12
    local len = math.sqrt(dx * dx + dy * dy)
    local nx, ny = -dy / len, dx / len
    for _ = 1, 36 do
      physics.step(s, 0.016, cfg)
      local px = s.x - 0
      local py = s.y - 0
      local along = (px * dx + py * dy) / (len * len)
      local off = (px - dx * along) * nx + (py - dy * along) * ny
      if off < min_off then
        min_off = off
      end
      if off > max_off then
        max_off = off
      end
    end
    assert_true(min_off < -0.4, string.format("surf should have a trough, min_off=%.3f", min_off))
    assert_true(max_off > 0.4, string.format("surf should have a crest, max_off=%.3f", max_off))
    for _ = 1, 80 do
      physics.step(s, 0.016, cfg)
    end
    assert_true(not s.surfing, "surf should finish")
    assert_true(math.abs(s.x - 40) < 0.8, string.format("surf should arrive in x, x=%.3f", s.x))
    assert_true(math.abs(s.y - 12) < 0.8, string.format("surf should arrive in y, y=%.3f", s.y))
  end

  do
    local ocean = require("floating_cursor.ocean")
    local lines = ocean.frame(40, 8, 0.8, true)
    assert_true(#lines == 8, "ocean frame should honor height")
    local min_s, max_s = 8, 0
    for x = 1, 40 do
      for y = 1, 8 do
        local ch = lines[y]:sub(x, x)
        if ch ~= " " and ch ~= ">" then
          if y < min_s then
            min_s = y
          end
          if y > max_s then
            max_s = y
          end
          break
        end
      end
    end
    assert_true(max_s - min_s >= 2, string.format("ocean should have highs and lows, %d..%d", min_s, max_s))
  end

  do
    local s = physics.new(8, 8)
    physics.set_target(s, 8, 8, cfg)
    physics.step(s, 0.22, cfg)
    assert_true(math.abs(s.draw_y - s.y) > 0.01, "idle float should bob the drawn cursor")
    local parts = physics.particles(s)
    assert_true(parts[1] and parts[1].kind == "head", "particles should start with the head")
  end

  local plugin = require("floating_cursor")
  plugin.setup({ enabled = false, ascii = true, hide_real_cursor = false })
  assert_true(plugin.is_enabled() == false, "setup({ enabled = false }) must not start the overlay")

  plugin.enable()
  assert_true(plugin.is_enabled(), "enable should turn the overlay on")
  vim.wait(40)
  plugin.disable()
  assert_true(plugin.is_enabled() == false, "disable should turn the overlay off")

  io.stdout:write("floating-cursor tests ok\n")
end, debug.traceback)

if not ok then
  fail(err)
end
