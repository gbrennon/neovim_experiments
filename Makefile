# Neovim Configuration Makefile

# Variables
LUA_PATH := ./lua/?.lua;./lua/?/init.lua;./spec/?.lua;./spec/?/init.lua;$(LUA_PATH)
LUAROCKS_BIN := $(HOME)/.luarocks/bin
BUSTED := $(LUAROCKS_BIN)/busted
LUACHECK := $(LUAROCKS_BIN)/luacheck
LUACOV := $(LUAROCKS_BIN)/luacov

# Default target
.PHONY: all
all: test lint

# Run tests
.PHONY: test
test:
	@echo "Running tests..."
	@LUA_PATH="$(LUA_PATH)" $(BUSTED) spec/

# Run tests with coverage
.PHONY: test-coverage
test-coverage:
	@echo "Running tests with coverage..."
	@LUA_PATH="$(LUA_PATH)" $(BUSTED) spec/
	@echo ""
	@echo "Generating coverage report..."
	@lua lua/spec/coverage.lua

# Run linter
.PHONY: lint
lint:
	@echo "Running luacheck..."
	@$(LUACHECK) lua/ spec/ --exclude-files "spec/helpers/vim_mock.lua"

# Clean coverage files
.PHONY: clean
clean:
	@echo "Cleaning coverage files..."
	@rm -f luacov.stats.out luacov.report.out

# Install test dependencies
.PHONY: install-deps
install-deps:
	@echo "Installing test dependencies..."
	@luarocks install busted --local
	@luarocks install luacov --local
	@luarocks install luacheck --local

# Help
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  test           - Run tests"
	@echo "  test-coverage  - Run tests with coverage"
	@echo "  lint           - Run luacheck linter"
	@echo "  clean          - Remove coverage files"
	@echo "  install-deps   - Install test dependencies"
	@echo "  help           - Show this help"