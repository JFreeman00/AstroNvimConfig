-- AstroNvim's `lazy_snapshot.lua` pins aerial to `version = "^2.2"` (pinning is active because
-- `lazy_setup.lua` tracks `version = "^5"` of AstroNvim). Aerial 2.x still calls the
-- `iter_matches({ all = false })` API that Neovim 0.12 removed, which throws
-- "attempt to call method 'start' (a nil value)" from its treesitter backend on every buffer attach.
-- The fix landed in aerial 3.1.0; 4.0.0 requires Neovim >= 0.12, which we have.
-- This spec is imported after the snapshot, so it wins the `version` field.
---@type LazySpec
return {
  "stevearc/aerial.nvim",
  version = "^4",
}
