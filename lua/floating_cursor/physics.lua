local Physics = {}

local function hypot(dx, dy)
  return math.sqrt(dx * dx + dy * dy)
end

local function clamp01(t)
  if t < 0 then
    return 0
  end
  if t > 1 then
    return 1
  end
  return t
end

local function smoothstep(t)
  t = clamp01(t)
  return t * t * (3 - 2 * t)
end

function Physics.new(x, y)
  x = x or 0
  y = y or 0
  return {
    x = x,
    y = y,
    vx = 0,
    vy = 0,
    target_x = x,
    target_y = y,
    from_x = x,
    from_y = y,
    to_x = x,
    to_y = y,
    draw_x = x,
    draw_y = y,
    surfing = false,
    surf_t = 0,
    surf_duration = 0.3,
    idle_t = 0,
    trail = {},
  }
end

function Physics.set_target(state, x, y, cfg)
  state.target_x = x
  state.target_y = y

  local dist = hypot(x - state.x, y - state.y)
  if state.surfing then
    state.to_x = x
    state.to_y = y
    return dist
  end

  if dist >= cfg.surf_distance then
    state.surfing = true
    state.surf_t = 0
    state.from_x = state.x
    state.from_y = state.y
    state.to_x = x
    state.to_y = y
    state.surf_duration = math.min(
      cfg.surf_max_duration,
      cfg.surf_min_duration + dist * cfg.surf_duration_scale
    )
    state.vx = 0
    state.vy = 0
  end
  return dist
end

local function push_trail(state, cfg)
  local newest = state.trail[1]
  local cx = math.floor(state.draw_x + 0.5)
  local cy = math.floor(state.draw_y + 0.5)
  if newest and math.floor(newest.x + 0.5) == cx and math.floor(newest.y + 0.5) == cy then
    return
  end
  table.insert(state.trail, 1, { x = state.draw_x, y = state.draw_y })
  while #state.trail > cfg.trail_length do
    table.remove(state.trail)
  end
end

function Physics.step(state, dt, cfg)
  if dt <= 0 then
    dt = 0.016
  end

  local stiff = cfg.stiffness
  if stiff < 0 then
    stiff = 0
  elseif stiff > 1 then
    stiff = 1
  end
  local damp = cfg.damping
  if damp < 0 then
    damp = 0
  elseif damp > 0.95 then
    damp = 0.95
  end

  if state.surfing then
    state.surf_t = state.surf_t + dt / math.max(state.surf_duration, 0.001)
    local t = smoothstep(state.surf_t)
    if state.surf_t >= 1 then
      state.x = state.to_x
      state.y = state.to_y
      state.surfing = false
      state.surf_t = 1
      state.vx = 0
      state.vy = 0
    else
      local dx = state.to_x - state.from_x
      local dy = state.to_y - state.from_y
      local len = hypot(dx, dy)
      local nx, ny = 0, 1
      if len > 0.0001 then
        nx, ny = -dy / len, dx / len
      end
      -- Envelope dies at both ends so the ride lands on the real cursor.
      -- Multiple cycles give actual crests and troughs, not one bump.
      local envelope = math.sin(t * math.pi)
      local cycles = cfg.wave_cycles
      if type(cycles) ~= "number" or cycles < 1 then
        cycles = 2.5
      end
      local wave = math.sin(t * math.pi * cycles * 2) * cfg.wave_amplitude * envelope
      state.x = state.from_x + dx * t + nx * wave
      state.y = state.from_y + dy * t + ny * wave
    end
    state.draw_x = state.x
    state.draw_y = state.y
    push_trail(state, cfg)
    return
  end

  local dx = state.target_x - state.x
  local dy = state.target_y - state.y
  local dist = hypot(dx, dy)

  state.vx = (state.vx + dx * stiff) * (1 - damp)
  state.vy = (state.vy + dy * stiff) * (1 - damp)

  local scale = dt / 0.016
  state.x = state.x + state.vx * scale
  state.y = state.y + state.vy * scale

  local speed = hypot(state.vx, state.vy)
  if dist < 0.08 and speed < 0.05 then
    state.x = state.target_x
    state.y = state.target_y
    state.vx = 0
    state.vy = 0
    dist = 0
  end

  state.draw_x = state.x
  state.draw_y = state.y
  if dist < cfg.idle_threshold then
    state.idle_t = state.idle_t + dt
    local wobble = math.sin(state.idle_t * cfg.bob_hz * 2 * math.pi) * cfg.bob_amplitude
    state.draw_y = state.y + wobble
    state.draw_x = state.x + math.sin(state.idle_t * cfg.bob_hz * math.pi) * cfg.bob_amplitude * 0.35
  else
    state.idle_t = 0
  end

  push_trail(state, cfg)
end

function Physics.particles(state)
  local seen = {}
  local out = {}

  local function add(x, y, kind)
    local cx = math.floor(x + 0.5)
    local cy = math.floor(y + 0.5)
    local key = cx .. ":" .. cy
    if seen[key] then
      return
    end
    seen[key] = true
    table.insert(out, { x = cx, y = cy, kind = kind })
  end

  add(state.draw_x, state.draw_y, "head")
  for _, p in ipairs(state.trail) do
    add(p.x, p.y, "trail")
  end
  return out
end

return Physics
