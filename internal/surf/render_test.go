package surf

import (
	"strings"
	"testing"
	"unicode/utf8"
)

func TestRenderASCIIContainsSurferAndWave(t *testing.T) {
	frame := Render(Config{Width: 40, Height: 12, ASCII: true, Speed: 1}, 0.4)
	if !strings.Contains(frame, ">") {
		t.Fatal("expected ASCII surfer '>' in frame")
	}
	if !strings.Contains(frame, "~") && !strings.Contains(frame, "-") {
		t.Fatal("expected wave glyphs in frame")
	}
	if !strings.Contains(frame, "floating-cursor") {
		t.Fatal("expected status line")
	}
}

func TestRenderDefaultUsesCursorSprite(t *testing.T) {
	frame := Render(Config{Width: 32, Height: 10, Speed: 1}, 0)
	if !strings.Contains(frame, "▲") {
		t.Fatal("expected default cursor sprite")
	}
	if strings.Contains(frame, ">") {
		t.Fatal("did not expect ASCII surfer in default mode")
	}
}

func TestRenderPadsStatusLineToWidth(t *testing.T) {
	width := 48
	frame := Render(Config{Width: width, Height: 8, ASCII: true}, 0)
	first := strings.Split(frame, "\n")[0]
	plain := stripANSI(first)
	if utf8.RuneCountInString(plain) != width {
		t.Fatalf("status width = %d, want %d (%q)", utf8.RuneCountInString(plain), width, plain)
	}
}

func TestSpriteWidth(t *testing.T) {
	if SpriteWidth(true, false) != 1 {
		t.Fatal("ASCII sprite should be 1 cell")
	}
	if SpriteWidth(false, false) != 1 {
		t.Fatal("default sprite should be 1 cell")
	}
	if SpriteWidth(false, true) != 2 {
		t.Fatal("emoji sprite should be 2 cells")
	}
}

func stripANSI(s string) string {
	var b strings.Builder
	for i := 0; i < len(s); {
		if s[i] == '\x1b' {
			if j := strings.IndexByte(s[i:], 'm'); j >= 0 {
				i += j + 1
				continue
			}
		}
		b.WriteByte(s[i])
		i++
	}
	return b.String()
}
