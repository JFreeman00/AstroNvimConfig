-- clangd tuned for ESP-IDF.
--
-- Three things matter here and all of them are easy to get wrong:
--
--  1. Mason's clangd is mainline LLVM, which has no xtensa backend — it cannot parse ESP32/S2/S3
--     sources at all. Espressif ships its own clangd under `~/.espressif/tools/esp-clangd/`; we
--     prefer that and fall back to whatever `clangd` is on $PATH (fine for RISC-V C3/C6 targets).
--  2. `idf.py` writes `build/compile_commands.json`. clangd already looks in a `build/`
--     subdirectory while walking up from the file, so do NOT pass `--compile-commands-dir` —
--     pinning it to the project root is what stops the database from being found.
--  3. Without `--query-driver`, clangd will not ask the cross-compiler for its system include
--     paths, which is what produces the wall of bogus "file not found" on `stdint.h`,
--     `freertos/FreeRTOS.h` and friends.
--
-- If Espressif's toolchains ever move, only the two globs below need updating.

local espressif = vim.fn.expand "~/.espressif/tools"

---Newest matching path for a glob, or nil.
---@param pattern string
---@return string?
local function latest(pattern)
  local matches = vim.fn.glob(pattern, false, true)
  table.sort(matches) -- version directories sort lexicographically by date suffix
  return matches[#matches]
end

-- xtensa-esp-elf/<ver>/xtensa-esp-elf/bin/xtensa-esp32s3-elf-gcc, riscv32-esp-elf/... etc.
local query_driver = espressif .. "/*/*/*/bin/*-elf-gcc"

local esp_clangd = latest(espressif .. "/esp-clangd/*/esp-clangd/bin/clangd")

local cmd = {
  esp_clangd or "clangd",
  "--query-driver=" .. query_driver,
  "--background-index",
  "--clang-tidy",
  "--all-scopes-completion",
  "--completion-style=detailed",
  "--header-insertion=never",
  "--pch-storage=memory",
}

-- Espressif's esp-clangd package ships *only* `bin/clangd` — it has no `lib/clang/<ver>/include`,
-- so the compiler-resident headers (float.h, stddef.h, stdint.h, stdarg.h) that clang expects to
-- find in its own resource directory simply aren't there. That surfaces as
-- "in included file: 'float.h' file not found" on every ESP-IDF source. `--query-driver` does not
-- help: it supplies GCC's *system* headers, not clang's builtins. Borrow the resource directory
-- from Mason's clangd, which is a complete LLVM install.
if esp_clangd and not latest(vim.fs.dirname(vim.fs.dirname(esp_clangd)) .. "/lib/clang/*/include") then
  local resource_dir = latest(vim.fn.stdpath "data" .. "/mason/packages/clangd/*/lib/clang/*")
  if resource_dir then table.insert(cmd, "--resource-dir=" .. resource_dir) end
end

---@type LazySpec
return {
  "AstroNvim/astrolsp",
  opts = {
    -- customize language server configuration options passed to `lspconfig`
    ---@diagnostic disable: missing-fields
    config = {
      clangd = {
        cmd = cmd,
        capabilities = {
          offsetEncoding = "utf-8",
        },
        init_options = {
          clangdFileStatus = true,
          usePlaceholders = true,
          completeUnimported = true,
          semanticHighlighting = true,
        },
      },
    },
  },
}
