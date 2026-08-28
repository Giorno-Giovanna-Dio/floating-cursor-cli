# floating-cursor

**Maybe your cursor wants to go surfing.**

A Neovim plugin (with a tiny CLI preview) that gives the terminal cursor mass, drift, and a water wake. Short motions spring and settle. Long jumps ride a sine-wave path instead of teleporting. When you pause, it keeps a quiet idle bob — like it is floating on the swell.

Built for terminal nerds. Works in any Neovim TTY, not just a GPU GUI.

[![CI](https://github.com/Giorno-Giovanna-Dio/floating-cursor-cli/actions/workflows/ci.yml/badge.svg)](https://github.com/Giorno-Giovanna-Dio/floating-cursor-cli/actions/workflows/ci.yml)
[![Neovim](https://img.shields.io/badge/Neovim-0.9%2B-57A143?logo=neovim&logoColor=white)](https://neovim.io)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<p align="center">
  <a href="https://www.buymeacoffee.com/Davicode">
    <img src="https://img.shields.io/badge/Buy%20me%20a%20coffee-ffdd00?style=for-the-badge&logo=buy-me-a-coffee&logoColor=black" alt="Buy me a coffee" />
  </a>
</p>

```
 floating-cursor  |  ctrl+c to paddle in
           ▲
      ≈∽~~░▒▒▒▒▒▒▓
   ~~≈∽░░░░▒▒▒▒▓▓▓
∽~~~~░░░░▒▒▒▒▒▓▓▓▓
```

## Why this exists

Cursor smear plugins already interpolate a straight trail. GUI editors like Neovide can do real motion blur. This one is different on purpose:

| | smear-cursor.nvim | **floating-cursor** |
|---|---|---|
| Short moves | smear | spring + damping drift |
| Long jumps | straight interpolation | sine-wave **surf path** |
| Sitting still | nothing | idle **float / bob** |
| Trail | block smear | water wake `≈ ∽ ~ ·` |
| Try without Neovim | no | `go run ./cmd/floating-cursor` |

If you live in tmux + Neovim in a boring TTY, this is the whole joke: the cursor should feel a little alive.

## Install (Neovim 0.9+)

### lazy.nvim

```lua
{
  "Giorno-Giovanna-Dio/floating-cursor-cli",
  event = "VeryLazy",
  config = function()
    require("floating_cursor").setup()
  end,
}
```

### vim-plug

```vim
Plug 'Giorno-Giovanna-Dio/floating-cursor-cli'
```

```lua
require("floating_cursor").setup()
```

## Commands

- `:FloatingCursorToggle`
- `:FloatingCursorEnable`
- `:FloatingCursorDisable`
- `:FloatingCursorOcean` — bottom swell with real crests and troughs, while you keep editing

`:checkhealth floating_cursor` confirms Neovim is new enough and whether the overlay is running.

## Local install (this repo)

If you cloned the project and just want it in Neovim:

```bash
cd /Users/davidchung/Desktop/coding_projects/floating-cursor
make install
```

Restart Neovim. The floating cursor starts on `VimEnter`. Long jumps ride a wave with highs and lows. `:FloatingCursorOcean` puts the filled swell along the bottom of the editor without leaving Vim.

```bash
make uninstall
```

## Setup

```lua
require("floating_cursor").setup({
  stiffness = 0.22,       -- lower = floatier
  damping = 0.32,         -- higher = less bounce
  fps = 50,
  trail_length = 12,
  surf_distance = 8,      -- cells of travel before a surf jump
  wave_amplitude = 4.6,   -- crest / trough height
  wave_cycles = 2.5,      -- how many highs and lows per jump
  ocean = false,          -- true to show the bottom swell on startup
  ocean_height = 7,
  bob_amplitude = 0.42,
  hide_real_cursor = true,
  ascii = false,          -- true for fonts without unicode
  enabled_in_terminal = false,
  disabled_filetypes = {
    "TelescopePrompt",
    "lazy",
    "neo-tree",
  },
})
```

Turn the stiffness down and the damping up if you want it drunk. Do the opposite if you want it snappy.

## CLI preview

Do not have Neovim open? The same repo ships a terminal toy that just… surfs.

```bash
go run ./cmd/floating-cursor
go run ./cmd/floating-cursor -ascii
go run ./cmd/floating-cursor -emoji
go run ./cmd/floating-cursor -once -speed 1.4
```

```
floating-cursor — maybe your cursor wants to go surfing?

  -ascii      ASCII sprites
  -emoji      wide glyph rider
  -once       exit after one lap
  -speed      multiplier
  -duration   stop after a duration
  -version
```

Ctrl+C to paddle in.

## How it works

1. A timer reads the real cursor’s screen cell.
2. A tiny physics step either springs toward that cell, or — if you jumped far — eases along a sine-wave path.
3. The drawn cursor and its wake are 1×1 floating windows, so it works in terminals with no graphics.
4. Optional `guicursor` blend hides the original block so only the floating one remains (best in Kitty, Ghostty, WezTerm, iTerm2).

## Tips

- If you still see two cursors, your TTY ignores `guicursor` blend. Set `hide_real_cursor = false` and keep the wake as a companion orb.
- Disable it in fuzzy finders via `disabled_filetypes`.
- `:FloatingCursorToggle` is the panic button.

## Support

Vim plugins are supposed to be free. If this made your `$EDITOR` a little more ridiculous, a coffee is plenty.

**[Buy me a coffee](https://www.buymeacoffee.com/Davicode)**

## License

MIT. See [LICENSE](LICENSE).
