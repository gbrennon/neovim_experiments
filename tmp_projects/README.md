# Temporary projects to verify LSP configurations.

## Languages included:
- python
- typescript
- rust
- scala
- go

## How to use:
1. Ensure LSP servers are installed: pyright, typescript-language-server, rust-analyzer, metals, gopls.
2. Open the desired project folder in Neovim.
3. Run :LspInfo to check attached servers and capabilities.
4. Use <leader>rn to rename a symbol and verify references are updated across files.

Notes:
- These are minimal projects intended for quick LSP checks; install the language-specific LSP servers separately.
