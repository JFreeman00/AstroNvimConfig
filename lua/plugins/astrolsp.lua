---@type LazySpec
return {
  "AstroNvim/astrolsp",
  ---@type AstroLSPOpts
  opts = {
    features = {
      codelens = true,
      inlay_hints = true, -- powers the `ts_ls` hint settings in `plugins/user/typescript.lua`; `<Leader>uH` toggles per buffer
      semantic_tokens = true,
    },
    formatting = {
      format_on_save = {
        enabled = false,
        allow_filetypes = {},
        ignore_filetypes = {},
      },
      disabled = {},
      timeout_ms = 1000,
    },
    servers = {},
    config = {},
    handlers = {},
    -- Buffer-local autocmds

    autocmds = {
      lsp_codelens_refresh = {
        {
          event = { "InsertLeave", "BufEnter" },
          desc = "Refresh codelens (buffer)",
          callback = function(args)
            if require("astrolsp").config.features.codelens then vim.lsp.codelens.refresh { bufnr = args.buf } end
          end,
        },
      },
      lsp_hover_diagnostics = {
        {
        event = "CursorHold",
        desc = "Show diagnostics on error, otherwise hover",
        callback = function()
          local bufnr = 0
          local line = vim.api.nvim_win_get_cursor(0)[1] - 1

          -- Hämta ENDAST errors på aktuell rad
          local errors = vim.diagnostic.get(bufnr, {
            lnum = line,
            severity = vim.diagnostic.severity.ERROR,
          })

          if #errors > 0 then
            -- Visa error diagnostic
            vim.diagnostic.open_float(nil, {
              focusable = false,
              close_events = { "CursorMoved", "InsertEnter", "BufLeave" },
              border = "rounded",
              source = "always",
              scope = "cursor",
            })
          else
            -- Annars: visa hover (metod-signatur, returtyp, docs)
            vim.lsp.buf.hover()
          end
        end,
        },
      },
    },
    -- Key mappings for LSP
    mappings = {
      n = {
        gD = {
          function() vim.lsp.buf.declaration() end,
          desc = "Declaration of current symbol",
          cond = "textDocument/declaration",
        },
        ["<Leader>uY"] = {
          function() require("astrolsp.toggles").buffer_semantic_tokens() end,
          desc = "Toggle LSP semantic highlight (buffer)",
          cond = function(client)
            return client:supports_method "textDocument/semanticTokens/full" and vim.lsp.semantic_tokens ~= nil
          end,
        },
        ["<Leader>lh"] = {
          function() vim.lsp.buf.hover() end,
          desc = "Show function signature and documentation",
          cond = "textDocument/hover",
        },
        K = {
          function() vim.lsp.buf.hover() end,
          desc = "Show hover (function details)",
          cond = "textDocument/hover",
        },
        ["<Leader>ld"] = {
          function()
            vim.diagnostic.open_float(nil, {
              focusable = true,
              border = "rounded",
              source = "always",
              scope = "cursor",
            })
          end,
          desc = "Show diagnostics (persistent)",
        },
      },
      i = {
        ["<C-k>"] = {
          function() vim.lsp.buf.signature_help() end,
          desc = "LSP Signature Help",
          cond = "textDocument/signatureHelp",
        },
      },
    },
    -- Custom on_attach function
    on_attach = function(client, bufnr)
      -- Optional: disable semanticTokensProvider for all clients
      -- client.server_capabilities.semanticTokensProvider = nil
    end,
  },
}
