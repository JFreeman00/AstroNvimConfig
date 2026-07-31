-- Code linting
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  -- The linters below are Mason packages, and mason.nvim is what puts
  -- `~/.local/share/nvim/mason/bin` on $PATH. Without this dependency nvim-lint can run before
  -- mason has loaded and every linter fails with "ENOENT: no such file or directory".
  -- (AstroNvim v5 force-loaded mason from its treesitter spec; v6 no longer does.)
  dependencies = { "mason-org/mason.nvim" },
  config = function()
    local lint = require "lint"

    -- Configure linters by filetype
    lint.linters_by_ft = {
      -- JavaScript/TypeScript
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },

      -- Python
      python = { "pylint" },

      -- C/C++
      cpp = { "cpplint" },
      c = { "cpplint" },

      -- Java
      java = { "checkstyle" },

      -- JSON
      json = { "jsonlint" },

      -- Uncomment to enable more linters:
      -- lua = { "luacheck" },
      -- sh = { "shellcheck" },
      dockerfile = { "hadolint" },
      -- yaml = { "yamllint" },
    }

    -- Create autogroup for linting
    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    -- Function to check for ESLint config files in project root
    local function has_eslint_config()
      local config_files = { ".eslintrc.js", ".eslintrc.json", ".eslintrc.cjs", ".eslintrc", "eslint.config.js" }
      local found = vim.fs.find(config_files, {
        upward = true,
        type = "file",
        path = vim.fs.dirname(vim.api.nvim_buf_get_name(0)),
      })
      return #found > 0
    end

    -- Auto-lint on buffer events
    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        local ft = vim.bo.filetype

        -- Enable linting if file found
        if ft:match "javascript" or ft:match "typescript" then
          if has_eslint_config() then lint.try_lint() end
        else
          lint.try_lint()
        end
      end,
    })

    -- Manual linting keybinding
    vim.keymap.set("n", "<leader>l", function() lint.try_lint() end, { desc = "Trigger linting for current file" })
  end,
}
