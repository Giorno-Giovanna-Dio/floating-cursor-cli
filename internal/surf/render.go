package surf

import (
	"strings"
	"unicode/utf8"
)

const (
	ansiReset  = "\x1b[0m"
	ansiDim    = "\x1b[2m"
	ansiCyan   = "\x1b[36m"
	ansiBright = "\x1b[96m"
	ansiYellow = "\x1b[93m"
)

// Config describes one frame of the surf scene.
type Config struct {
	Width  int
	Height int
	ASCII  bool
	Emoji  bool
	Speed  float64
}

// Sprite is the rider drawn on top of the swell.
func Sprite(ascii, emoji bool) string {
	if ascii {
		return ">"
	}
	if emoji {
		return "🏄"
	}
	return "▲"
}

// SpriteWidth is the terminal cell width of the rider.
func SpriteWidth(ascii, emoji bool) int {
	if !ascii && emoji {
		return 2
	}
	return 1
}

// Render draws one complete frame, including a status row.
func Render(cfg Config, elapsed float64) string {
	w, h := cfg.Width, cfg.Height
	if w < 8 {
		w = 8
	}
	if h < 4 {
		h = 4
	}

	speed := cfg.Speed
	if speed <= 0 {
		speed = 1
	}

	sprite := Sprite(cfg.ASCII, cfg.Emoji)
	sw := SpriteWidth(cfg.ASCII, cfg.Emoji)
	sx, _ := SurferState(elapsed, speed, w, sw)
	phase := elapsed * 1.6 * speed
	amp := amplitudeFor(h)

	rows := make([][]rune, h)
	for y := 0; y < h; y++ {
		rows[y] = []rune(strings.Repeat(" ", w))
	}

	writeString(rows[0], 0, statusLine(w, cfg.ASCII))

	for x := 0; x < w; x++ {
		row := WaterRow(h, WaveY(x, phase, amp))
		rows[row][x] = waveGlyph(x, row, cfg.ASCII)
		if row+1 < h && x%3 != 1 {
			rows[row+1][x] = foamGlyph(cfg.ASCII)
		}
	}

	sy := WaterRow(h, WaveY(sx, phase, amp)) - 1
	if sy < 1 {
		sy = 1
	}
	writeString(rows[sy], sx, sprite)
	skip := -1
	if sw == 2 && sx+1 < w {
		skip = sx + 1
	}

	var b strings.Builder
	b.Grow(h * (w + 24))
	for y, row := range rows {
		line := encodeRow(row, y == sy, skip)
		switch {
		case y == 0:
			b.WriteString(ansiDim)
			b.WriteString(line)
			b.WriteString(ansiReset)
		case strings.Contains(line, sprite):
			b.WriteString(colorizeRow(line, sprite, cfg.ASCII))
		default:
			b.WriteString(ansiCyan)
			b.WriteString(line)
			b.WriteString(ansiReset)
		}
		if y < h-1 {
			b.WriteByte('\n')
		}
	}
	return b.String()
}

func amplitudeFor(height int) float64 {
	amp := float64(height) / 5
	if amp < 2 {
		return 2
	}
	if amp > 8 {
		return 8
	}
	return amp
}

func statusLine(width int, ascii bool) string {
	text := " floating-cursor  ·  ctrl+c to paddle in "
	if ascii {
		text = " floating-cursor  |  ctrl+c to paddle in "
	}
	n := utf8.RuneCountInString(text)
	if n > width {
		text = " floating-cursor "
		n = utf8.RuneCountInString(text)
	}
	if n < width {
		text += strings.Repeat(" ", width-n)
	}
	return text
}

func waveGlyph(x, row int, ascii bool) rune {
	if ascii {
		if (x+row)%4 == 0 {
			return '-'
		}
		return '~'
	}
	switch (x + row) % 5 {
	case 0:
		return '≈'
	case 2:
		return '∽'
	default:
		return '~'
	}
}

func foamGlyph(ascii bool) rune {
	if ascii {
		return '.'
	}
	return '·'
}

func encodeRow(row []rune, isSurferRow bool, skip int) string {
	if !isSurferRow || skip < 0 || skip >= len(row) {
		return string(row)
	}
	var b strings.Builder
	b.Grow(len(row))
	for i, r := range row {
		if i == skip {
			continue
		}
		b.WriteRune(r)
	}
	return b.String()
}

func writeString(row []rune, start int, s string) {
	i := start
	for _, r := range s {
		if i < 0 || i >= len(row) {
			break
		}
		row[i] = r
		i++
	}
}

func colorizeRow(row, sprite string, ascii bool) string {
	idx := strings.Index(row, sprite)
	if idx < 0 {
		return ansiCyan + row + ansiReset
	}
	end := idx + len(sprite)
	waveColor := ansiCyan
	if !ascii {
		waveColor = ansiBright
	}
	return waveColor + row[:idx] + ansiYellow + row[idx:end] + waveColor + row[end:] + ansiReset
}
