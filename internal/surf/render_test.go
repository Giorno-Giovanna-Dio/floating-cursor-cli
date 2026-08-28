package surf

import (
	"regexp"
	"strings"
	"testing"
	"unicode/utf8"
)

var ansi = regexp.MustCompile(`\x1b\[[0-9;]*m`)

func TestRenderASCIIFitsTerminal(t *testing.T) {
	const w, h = 48, 12
	frame := Render(Config{Width: w, Height: h, ASCII: true, Speed: 1}, 1.25)
	plain := ansi.ReplaceAllString(frame, "")
	lines := strings.Split(plain, "\n")
	if len(lines) != h {
		t.Fatalf("got %d lines, want %d", len(lines), h)
	}
	for i, line := range lines {
		if utf8.RuneCountInString(line) != w {
			t.Fatalf("line %d width %d, want %d (%q)", i, utf8.RuneCountInString(line), w, line)
		}
	}
	if !strings.Contains(plain, "floating-cursor") {
		t.Fatal("status line missing")
	}
	if !strings.Contains(plain, ">") {
		t.Fatal("ascii rider missing")
	}
}

func TestSpriteChoices(t *testing.T) {
	if Sprite(true, false) != ">" {
		t.Fatalf("ascii sprite: %q", Sprite(true, false))
	}
	if Sprite(false, true) != "🏄" {
		t.Fatalf("emoji sprite: %q", Sprite(false, true))
	}
	if SpriteWidth(false, true) != 2 {
		t.Fatal("emoji should be two cells")
	}
}

func TestRenderWavesVaryInHeight(t *testing.T) {
	const w, h = 64, 18
	frame := Render(Config{Width: w, Height: h, ASCII: true, Speed: 1}, 0.9)
	plain := ansi.ReplaceAllString(frame, "")
	lines := strings.Split(plain, "\n")
	if len(lines) != h {
		t.Fatalf("got %d lines, want %d", len(lines), h)
	}

	minSurf, maxSurf := h, 0
	found := false
	for x := 0; x < w; x++ {
		for y := 1; y < h; y++ {
			rs := []rune(lines[y])
			if x >= len(rs) {
				break
			}
			if rs[x] == ' ' || rs[x] == '>' {
				continue
			}
			if y < minSurf {
				minSurf = y
			}
			if y > maxSurf {
				maxSurf = y
			}
			found = true
			break
		}
	}
	if !found {
		t.Fatal("no water surface found")
	}
	if maxSurf-minSurf < 4 {
		t.Fatalf("expected crests and troughs, surface rows %d..%d", minSurf, maxSurf)
	}
}
