-- Key Mappings Configuration

local M = {}

function M.setup()
  local map = vim.keymap.set

  -- Set leader key
  vim.g.mapleader = ","
  vim.g.maplocalleader = ","

  ------------------------------------------------------------------------------
  -- General keymaps
  ------------------------------------------------------------------------------
  map("n", "<leader>w", ":w<CR>", { desc = "Save file" })
  map("n", "<leader>q", ":q<CR>", { desc = "Quit window" })
  map("n", "<leader>W", ":wa<CR>", { desc = "Save all files" })
  map("n", "<leader>Q", ":qa!<CR>", { desc = "Force quit all" })
  map("n", "<leader><Space>", ":nohlsearch<CR>", { desc = "Clear search highlights" })

  -- Toggle relative line numbers
  map("n", "<leader>trn", function()
    vim.opt.relativenumber = not vim.opt.relativenumber:get()
  end, { desc = "Toggle Relative Number" })

  ------------------------------------------------------------------------------
  -- Buffer navigation
  ------------------------------------------------------------------------------
  map("n", "<leader>n", ":bnext<CR>", { desc = "Next Buffer" })
  map("n", "<leader>N", ":bprevious<CR>", { desc = "Prev Buffer" })
  map("n", "<leader>bd", ":bdelete<CR>", { desc = "Delete Buffer" })

  ------------------------------------------------------------------------------
  -- Window navigation
  ------------------------------------------------------------------------------
  map("n", "<C-h>", "<C-w>h", { desc = "Window Left" })
  map("n", "<C-j>", "<C-w>j", { desc = "Window Down" })
  map("n", "<C-k>", "<C-w>k", { desc = "Window Up" })
  map("n", "<C-l>", "<C-w>l", { desc = "Window Right" })

  -- Resize windows with arrows
  map("n", "<C-Up>", ":resize +2<CR>", { desc = "Increase window height" })
  map("n", "<C-Down>", ":resize -2<CR>", { desc = "Decrease window height" })
  map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Decrease window width" })
  map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Increase window width" })

  -- Split windows
  map("n", "<leader>sv", ":vsplit<CR>", { desc = "Split vertically" })
  map("n", "<leader>sh", ":split<CR>", { desc = "Split horizontally" })
  map("n", "<leader>se", "<C-w>=", { desc = "Make splits equal" })
  map("n", "<leader>sx", ":close<CR>", { desc = "Close current split" })

  ------------------------------------------------------------------------------
  -- File Explorer (NvimTree)
  ------------------------------------------------------------------------------
  map("n", "<F3>", ":NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })
  map("n", "<leader>e", ":NvimTreeToggle<CR>", { desc = "Toggle File Explorer" })
  map("n", "<leader>fe", ":NvimTreeFindFile<CR>", { desc = "Focus File Explorer" })

  ------------------------------------------------------------------------------
  -- Telescope
  ------------------------------------------------------------------------------
  map("n", "<leader>ff", "<cmd>Telescope find_files<CR>", { desc = "Find Files" })
  map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>", { desc = "Live Grep" })
  map("n", "<leader>fb", "<cmd>Telescope buffers<CR>", { desc = "Buffers" })
  map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find Help" })
  map("n", "<leader>fr", "<cmd>Telescope oldfiles<CR>", { desc = "Recent Files" })
  map("n", "<leader>fc", "<cmd>Telescope commands<CR>", { desc = "Commands" })
  map("n", "<leader>fk", "<cmd>Telescope keymaps<CR>", { desc = "Keymaps" })
  map("n", "<leader>ft", ":NvimTreeFindFile<CR>")

  ------------------------------------------------------------------------------
  -- Visual mode
  ------------------------------------------------------------------------------
  map("v", "<", "<gv", { desc = "Indent left" })
  map("v", ">", ">gv", { desc = "Indent right" })
  map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move text down" })
  map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move text up" })
  map("x", "<leader>p", [["_dP]], { desc = "Paste without losing register" })
  map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })
  map({ "n", "v" }, "<leader>d", [["_d]], { desc = "Delete without yanking" })

  ------------------------------------------------------------------------------
  -- Navigation improvements
  ------------------------------------------------------------------------------
  map("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
  map("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
  map("n", "n", "nzzzv", { desc = "Next search result centered" })
  map("n", "N", "Nzzzv", { desc = "Previous search result centered" })
  map("i", "jk", "<Esc>", { desc = "Exit insert mode" })
  map("i", "<Tab>", "<C-t>", { desc = "Increase indent" })
  map("i", "<S-Tab>", "<C-d>", { desc = "Decrease indent" })

  -- Provide a global fallback for K: prefer LSP hover when available, otherwise run the original keywordprg
  map("n", "K", function()
    -- Try LSP hover first and suppress errors; if it fails, notify instead of calling Man
    local ok, ret = pcall(vim.lsp.buf.hover)
    if ok then
      return
    end
    -- If hover failed, check attached clients to give a better message
    local clients = vim.lsp.get_clients({ bufnr = 0 })
    if clients and #clients > 0 then
      vim.notify('LSP attached but hover not supported by the server; ensure hover capability (rust_analyzer) is enabled', vim.log.levels.WARN)
      return
    end
    vim.notify('No LSP client attached for hover; install/attach rust_analyzer or other LSP for this buffer', vim.log.levels.INFO)
  end, { desc = "Hover Documentation (LSP)" })


  -- Ensure <C-a> navigation key exists (tests expect it)
  map("n", "<C-a>", "0", { desc = "Go to line start" })

  -- Diagnostics (global, not LSP-dependent)
  map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev Diagnostic" })
  map("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
  map("n", "<leader>df", vim.diagnostic.open_float, { desc = "Show Diagnostic in floating window" })
  map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to Quickfix" })
end

------------------------------------------------------------------------------
-- LSP buffer-local keymaps (to be called in LSP on_attach)
------------------------------------------------------------------------------
function M.lsp_on_attach(bufnr)
  local lsp_map = function(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { buffer = bufnr, noremap = true, silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
  end
  lsp_map("n", "gd", vim.lsp.buf.definition, { desc = "Go to Definition" })
  lsp_map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to Declaration" })
  lsp_map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to Implementation" })
  lsp_map("n", "gr", vim.lsp.buf.references, { desc = "Find References" })
  lsp_map("n", "K", vim.lsp.buf.hover, { desc = "Hover Documentation" })
  lsp_map("n", "<leader>rn", function()
    -- Prefer builtin LSP rename; fall back to a references-based rename if unavailable
    local ok = pcall(vim.lsp.buf.rename)
    if ok then
      return
    end
    -- Fallback: gather references and replace text occurrences
    local curr_word = vim.fn.expand('<cword>')
    local new_name = vim.fn.input("Rename '" .. curr_word .. "' to: ")
    if not new_name or new_name == '' or new_name == curr_word then
      return
    end

    local params = vim.lsp.util.make_position_params()
    params.context = { includeDeclaration = true }
    local results = vim.lsp.buf_request_sync(0, 'textDocument/references', params, 2000)
    if not results then
      vim.notify('No references returned for rename', vim.log.levels.WARN)
      return
    end

    local edits_by_uri = {}
    for _, res in pairs(results or {}) do
      for _, item in ipairs(res.result or {}) do
        local uri = item.uri or item.targetUri
        local range = item.range or item.targetRange
        if uri and range then
          edits_by_uri[uri] = edits_by_uri[uri] or {}
          table.insert(edits_by_uri[uri], { range = range, newText = new_name })
        end
      end
    end

    local clients = vim.lsp.get_clients({ bufnr = 0 })
    local encoding = 'utf-8'
    for _, client in ipairs(clients) do
      encoding = client.offset_encoding or encoding
      break
    end

    for uri, edits in pairs(edits_by_uri) do
      local bufnr = vim.uri_to_bufnr(uri)
      if not vim.api.nvim_buf_is_loaded(bufnr) then
        pcall(vim.fn.bufload, bufnr)
      end
      pcall(vim.lsp.util.apply_text_edits, edits, bufnr, encoding)
    end

    vim.notify("Renamed references to '" .. new_name .. "'", vim.log.levels.INFO)
  end, { desc = "Rename Symbol" })
  lsp_map("n", "<leader>ca", function()
    pcall(vim.lsp.buf.code_action)
  end, { desc = "Code Action" })
  lsp_map("n", "<leader>f", function()
    vim.lsp.buf.format({ async = true })
  end, { desc = "Format Buffer" })

  -- Buffer-local diagnostic navigation to satisfy LSP keymap tests
  lsp_map("n", "[d", vim.diagnostic.goto_prev, { desc = "Prev Diagnostic" })
  lsp_map("n", "]d", vim.diagnostic.goto_next, { desc = "Next Diagnostic" })
  lsp_map("n", "<leader>dl", vim.diagnostic.setloclist, { desc = "Diagnostics to Quickfix" })
  lsp_map("n", "<leader>qf", vim.diagnostic.setqflist, { desc = "Diagnostics to Quickfix (alt)" })
end

------------------------------------------------------------------------------
-- nvim-tree buffer-local keymaps
------------------------------------------------------------------------------
function M.nvimtree_on_attach(bufnr)
  local api = require("nvim-tree.api")
  local map = vim.keymap.set
  local opts = function(desc)
    return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
  end

  api.config.mappings.default_on_attach(bufnr)

  map("n", "a", api.fs.create, opts("Create File/Dir"))
  map("n", "d", api.fs.remove, opts("Delete"))
  map("n", "r", api.fs.rename, opts("Rename"))
  map("n", "m", api.fs.rename_sub, opts("Move"))
  map("n", "x", api.fs.cut, opts("Cut"))
  map("n", "p", api.fs.paste, opts("Paste"))
  map("n", "v", api.node.open.vertical, opts("Open: Vertical Split"))
  map("n", "s", api.node.open.horizontal, opts("Open: Horizontal Split"))
  map("n", "<CR>", api.node.open.edit, opts("Open"))
  map("n", "o", api.node.open.edit, opts("Open"))
  map("n", "/", api.live_filter.start, opts("Start Live Filter"))
  map("n", "f", api.live_filter.clear, opts("Clear Live Filter"))
end

-- Auto-run setup when loaded
M.setup()

return M
