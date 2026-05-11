-- Vim mock for testing outside of Neovim

local M = {}

M._state = {
  options = {},
  global_options = {},
  keymaps = {},
  autocmds = {},
  signs = {},
  diagnostic_config = nil,
  lsp_configs = {},
  lsp_enabled = {},
  highlights = {},
}

local function create_opt_proxy()
  return setmetatable({}, {
    __index = function(_, k)
      return {
        get = function() return M._state.options[k] end,
        _value = M._state.options[k], -- For direct access in tests
        append = function(_, v)
          local current = M._state.options[k] or {}
          if type(current) == "table" then
            table.insert(current, v)
          end
        end,
      }
    end,
    __newindex = function(_, k, v)
      M._state.options[k] = v
    end,
  })
end

local vim_mock = {
  g = setmetatable({}, {
    __index = function(_, k) return M._state.global_options[k] end,
    __newindex = function(_, k, v) M._state.global_options[k] = v end,
  }),

  o = setmetatable({}, {
    __index = function(_, k) return M._state.options[k] end,
    __newindex = function(_, k, v) M._state.options[k] = v end,
  }),

  opt = create_opt_proxy(),

  bo = setmetatable({}, {
    __index = function() return {} end,
    __newindex = function() end,
  }),

  fn = {
    executable = function(cmd)
      local known = {
        ["lua-language-server"] = 1,
        ["pyright-langserver"] = 1,
        ["gopls"] = 1,
        ["rust-analyzer"] = 1,
        ["metals"] = 1,
        ["typescript-language-server"] = 1,
        ["vscode-json-language-server"] = 1,
        ["yaml-language-server"] = 1,
        ["vscode-html-language-server"] = 1,
        ["vscode-css-language-server"] = 1,
      }
      return known[cmd] or 0
    end,
    sign_define = function(name, opts)
      M._state.signs[name] = opts
    end,
    has = function(feature)
      return ({ nvim = 1, ["nvim-0.11"] = 1 })[feature] or 0
    end,
    stdpath = function(what)
      return "/tmp/nvim-" .. what
    end,
    expand = function(str) return str end,
    system = function() return "" end,
    bufload = function() end,
  },

  api = {
    nvim_create_autocmd = function(events, opts)
      table.insert(M._state.autocmds, { events = events, opts = opts })
      return #M._state.autocmds
    end,
    nvim_create_augroup = function(name, opts)
      return name
    end,
    nvim_get_runtime_file = function() return {} end,
    nvim_set_hl = function(ns, name, opts)
      local converted = {}
      if opts.fg then
        converted.fg = type(opts.fg) == "string" and tonumber(opts.fg:gsub("#", ""), 16) or opts.fg
      end
      if opts.bg then
        converted.bg = type(opts.bg) == "string" and tonumber(opts.bg:gsub("#", ""), 16) or opts.bg
      end
      if opts.bold then converted.bold = opts.bold end
      if opts.cterm then converted.cterm = opts.cterm end
      M._state.highlights[name] = converted
    end,
    nvim_get_hl = function(ns, opts)
      local name = opts.name
      return M._state.highlights[name] or {}
    end,
    nvim_buf_get_mark = function() return { 0, 0 } end,
    nvim_buf_line_count = function() return 100 end,
    nvim_win_set_cursor = function() end,
    nvim_buf_is_loaded = function() return true end,
  },

  keymap = {
    set = function(mode, lhs, rhs, opts)
      opts = opts or {}
      if type(mode) == "table" then
        for _, m in ipairs(mode) do
          table.insert(M._state.keymaps, { mode = m, lhs = lhs, rhs = rhs, opts = opts, buffer = opts.buffer })
        end
      else
        table.insert(M._state.keymaps, { mode = mode, lhs = lhs, rhs = rhs, opts = opts, buffer = opts.buffer })
      end
    end,
    _get_keymap = function(mode, lhs)
      -- Prefer buffer-local keymaps when present
      for _, keymap in ipairs(M._state.keymaps) do
        if keymap.mode == mode and keymap.lhs == lhs and keymap.buffer then
          return keymap
        end
      end
      for _, keymap in ipairs(M._state.keymaps) do
        if keymap.mode == mode and keymap.lhs == lhs then
          return keymap
        end
      end
      return nil
    end,
  },

  diagnostic = {
    severity = { ERROR = 1, WARN = 2, INFO = 3, HINT = 4 },
    config = function(opts) M._state.diagnostic_config = opts end,
    goto_prev = function() end,
    goto_next = function() end,
    open_float = function() end,
    setloclist = function() end,
  },

  lsp = {
    protocol = {
      make_client_capabilities = function()
        return { textDocument = {}, workspace = {} }
      end,
    },
    buf = {
      definition = function() end,
      declaration = function() end,
      implementation = function() end,
      references = function() end,
      hover = function() end,
      rename = function() end,
      code_action = function() end,
      format = function() end,
      execute_command = function() end,
    },
    buf_request_sync = function() return {} end,
    util = {
      make_range_params = function() return { context = {} } end,
      make_text_document_params = function(bufnr)
        return { uri = "file:///tmp/" .. tostring(bufnr or 0) }
      end,
      make_position_params = function() return { textDocument = { uri = 'file:///tmp/1' }, position = { line = 0, character = 0 } } end,
      apply_workspace_edit = function() end,
      apply_text_edits = function(edits, bufnr, encoding)
        M._state.applied_edits = M._state.applied_edits or {}
        M._state.applied_edits[bufnr] = edits
      end,
    },
    uri_to_bufnr = function(uri)
      -- simplistic mapping: assign a bufnr based on hash
      M._state.uri_map = M._state.uri_map or {}
      if M._state.uri_map[uri] then return M._state.uri_map[uri] end
      local id = (#M._state.uri_map) + 2
      M._state.uri_map[uri] = id
      return id
    end,
    -- Provide set_log_level for compatibility with core.options
    set_log_level = function() end,
    config = setmetatable({}, {
      __newindex = function(_, k, v)
        M._state.lsp_configs[k] = v
      end,
      __index = function(_, k)
        return M._state.lsp_configs[k]
      end,
    }),
    -- Return a default mock client that supports code actions
    get_clients = function(opts)
      return { { id = 1, name = "mock", server_capabilities = { codeActionProvider = true }, offset_encoding = "utf-8" } }
    end,
    enable = function(name)
      M._state.lsp_enabled[name] = true
    end,
  },

  highlight = {
    on_yank = function() end,
  },

  loop = {
    fs_stat = function() return nil end,
  },

  cmd = setmetatable({}, {
    __call = function(_, ...) end,
    __index = function(_, k)
      return function(...)
        M._state.cmd_calls = M._state.cmd_calls or {}
        table.insert(M._state.cmd_calls, { cmd = k, args = {...} })
      end
    end,
  }),

  tbl_extend = function(behavior, ...)
    local result = {}
    for _, t in ipairs({...}) do
      if type(t) == "table" then
        for k, v in pairs(t) do
          result[k] = v
        end
      end
    end
    return result
  end,

  tbl_deep_extend = function(behavior, ...)
    local result = {}
    local function deep_copy(src, dst)
      for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then
          deep_copy(v, dst[k])
        else
          dst[k] = v
        end
      end
    end
    for _, t in ipairs({...}) do
      if type(t) == "table" then
        deep_copy(t, result)
      end
    end
    return result
  end,

  tbl_contains = function(tbl, val)
    for _, v in ipairs(tbl) do
      if v == val then return true end
    end
    return false
  end,

  uri_to_bufnr = function(uri)
    return vim.lsp.uri_to_bufnr(uri)
  end,

  inspect = function(t) return tostring(t) end,
  notify = function() end,
  schedule = function(fn) fn() end,

  log = {
    levels = { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 },
  },
}

function M.reset()
  M._state = {
    options = {},
    global_options = {},
    keymaps = {},
    autocmds = {},
    signs = {},
    diagnostic_config = nil,
    lsp_configs = {},
    lsp_enabled = {},
    cmd_calls = {},
    highlights = {},
  }
  vim_mock.opt = create_opt_proxy()
end

function M.get_state()
  return M._state
end

function M.setup()
  _G.vim = vim_mock
  M.reset()
  return vim_mock
end

return M
