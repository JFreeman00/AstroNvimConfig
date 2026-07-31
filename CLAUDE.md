# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal Neovim configuration built on the [AstroNvim](https://github.com/AstroNvim/AstroNvim) v6 template (see `README.md`), installed at `~/.config/nvim`. There is no build step, no test suite, and no application code — every file is a lazy.nvim plugin spec that is evaluated at Neovim startup. "Running the code" means starting `nvim`.

Some comments and commit messages are in Swedish.

## Commands

```shell
nvim                                        # the only real "run" — errors surface at startup
nvim --headless "+Lazy! sync" +qa           # install/update plugins non-interactively, updates lazy-lock.json
                                            # pinned plugins need 2-3 passes to settle — see "Overriding AstroNvim's plugin pins"
nvim --headless "+checkhealth" +qa          # verify providers, LSP, treesitter
luajit -bl lua/plugins/user/ui.lua >/dev/null   # syntax-check a single Lua file without launching nvim
```

In-editor: `:Lazy` (plugin manager), `:Mason` (LSP/linter/formatter binaries), `:LspInfo`.

`.stylua.toml` and `selene.toml`/`neovim.yml` configure formatting and linting of this config's own Lua, but neither `stylua` nor `selene` is on PATH — `stylua` is in the Mason `ensure_installed` list, so it lives under `~/.local/share/nvim/mason/bin/`. Match the existing style rather than reformatting: 2-space indent, 120 columns, double quotes, no parens on single-argument calls (`require "lazy_setup"`).

`lazy-lock.json` pins every plugin commit; it churns on any `:Lazy` operation. Only commit it when the intent is to record a plugin update.

## Load order

`init.lua` bootstraps lazy.nvim (cloning it if missing) → `lua/lazy_setup.lua` → `lua/polish.lua`.

`lazy_setup.lua` sets `mapleader = <Space>` and `maplocalleader = ,` (they must be set there, before lazy loads), then imports three spec sources in order:

1. `astronvim.plugins` — the AstroNvim distribution itself
2. `lua/community.lua` — AstroCommunity packs (`astrocommunity.pack.lua`), plus an explicit `{ import = "plugins.user" }`
3. `lua/plugins/` — every `.lua` file directly in that folder

The explicit `plugins.user` import in `community.lua` is deliberate (see the comment at the top of that file): it ensures the specs in `lua/plugins/user/` are processed before the top-level `lua/plugins/` files.

`lua/polish.lua` is disabled by a leading `if true then return end`. `lua/plugins/none-ls.lua` uses the same sentinel (`if true then return {} end`), so none-ls loads with AstroNvim's defaults and no custom sources; diagnostics come from nvim-lint instead.

## How configuration is layered

Multiple files return specs for the *same* plugin repo, and lazy.nvim deep-merges their `opts`. This is the central idiom here — to change a setting, find every file naming that repo, not just the obvious one:

- `AstroNvim/astrocore` — `plugins/astrocore.lua` (vim options, diagnostics, filetypes) and `plugins/user/keymaps.lua` (split/tab/buffer mappings)
- `AstroNvim/astrolsp` — `plugins/astrolsp.lua` (features, mappings, autocmds) plus one file per language under `plugins/user/`: `clangd.lua`, `python.lua`, `typescript.lua`
- `AstroNvim/astroui` — `plugins/astroui.lua` (highlights, icons; `colorscheme` is commented out, see below)

New per-language LSP tweaks belong in their own `lua/plugins/user/<lang>.lua` returning `{ "AstroNvim/astrolsp", opts = { servers = {...}, config = { <server> = {...} } } }`.

## Notable deviations from stock AstroNvim

- **Statusline/tabline**: `plugins/user/ui.lua` disables heirline entirely (`{ "rebelot/heirline.nvim", enabled = false }`) and replaces it with bufferline + a hand-rolled orange lualine theme. AstroNvim's own statusline config therefore has no effect.
- **Colorscheme**: set by `plugins/user/colorscheme.lua` calling `vim.cmd "colorscheme onedark"` (onedarkpro, `lazy = false`, `priority = 1000`), *not* by the `astroui` `colorscheme` option, which is commented out.
- **Diagnostics**: virtual text and virtual lines are off at startup; virtual text/underline are restricted to ERROR severity. `astrolsp.lua` adds a `CursorHold` autocmd that shows a floating error diagnostic if the cursor line has one, otherwise falls back to `vim.lsp.buf.hover()`.
- **Formatting**: `format_on_save` is disabled in `plugins/astrolsp.lua`.
- **Linting**: `plugins/user/nvim-lint.lua` maps filetypes to linters and lints on `BufEnter`/`BufWritePost`/`InsertLeave`; JS/TS only lint when an eslint config is found upward from the buffer. It also sets `<leader>l` directly via `vim.keymap.set` rather than through astrocore mappings. It declares `dependencies = { "mason-org/mason.nvim" }` because mason is what puts `~/.local/share/nvim/mason/bin` on `$PATH` — any lazily-loaded plugin that shells out to a Mason binary needs that dependency, or it fails with `ENOENT` when it happens to load first.
- **Folding**: nvim-ufo + statuscol.nvim, with `foldcolumn = "2"`, `foldlevel(start) = 99`, and `fillchars` fold glyphs set in `plugins/astrocore.lua`. AstroNvim v6 dropped its own nvim-ufo integration, so `plugins/user/ufo.lua` is now the only thing configuring ufo — it declares the plugin and its `promise-async` dependency itself.
- **Tooling install**: `plugins/mason.lua` drives everything through `mason-tool-installer` `ensure_installed` with `auto_update = true`. Add new servers/linters/formatters there using the exact `:Mason` package name.
- `endofline`/`fixendofline` are off, so saved files have no trailing newline.

## Known rough edges

- `lua/plugins/user.lua` is still largely the AstroNvim example file and is active: it installs `presence.nvim` and `lsp_signature.nvim`, sets the dashboard ASCII header, disables `better-escape.nvim`, and adds a LuaSnip filetype extension. Note the two similar paths: `plugins/user.lua` (example file) vs `plugins/user/` (the real per-plugin directory).
- `plugins/astrocore.lua` still carries the template's placeholder `fooscript` filetype entries.
- `plugins/astrolsp.lua` has an empty `on_attach` stub.

## Overriding AstroNvim's plugin pins

Because `lazy_setup.lua` tracks `version = "^6"` of AstroNvim, `pin_plugins` defaults to true and AstroNvim imports `astronvim/lua/astronvim/lazy_snapshot.lua`, which pins many plugins to a `version` range or commit. Two consequences:

**Pins do not move on their own.** A plugin stuck on an old major cannot be freed by `:Lazy update` — override it with a user spec, which is imported later and wins the field:

```lua
-- lua/plugins/user/<plugin>.lua
return { "author/plugin.nvim", version = "^4" } -- or `version = false` to track the default branch
```

`lua/plugins/user/aerial.lua` exists for exactly this reason and still overrides *upward* (v6's snapshot pins `^3`; we track `^4`). When a plugin misbehaves on a current Neovim, check `lazy_snapshot.lua` before assuming it's an upstream bug — an archived or stale pin is the more common cause.

**A sync takes several passes.** When the snapshot itself changes (e.g. an AstroNvim major upgrade), one `:Lazy sync` updates AstroNvim but leaves the plugins it pins on their old versions; the new pins only apply on the following run. Run `:Lazy sync` until `astrocore`/`astrolsp`/`astroui` report the majors listed in `lazy_snapshot.lua`. This is what AstroNvim's "run `:Lazy update` twice" notification refers to.

## ESP-IDF

The primary use of this config is embedded ESP-IDF work (with occasional React/JS), and
`lua/plugins/user/clangd.lua` is tuned for it. Mason's clangd is mainline LLVM and has **no xtensa
backend**, so that file resolves Espressif's clangd out of `~/.espressif/tools/esp-clangd/*/` at
startup and falls back to `clangd` on `$PATH` only if it's missing. Two flags matter: `--query-driver`
(globbed onto the xtensa/riscv `*-elf-gcc` binaries, without which every ESP system header reports
"file not found"), and the *absence* of `--compile-commands-dir` — `idf.py` writes
`build/compile_commands.json` and clangd finds a `build/` subdirectory by itself, so pinning that flag
is what breaks database discovery. Don't reintroduce it, and don't add `--suggest-missing-includes`
(obsolete and ignored since clangd 15).

The `--resource-dir` in that file is not optional decoration: Espressif's esp-clangd package contains
**only `bin/clangd`**, with no `lib/clang/<ver>/include`, so clang's own builtin headers (`float.h`,
`stddef.h`, `stdint.h`, `stdarg.h`) don't exist where it looks for them. `--query-driver` does not
cover this — it supplies GCC's *system* headers, not clang's builtins. The config detects the missing
directory and borrows Mason's clangd resource dir instead. If ESP-IDF ever ships a complete
esp-clangd, the check makes the override drop out on its own.

## Treesitter

Since v6, nvim-treesitter tracks its **`main`** branch (the old `master` branch was archived in May 2025 and is broken on Neovim 0.12). Two things follow:

- Parsers are declared through AstroCore, not the nvim-treesitter spec — see `lua/plugins/treesitter.lua`, which returns an `AstroNvim/astrocore` spec setting `treesitter.ensure_installed`. That key is `opts_extend`ed, so entries append to AstroNvim's defaults (`bash`, `c`, `lua`, `markdown`, `markdown_inline`, `python`, `query`, `vim`, `vimdoc`).
- Parsers install to `~/.local/share/nvim/site/parser/`, not into the plugin directory. If highlighting throws query errors like `Invalid field name`, stale `.so` files from the master era are shadowing the new queries — check `~/.local/share/nvim/lazy/nvim-treesitter/parser/` is empty and reinstall with `:TSUpdate`.
