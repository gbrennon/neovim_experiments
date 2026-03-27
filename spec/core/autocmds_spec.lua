-- Tests for core/autocmds.lua
local spec_helper = require("spec_helper")

describe("core.autocmds", function()
  before_each(function()
    spec_helper.reset_vim_mock()
  end)

  describe("module structure", function()
    it("should load without errors", function()
      assert.has_no.errors(function()
        require("core.autocmds")
      end)
    end)

    it("should return a module table", function()
      local autocmds = require("core.autocmds")
      assert.is_table(autocmds)
    end)

    it("should have setup function", function()
      local autocmds = require("core.autocmds")
      assert.is_function(autocmds.setup)
    end)
  end)

  describe("setup function", function()
    it("can be called multiple times without error", function()
      local autocmds = require("core.autocmds")
      assert.has_no.errors(function()
        autocmds.setup()
        autocmds.setup()
      end)
    end)
  end)

  describe("autocmd registration", function()
    local function find_autocmd(state, event)
      for _, ac in ipairs(state.autocmds) do
        local events = ac.events
        if type(events) == "string" and events == event then
          return ac
        elseif type(events) == "table" then
          for _, e in ipairs(events) do
            if e == event then
              return ac
            end
          end
        end
      end
      return nil
    end

    local function find_autocmd_by_desc(state, desc)
      for _, ac in ipairs(state.autocmds) do
        if ac.opts and ac.opts.desc == desc then
          return ac
        end
      end
      return nil
    end

    it("should create autocmds", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      assert.is_true(#state.autocmds > 0)
    end)

    it("should register TextYankPost autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "TextYankPost")
      assert.is_not_nil(ac)
      assert.equals("Highlight on yank", ac.opts.desc)
    end)

    it("should have callback for TextYankPost", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "TextYankPost")
      assert.is_not_nil(ac)
      assert.is_function(ac.opts.callback)
    end)

    it("TextYankPost callback should call vim.highlight.on_yank", function()
      local on_yank_called = false
      vim.highlight.on_yank = function(opts)
        on_yank_called = true
        assert.equals("IncSearch", opts.higroup)
        assert.equals(200, opts.timeout)
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "TextYankPost")
      ac.opts.callback()
      assert.is_true(on_yank_called)
    end)

    it("should register BufWritePre autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufWritePre")
      assert.is_not_nil(ac)
      assert.equals("Remove trailing whitespace", ac.opts.desc)
    end)

    it("should have pattern for BufWritePre", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufWritePre")
      assert.is_not_nil(ac)
      assert.equals("*", ac.opts.pattern)
    end)

    it("should register BufReadPost autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufReadPost")
      assert.is_not_nil(ac)
      assert.equals("Restore cursor position", ac.opts.desc)
    end)

    it("should have callback for BufReadPost", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufReadPost")
      assert.is_not_nil(ac)
      assert.is_function(ac.opts.callback)
    end)

    it("BufReadPost callback should restore cursor position", function()
      vim.api.nvim_buf_get_mark = function() return { 5, 0 } end
      vim.api.nvim_buf_line_count = function() return 100 end
      local cursor_set = false
      vim.api.nvim_win_set_cursor = function(_, pos)
        cursor_set = true
        assert.same({ 5, 0 }, pos)
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufReadPost")
      ac.opts.callback()
      assert.is_true(cursor_set)
    end)

    it("BufReadPost callback should handle mark at line 0", function()
      vim.api.nvim_buf_get_mark = function() return { 0, 0 } end
      vim.api.nvim_buf_line_count = function() return 100 end
      local cursor_set = false
      vim.api.nvim_win_set_cursor = function()
        cursor_set = true
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "BufReadPost")
      ac.opts.callback()
      assert.is_false(cursor_set)
    end)

    it("should register FileType autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FileType")
      assert.is_not_nil(ac)
      assert.equals("Close certain filetypes with q", ac.opts.desc)
    end)

    it("should have pattern for FileType", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FileType")
      assert.is_not_nil(ac)
      assert.is_table(ac.opts.pattern)
    end)

    it("should include help in FileType pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FileType")
      assert.is_not_nil(ac)
      local has_help = false
      for _, ft in ipairs(ac.opts.pattern) do
        if ft == "help" then has_help = true end
      end
      assert.is_true(has_help)
    end)

    it("should include qf in FileType pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FileType")
      assert.is_not_nil(ac)
      local has_qf = false
      for _, ft in ipairs(ac.opts.pattern) do
        if ft == "qf" then has_qf = true end
      end
      assert.is_true(has_qf)
    end)

    it("should register VimResized autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "VimResized")
      assert.is_not_nil(ac)
      assert.equals("Auto resize splits", ac.opts.desc)
    end)

    it("should have callback for VimResized", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "VimResized")
      assert.is_not_nil(ac)
      assert.is_function(ac.opts.callback)
    end)

    it("VimResized callback should call tabdo wincmd =", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "VimResized")
      assert.has_no.errors(function()
        ac.opts.callback()
      end)
    end)

    it("FileType callback should set buflisted and keymap", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FileType")
      assert.has_no.errors(function()
        ac.opts.callback({ buf = 1 })
      end)
    end)

    it("should register FocusGained autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FocusGained")
      assert.is_not_nil(ac)
      assert.equals("Check if file changed", ac.opts.desc)
    end)

    it("should have checktime command for FocusGained", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd(state, "FocusGained")
      assert.is_not_nil(ac)
      assert.equals("checktime", ac.opts.command)
    end)

    it("should not restart LSP for ordinary project file saves", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Restart LSP when project files change")
      assert.is_nil(ac)
    end)

    it("should not restart LSP when files are renamed or moved", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Restart LSP when files are renamed or moved")
      assert.is_nil(ac)
    end)
  end)

  describe("auto-import autocmd", function()
    local function find_autocmd_by_desc(state, desc)
      for _, ac in ipairs(state.autocmds) do
        if ac.opts and ac.opts.desc == desc then
          return ac
        end
      end
      return nil
    end

    it("should register auto-import BufWritePre autocmd", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.is_not_nil(ac)
    end)

    it("should trigger on BufWritePre event", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.is_not_nil(ac)
      assert.equals("BufWritePre", ac.events)
    end)

    it("should have pattern for supported file types", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.is_not_nil(ac)
      assert.is_table(ac.opts.pattern)
    end)

    it("should include Go files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_go = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.go" then has_go = true end
      end
      assert.is_true(has_go)
    end)

    it("should include TypeScript files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_ts = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.ts" then has_ts = true end
      end
      assert.is_true(has_ts)
    end)

    it("should include TSX files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_tsx = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.tsx" then has_tsx = true end
      end
      assert.is_true(has_tsx)
    end)

    it("should include JavaScript files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_js = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.js" then has_js = true end
      end
      assert.is_true(has_js)
    end)

    it("should include JSX files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_jsx = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.jsx" then has_jsx = true end
      end
      assert.is_true(has_jsx)
    end)

    it("should include Python files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_py = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.py" then has_py = true end
      end
      assert.is_true(has_py)
    end)

    it("should include Rust files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_rs = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.rs" then has_rs = true end
      end
      assert.is_true(has_rs)
    end)

    it("should include Scala files in pattern", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      local has_scala = false
      for _, p in ipairs(ac.opts.pattern) do
        if p == "*.scala" then has_scala = true end
      end
      assert.is_true(has_scala)
    end)

    it("should have callback function", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.is_not_nil(ac)
      assert.is_function(ac.opts.callback)
    end)

    it("callback should execute without error", function()
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.has_no.errors(function()
        ac.opts.callback()
      end)
    end)

    it("callback should handle empty results", function()
      vim.lsp.buf_request_sync = function() return {} end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.has_no.errors(function()
        ac.opts.callback()
      end)
    end)

    it("callback should handle nil results", function()
      vim.lsp.buf_request_sync = function() return nil end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      assert.has_no.errors(function()
        ac.opts.callback()
      end)
    end)

    it("callback should apply workspace edits from actions", function()
      local edit_applied = false
      vim.lsp.buf_request_sync = function()
        return {
          { result = { { edit = { changes = {} } } } },
        }
      end
      vim.lsp.util.apply_workspace_edit = function()
        edit_applied = true
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      ac.opts.callback()
      assert.is_true(edit_applied)
    end)

    it("callback should execute commands from actions", function()
      local command_executed = false
      vim.lsp.buf_request_sync = function()
        return {
          { result = { { command = { command = "organize_imports" } } } },
        }
      end
      vim.lsp.buf.execute_command = function()
        command_executed = true
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      ac.opts.callback()
      assert.is_true(command_executed)
    end)

    it("callback should request add-missing, organize, and fix-all actions", function()
      local requested_kinds = {}
      local request_bufnr
      local request_uri
      vim.lsp.buf_request_sync = function(bufnr, _, params)
        request_bufnr = bufnr
        request_uri = params.textDocument.uri
        table.insert(requested_kinds, params.context.only[1])
        return {}
      end
      require("core.autocmds")
      local state = spec_helper.vim_mock.get_state()
      local ac = find_autocmd_by_desc(state, "Auto-import and organize imports on save")
      ac.opts.callback({ buf = 3 })

      assert.equals(3, request_bufnr)
      assert.equals("file:///tmp/3", request_uri)
      assert.is_true(vim.tbl_contains(requested_kinds, "source.addMissingImports"))
      assert.is_true(vim.tbl_contains(requested_kinds, "source.addMissingImports.ts"))
      assert.is_true(vim.tbl_contains(requested_kinds, "source.organizeImports"))
      assert.is_true(vim.tbl_contains(requested_kinds, "source.organizeImports.ts"))
      assert.is_true(vim.tbl_contains(requested_kinds, "source.fixAll"))
      assert.is_true(vim.tbl_contains(requested_kinds, "source.fixAll.ts"))
    end)
  end)
end)
