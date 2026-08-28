package surf

import (
	"bytes"
	"strings"
	"testing"
	"time"
)

func TestRunPrintsStaticFrameWhenNotATTY(t *testing.T) {
	var buf bytes.Buffer
	err := Run(Options{
		ASCII:  true,
		Speed:  1,
		Stdout: &buf,
		IsTTY:  func() bool { return false },
	})
	if err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, ">") {
		t.Fatal("expected static ASCII surf frame")
	}
	if !strings.Contains(out, "A terminal is required") {
		t.Fatal("expected non-TTY hint")
	}
	if strings.Contains(out, altScreenOn) {
		t.Fatal("non-TTY path should not enter the alt screen")
	}
}

func TestRunOnceExitsAfterALap(t *testing.T) {
	var buf bytes.Buffer
	err := Run(Options{
		ASCII:  true,
		Once:   true,
		Speed:  40,
		FPS:    50,
		Stdout: &buf,
		IsTTY:  func() bool { return true },
		Size:   func() (int, int) { return 24, 8 },
	})
	if err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, altScreenOn) || !strings.Contains(out, altScreenOff) {
		t.Fatal("expected alt screen to be entered and restored")
	}
	if !strings.Contains(out, showCursor) {
		t.Fatal("expected cursor to be restored")
	}
}

func TestRunHonorsDuration(t *testing.T) {
	start := time.Now()
	err := Run(Options{
		ASCII:    true,
		Duration: 40 * time.Millisecond,
		FPS:      50,
		Stdout:   new(bytes.Buffer),
		IsTTY:    func() bool { return true },
		Size:     func() (int, int) { return 20, 8 },
	})
	if err != nil {
		t.Fatal(err)
	}
	if time.Since(start) > time.Second {
		t.Fatal("duration cap took too long")
	}
}
