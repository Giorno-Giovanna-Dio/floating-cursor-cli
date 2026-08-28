package surf

import "testing"

func TestSurferStateStartsAtOrigin(t *testing.T) {
	x, laps := SurferState(0, 1, 80, 1)
	if x != 0 || laps != 0 {
		t.Fatalf("got x=%d laps=%d, want 0 0", x, laps)
	}
}

func TestSurferStateWraps(t *testing.T) {
	// 1s at 12 cells/s, width 10, sprite 1 => span 9 => 12/9 = 1 lap remainder 3
	x, laps := SurferState(1, 1, 10, 1)
	if x != 3 || laps != 1 {
		t.Fatalf("got x=%d laps=%d, want 3 1", x, laps)
	}
}

func TestWaterRowStaysInBand(t *testing.T) {
	height := 12
	for _, offset := range []float64{-100, -4, 0, 4, 100} {
		row := WaterRow(height, offset)
		if row < 1 || row > height-2 {
			t.Fatalf("offset %v mapped to row %d, out of 1..%d", offset, row, height-2)
		}
	}
}

func TestWaveYHasCrestsAndTroughs(t *testing.T) {
	minY, maxY := WaveY(0, 0, 4), WaveY(0, 0, 4)
	for x := 0; x < 80; x++ {
		y := WaveY(x, 0.4, 4)
		if y < minY {
			minY = y
		}
		if y > maxY {
			maxY = y
		}
	}
	if minY >= 0 {
		t.Fatalf("expected a trough below 0, min=%v", minY)
	}
	if maxY <= 0 {
		t.Fatalf("expected a crest above 0, max=%v", maxY)
	}
	if maxY-minY < 5 {
		t.Fatalf("wave range too small: min=%v max=%v", minY, maxY)
	}
}

func TestWaveYScalesWithAmplitude(t *testing.T) {
	small := WaveY(3, 0, 2)
	large := WaveY(3, 0, 8)
	if large == 0 && small == 0 {
		t.Fatal("expected a non-zero wave sample")
	}
	if abs(large) <= abs(small) {
		t.Fatalf("larger amplitude should move more: small=%v large=%v", small, large)
	}
}

func abs(v float64) float64 {
	if v < 0 {
		return -v
	}
	return v
}
