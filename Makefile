.PHONY: test test-go test-nvim run preview install uninstall

NVIM_PACK := $(HOME)/.local/share/nvim/site/pack/floating-cursor/start/floating-cursor-cli

test: test-go test-nvim

test-go:
	go test ./...

test-nvim:
	nvim --headless -u tests/minimal_init.lua -i NONE -c qa

run:
	go run ./cmd/floating-cursor

preview:
	go run ./cmd/floating-cursor -ascii

install:
	mkdir -p "$(dir $(NVIM_PACK))"
	ln -sfn "$(CURDIR)" "$(NVIM_PACK)"
	@echo "Installed to $(NVIM_PACK)"
	@echo "Restart Neovim. Jump around to surf; :FloatingCursorOcean draws the swell."

uninstall:
	rm -f "$(NVIM_PACK)"
	@echo "Removed $(NVIM_PACK)"
