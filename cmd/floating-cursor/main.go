package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/Giorno-Giovanna-Dio/floating-cursor-cli/internal/surf"
)

const version = "0.1.0"

func main() {
	showVersion := flag.Bool("version", false, "print version and exit")
	ascii := flag.Bool("ascii", false, "use ASCII sprites instead of unicode")
	emoji := flag.Bool("emoji", false, "use an emoji surfer (wide glyph)")
	once := flag.Bool("once", false, "exit after one ride across the terminal")
	speed := flag.Float64("speed", 1, "surf speed multiplier")
	duration := flag.Duration("duration", 0, "stop after this long (0 means until interrupt)")

	flag.Usage = func() {
		fmt.Fprintf(flag.CommandLine.Output(), "floating-cursor — maybe your cursor wants to go surfing?\n\n")
		fmt.Fprintf(flag.CommandLine.Output(), "Usage:\n  floating-cursor [flags]\n\n")
		fmt.Fprintf(flag.CommandLine.Output(), "Flags:\n")
		flag.PrintDefaults()
	}
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		return
	}
	if *speed <= 0 {
		fmt.Fprintln(os.Stderr, "speed must be greater than 0")
		os.Exit(2)
	}

	err := surf.Run(surf.Options{
		ASCII:    *ascii,
		Emoji:    *emoji,
		Once:     *once,
		Speed:    *speed,
		Duration: *duration,
		FPS:      20,
	})
	if err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
