# floating-cursor-cli

Maybe your cursor wants to go surfing?

`floating-cursor` is a tiny terminal toy. It sends a cursor out onto a looping swell and lets it ride until you paddle back in.

```
 floating-cursor  ·  ctrl+c to paddle in

          ▲
~~~~≈~~~∽~~~~≈~~~∽~~~~≈~~~∽~~~~
     ·     ·     ·     ·
```

## Install

```bash
go install github.com/Giorno-Giovanna-Dio/floating-cursor-cli/cmd/floating-cursor@latest
```

From a clone of this repository:

```bash
go build -o floating-cursor ./cmd/floating-cursor
./floating-cursor
```

## Usage

```bash
floating-cursor
floating-cursor -ascii
floating-cursor -emoji
floating-cursor -speed 1.8
floating-cursor -once
floating-cursor -duration 8s
floating-cursor -version
```

| Flag | Description |
|------|-------------|
| `-ascii` | Draw with ASCII sprites (`>` and `~`) |
| `-emoji` | Use a wide emoji surfer |
| `-speed` | Speed multiplier (must be `> 0`, default `1`) |
| `-once` | Exit after one ride across the terminal |
| `-duration` | Stop after a duration such as `5s` |
| `-version` | Print the version and exit |

Resize the window while it is running; the swell reflows with the terminal. Press `Ctrl+C` to quit.

If stdout is not a TTY, the CLI prints a single static frame and a short hint instead of entering the alternate screen.

## Develop

```bash
go test ./...
go vet ./...
```

## License

MIT
