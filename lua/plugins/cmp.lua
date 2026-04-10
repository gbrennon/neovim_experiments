-- Autocompletion Configuration

local M = {}

function M.config()
  local cmp = require("cmp")
  local luasnip = require("luasnip")

  -- Load friendly snippets
  require("luasnip.loaders.from_vscode").lazy_load()

  cmp.setup({
    snippet = {
      expand = function(args)
        luasnip.lsp_expand(args.body)
      end,
    },

    mapping = cmp.mapping.preset.insert({
      ["<C-b>"] = cmp.mapping.scroll_docs(-4),
      ["<C-f>"] = cmp.mapping.scroll_docs(4),
      ["<C-Space>"] = cmp.mapping.complete(),
      ["<C-e>"] = cmp.mapping.abort(),
      ["<CR>"] = cmp.mapping.confirm({ select = false }),
      ["<Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_next_item()
        elseif luasnip.expand_or_jumpable() then
          luasnip.expand_or_jump()
        else
          fallback()
        end
      end, { "i", "s" }),
      ["<S-Tab>"] = cmp.mapping(function(fallback)
        if cmp.visible() then
          cmp.select_prev_item()
        elseif luasnip.jumpable(-1) then
          luasnip.jump(-1)
        else
          fallback()
        end
      end, { "i", "s" }),
    }),

    sources = cmp.config.sources({
      { name = "nvim_lsp", priority = 1000 },
      { name = "luasnip", priority = 750 },
      { name = "buffer", priority = 500 },
      { name = "path", priority = 250 },
    }),

    experimental = {
      ghost_text = true,
    },
  })

  vim.api.nvim_create_autocmd("User", {
    pattern = "CmpConfirmDone",
    callback = function(ctx)
      local completion_item = ctx.data.completion_item
      if completion_item and completion_item.additionalTextEdits and #completion_item.additionalTextEdits > 0 then
        vim.schedule(function()
          vim.lsp.util.apply_text_edits(completion_item.additionalTextEdits, ctx.buf, "utf-8")
        end)
      end
    end,
  })

  -- Set configuration for specific filetype
  cmp.setup.filetype("gitcommit", {
    sources = cmp.config.sources({
      { name = "buffer" },
    }),
  })

  -- Use buffer source for `/` and `?`
  cmp.setup.cmdline({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline(),
    sources = {
      { name = "buffer" },
    },
  })

  -- Use cmdline & path source for ':'
  cmp.setup.cmdline(":", {
    mapping = cmp.mapping.preset.cmdline(),
    sources = cmp.config.sources({
      { name = "path" },
    }, { { name = "cmdline" }, }),
  })
end

-- Plugin spec for lazy.nvim
return {
  "hrsh7th/nvim-cmp",
  event = { "InsertEnter", "CmdlineEnter" },
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",
    "hrsh7th/cmp-buffer",
    "hrsh7th/cmp-path",
    "hrsh7th/cmp-cmdline",
    "L3MON4D3/LuaSnip",
    "saadparwaiz1/cmp_luasnip",
    "rafamadriz/friendly-snippets",
  },
  config = M.config,
  _module = M,
}
