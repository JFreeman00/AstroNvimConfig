-- Single source of truth for nvim-autopairs.
-- AstroNvim already sets `check_ts = true`, `ts_config = { java = false }`, `fast_wrap` and the
-- completion integration, so only the deltas belong here — lazy.nvim deep-merges these opts.
---@type LazySpec
return {
  "windwp/nvim-autopairs",
  opts = {
    ts_config = {
      lua = { "string" }, -- don't add pairs in lua string treesitter nodes
    },
  },
}
