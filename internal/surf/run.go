package surf

import (
	"fmt"
	"io"
	"os"
	"os/signal"
	"syscall"
	"time"
	"unsafe"
)

const (
	altScreenOn  = "\x1b[?1049h"
	altScreenOff = "\x1b[?1049l"
	hideCursor   = "\x1b[?25l"
	showCursor   = "\x1b[?25h"
	clearHome    = "\x1b[2J\x1b[H"
)

// Options control a live surfing session.
type Options struct {
	ASCII    bool
	Emoji    bool
	Once     bool
	Speed    float64
	Duration time.Duration
	FPS      int
	Stdout   io.Writer
	IsTTY    func() bool
	Size     func() (width, height int)
}

// Run starts the animation and restores the terminal on exit.
func Run(opts Options) error {
	out := opts.Stdout
	if out == nil {
		out = os.Stdout
	}
	if opts.Speed <= 0 {
		opts.Speed = 1
	}
	if opts.FPS <= 0 {
		opts.FPS = 20
	}
	isTTY := opts.IsTTY
	if isTTY == nil {
		isTTY = func() bool { return IsTerminal(os.Stdout.Fd()) }
	}
	size := opts.Size
	if size == nil {
		size = WinSize
	}

	if !isTTY() {
		w, h := 72, 18
		fmt.Fprintln(out, Render(Config{
			Width:  w,
			Height: h,
			ASCII:  true,
			Speed:  opts.Speed,
		}, 1.2))
		fmt.Fprintln(out)
		fmt.Fprintln(out, "A terminal is required for the live surf. Try again from an interactive shell.")
		return nil
	}

	if _, err := io.WriteString(out, altScreenOn+hideCursor+clearHome); err != nil {
		return err
	}
	defer func() {
		_, _ = io.WriteString(out, showCursor+altScreenOff)
	}()

	interrupt := make(chan os.Signal, 1)
	signal.Notify(interrupt, os.Interrupt, syscall.SIGTERM)
	defer signal.Stop(interrupt)

	resize := make(chan os.Signal, 1)
	signal.Notify(resize, syscall.SIGWINCH)
	defer signal.Stop(resize)

	w, h := size()
	ticker := time.NewTicker(time.Second / time.Duration(opts.FPS))
	defer ticker.Stop()

	start := time.Now()
	var deadline time.Time
	if opts.Duration > 0 {
		deadline = start.Add(opts.Duration)
	}

	cfg := Config{Width: w, Height: h, ASCII: opts.ASCII, Emoji: opts.Emoji, Speed: opts.Speed}
	if err := paint(out, cfg, 0); err != nil {
		return err
	}

	for {
		select {
		case <-interrupt:
			return nil
		case <-resize:
			w, h = size()
		case now := <-ticker.C:
			elapsed := now.Sub(start).Seconds()
			if !deadline.IsZero() && now.After(deadline) {
				return nil
			}
			cfg = Config{Width: w, Height: h, ASCII: opts.ASCII, Emoji: opts.Emoji, Speed: opts.Speed}
			if err := paint(out, cfg, elapsed); err != nil {
				return err
			}
			if opts.Once {
				_, laps := SurferState(elapsed, opts.Speed, w, SpriteWidth(opts.ASCII, opts.Emoji))
				if laps >= 1 {
					return nil
				}
			}
		}
	}
}

func paint(out io.Writer, cfg Config, elapsed float64) error {
	if _, err := io.WriteString(out, "\x1b[H"); err != nil {
		return err
	}
	_, err := io.WriteString(out, Render(cfg, elapsed))
	return err
}

// IsTerminal reports whether fd points at a terminal.
func IsTerminal(fd uintptr) bool {
	return ioctlOK(fd)
}

func ioctlOK(fd uintptr) bool {
	var ws winsize
	_, _, errno := syscall.Syscall(
		syscall.SYS_IOCTL,
		fd,
		uintptr(syscall.TIOCGWINSZ),
		uintptr(unsafe.Pointer(&ws)),
	)
	return errno == 0 && ws.Col > 0 && ws.Row > 0
}

// WinSize reports the current terminal size, falling back to 80x24.
func WinSize() (width, height int) {
	return winSizeFD(os.Stdout.Fd())
}

type winsize struct {
	Row    uint16
	Col    uint16
	Xpixel uint16
	Ypixel uint16
}

func winSizeFD(fd uintptr) (width, height int) {
	var ws winsize
	_, _, errno := syscall.Syscall(
		syscall.SYS_IOCTL,
		fd,
		uintptr(syscall.TIOCGWINSZ),
		uintptr(unsafe.Pointer(&ws)),
	)
	if errno != 0 || ws.Col == 0 || ws.Row == 0 {
		return 80, 24
	}
	return int(ws.Col), int(ws.Row)
}
