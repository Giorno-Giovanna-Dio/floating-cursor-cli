package surf

import "math"

const (
	defaultAmplitude = 4.0
	defaultFrequency = 0.22
	cellsPerSecond   = 12.0
	harmonicMix      = 0.55
	harmonicFreq     = 2.15
	harmonicPhase    = 1.37
)

// WaveY returns the vertical offset of the swell at column x.
// Positive values sit lower on the terminal. A second harmonic
// makes neighboring peaks different heights so the set has crests
// and troughs, not a single bump.
func WaveY(x int, phase, amplitude float64) float64 {
	if amplitude <= 0 {
		amplitude = defaultAmplitude
	}
	xf := float64(x)
	primary := math.Sin(xf*defaultFrequency + phase)
	harmonic := math.Sin(xf*defaultFrequency*harmonicFreq + phase*harmonicPhase)
	return (primary + harmonicMix*harmonic) * amplitude
}

// WaterRow maps a wave offset onto a terminal row, keeping the swell
// inside the drawable band beneath the status line.
func WaterRow(height int, offset float64) int {
	if height < 3 {
		return max(height-1, 0)
	}
	row := height/2 + int(math.Round(offset))
	if row < 1 {
		return 1
	}
	maxRow := height - 2
	if row > maxRow {
		return maxRow
	}
	return row
}

// SurferState advances the rider across the terminal.
func SurferState(elapsed, speed float64, width, spriteWidth int) (x, laps int) {
	if width <= 0 {
		return 0, 0
	}
	if speed <= 0 {
		speed = 1
	}
	if spriteWidth < 1 {
		spriteWidth = 1
	}

	span := width - spriteWidth
	if span < 1 {
		span = 1
	}

	cells := elapsed * cellsPerSecond * speed
	if cells < 0 {
		cells = 0
	}
	total := int(cells)
	laps = total / span
	x = total % span
	return x, laps
}
