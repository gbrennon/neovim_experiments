-- Autocommands Configuration

local M = {}

local AUTO_IMPORT_ACTION_KINDS = {
  "source.addMissingImports",
  "source.addMissingImports.ts",
  "source.organizeImports",
  "source.organizeImports.ts",
  "source.fixAll",
  "source.fixAll.ts",
}

local function restart_lsp_except_copilot()
  local clients = vim.lsp.get_clients()
  for _, client in ipairs(clients) do
    if client.name ~= "copilot" then
      vim.lsp.stop_client(client.id, true)
    end
  end
end

local function run_auto_import_actions(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  if #clients == 0 then
    return
  end

  local has_codeaction = false
  local encoding = "utf-8"
  for _, client in ipairs(clients) do
    encoding = client.offset_encoding or encoding
    if client.server_capabilities and client.server_capabilities.codeActionProvider then
      has_codeaction = true
    end
  end

  if not has_codeaction then
    return
  end

  for _, action_kind in ipairs(AUTO_IMPORT_ACTION_KINDS) do
    local params = {
      textDocument = vim.lsp.util.make_text_document_params(bufnr),
      range = {
        start = { line = 0, character = 0 },
        ["end"] = { line = 0, character = 0 },
      },
    }
    params.context = { only = { action_kind } }
    local result = vim.lsp.buf_request_sync(bufnr, "textDocument/codeAction", params, 1000)
    for _, res in pairs(result or {}) do
      for _, action in pairs(res.result or {}) do
        if action.edit then
          vim.lsp.util.apply_workspace_edit(action.edit, encoding)
        end
        if action.command then
          vim.lsp.buf.execute_command(action.command)
        end
      end
    end
  end
end

function M.setup()
  local augroup = vim.api.nvim_create_augroup
  local autocmd = vim.api.nvim_create_autocmd

  -- General settings group
  local general = augroup("General", { clear = true })

  -- Highlight on yank
  autocmd("TextYankPost", {
    group = general,
    callback = function()
      vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
    end,
    desc = "Highlight on yank",
  })

  -- Remove trailing whitespace on save
  autocmd("BufWritePre", {
    group = general,
    pattern = "*",
    command = [[%s/\s\+$//e]],
    desc = "Remove trailing whitespace",
  })

  -- Restore cursor position
  autocmd("BufReadPost", {
    group = general,
    callback = function()
      local mark = vim.api.nvim_buf_get_mark(0, '"')
      local lcount = vim.api.nvim_buf_line_count(0)
      if mark[1] > 0 and mark[1] <= lcount then
        pcall(vim.api.nvim_win_set_cursor, 0, mark)
      end
    end,
    desc = "Restore cursor position",
  })

  -- Close some filetypes with <q>
  autocmd("FileType", {
    group = general,
    pattern = { "help", "lspinfo", "man", "notify", "qf", "checkhealth" },
    callback = function(event)
      vim.bo[event.buf].buflisted = false
      vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
    desc = "Close certain filetypes with q",
  })

  -- Simple FocusGained: check for external changes
  autocmd("FocusGained", {
    group = general,
    command = "checktime",
    desc = "Check if file changed",
  })

  -- Auto resize splits on VimResized
  autocmd("VimResized", {
    group = general,
    callback = function()
      vim.cmd("tabdo wincmd =")
    end,
    desc = "Auto resize splits",
  })

  -- Check if file changed outside of vim and auto-reload
  autocmd({ "FocusGained", "TermClose", "TermLeave", "BufEnter", "CursorHold" }, {
    group = general,
    callback = function()
      -- Check for file changes and reload buffer if changed
      vim.cmd("checktime")

      -- Refresh nvim-tree if it's loaded and open
      local nvim_tree_ok, api = pcall(require, "nvim-tree.api")
      if nvim_tree_ok then
        local view = require("nvim-tree.view")
        if view.is_visible() then
          -- Use the exposed command to refresh nvim-tree which is more stable across versions
          vim.cmd("NvimTreeRefresh")
        end
      end
    end,
    desc = "Auto-reload files and refresh nvim-tree on focus/cursor hold",
  })

  -- LSP refresh and auto-import group
  local lsp_group = augroup("LspAutoImport", { clear = true })

  -- Auto-import / organize imports on save
  autocmd("BufWritePre", {
    group = lsp_group,
    pattern = { "*.ts", "*.tsx", "*.js", "*.jsx", "*.py", "*.go", "*.rs", "*.scala" },
    callback = function(event)
      run_auto_import_actions(event and event.buf or 0)
    end,
    desc = "Auto-import and organize imports on save",
  })

  -- LSP auto-refresh group
  local lsp_refresh_group = augroup("LspAutoRefresh", { clear = true })

  -- Auto-reload Neovim config when config files change
  local nvim_config_group = augroup("NvimConfigReload", { clear = true })

  autocmd("BufWritePost", {
    group = nvim_config_group,
    pattern = { "*init.lua", "*/lua/core/*.lua", "*/lua/plugins/*.lua" },
    callback = function(event)
      vim.defer_fn(function()
        local filename = vim.fn.fnamemodify(event.file, ":t")
        vim.notify("Config reload triggered for: " .. filename, vim.log.levels.WARN)

        -- Clear require cache for lua modules
        for module_name, _ in pairs(package.loaded) do
          if module_name:match("^core%.") or module_name:match("^plugins%.") then
            package.loaded[module_name] = nil
          end
        end

        -- Reload the modified file
        local relative_path = event.file:gsub(vim.fn.stdpath("config") .. "/", ""):gsub("%.lua$", ""):gsub("/", ".")
        if relative_path:match("^init$") then
          pcall(function()
            require("core.options")
            require("core.keymaps")
            require("core.autocmds")
          end)
        elseif relative_path:match("^core%.") then
          pcall(require, relative_path)
        elseif relative_path:match("^plugins%.") then
          pcall(require, relative_path)
        end

        vim.notify(filename .. " reloaded!", vim.log.levels.INFO)
      end, 100)
    end,
    desc = "Auto-reload Neovim config files",
  })

  -- Restart LSP when config files change
  autocmd({ "BufWritePost", "FileChangedShellPost" }, {
    group = lsp_refresh_group,
    pattern = {
      "pyproject.toml", "requirements.txt", "setup.py", "setup.cfg", "Pipfile", "pyrightconfig.json",
      "tsconfig.json", "jsconfig.json", "package.json", "package-lock.json",
      "go.mod", "go.work", "go.sum", "Cargo.toml", "Cargo.lock",
      "build.sbt", "build.sc", ".scala-build",
      ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml"
    },
    callback = function(event)
      vim.defer_fn(function()
        local filename = vim.fn.fnamemodify(event.file, ":t")
        vim.notify("Config file " .. filename .. " changed. Restarting LSP (excluding Copilot)...", vim.log.levels.INFO)

        -- Use the reliable vim.lsp restart approach
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
          if client.name ~= "copilot" then
            local buffers = vim.lsp.get_buffers_by_client_id(client.id)
            vim.lsp.stop_client(client.id, true)

            vim.defer_fn(function()
              for _, buf in ipairs(buffers) do
                if vim.api.nvim_buf_is_valid(buf) then
                  local filetype = vim.api.nvim_get_option_value("filetype", { buf = buf })
                  vim.api.nvim_exec_autocmds("FileType", {
                    buffer = buf,
                    data = { filetype = filetype }
                  })
                end
              end
            end, 1500)
          end
        end
      end, 500)
    end,
    desc = "Restart LSP when config files change",
  })

  -- Alternative: Watch for external config changes using vim's file watching
  autocmd({ "FocusGained", "BufEnter" }, {
    group = lsp_refresh_group,
    callback = function()
      -- Check if any config files changed and restart if needed
      local config_files = {
        "pyproject.toml", "requirements.txt", "package.json", "tsconfig.json",
        "go.mod", "Cargo.toml", "build.sbt", ".luarc.json"
      }

      for _, config_file in ipairs(config_files) do
        local filepath = vim.fn.expand(config_file)
        if vim.fn.filereadable(filepath) == 1 then
          -- Check if file was modified since last check
          local modtime = vim.fn.getftime(filepath)
          local last_modtime = vim.g["lsp_config_modtime_" .. config_file:gsub("%.", "_")]

          if last_modtime and modtime > last_modtime then
            vim.g["lsp_config_modtime_" .. config_file:gsub("%.", "_")] = modtime
            vim.notify("Detected " .. config_file .. " changes. Restarting LSP (excluding Copilot)...", vim.log.levels.INFO)
            restart_lsp_except_copilot()
            break
          elseif not last_modtime then
            -- Initialize the timestamp
            vim.g["lsp_config_modtime_" .. config_file:gsub("%.", "_")] = modtime
          end
        end
      end
    end,
    desc = "Check for config file changes on focus and restart LSP",
  })

  -- Auto-refresh quickfix list on diagnostics change
  local quickfix_group = augroup("QuickfixAutoRefresh", { clear = true })
  autocmd("DiagnosticChanged", {
    group = quickfix_group,
    callback = function()
      -- Check if quickfix list is open
      local qf_list = vim.fn.getqflist()
      if #qf_list > 0 then
        -- Refresh with latest diagnostics
        vim.diagnostic.setqflist()
      end
    end,
    desc = "Auto-refresh quickfix list when diagnostics change",
  })
end

-- Auto-run setup when loaded
M.setup()

return M
