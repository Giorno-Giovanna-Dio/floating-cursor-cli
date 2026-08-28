package surf

import (
	"bytes"
	"strings"
	"testing"
)

func TestRunPrintsStaticFrameWithoutTTY(t *testing.T) {
	var buf bytes.Buffer
	err := Run(Options{
		ASCII:  true,
		Stdout: &buf,
		IsTTY:  func() bool { return false },
	})
	if err != nil {
		t.Fatal(err)
	}
	out := buf.String()
	if !strings.Contains(out, "floating-cursor") {
		t.Fatalf("missing title in static frame:\n%s", out)
	}
	if !strings.Contains(out, "terminal is required") {
		t.Fatalf("missing tty hint:\n%s", out)
	}
}
