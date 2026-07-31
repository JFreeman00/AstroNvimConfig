-- As of AstroNvim v6, nvim-treesitter tracks its `main` branch and parsers are no longer declared
-- in the nvim-treesitter spec — they go through AstroCore's `treesitter.ensure_installed`
-- (`opts_extend`ed, so this list is appended to AstroNvim's defaults rather than replacing them).
---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      ensure_installed = {
        "lua",
        "vim",
        -- embedded / ESP-IDF
        "cpp",
        "cmake",
        -- web
        "javascript",
        "typescript",
        "tsx",
        "jsdoc",
        "html",
        "css",
        "json",
        -- add more arguments for adding more treesitter parsers
      },
    },
  },
}
