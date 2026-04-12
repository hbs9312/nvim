local M = {}

--- Transform an import path for gf navigation.
--- Handles: @/ aliases, dot-separated Python modules, index file resolution.
function M.includeexpr(fname)
  -- JS/TS: replace @/ alias with src/
  local transformed = fname:gsub("^@/", "src/")

  -- Python: replace dot imports with path separators (e.g. foo.bar -> foo/bar)
  if vim.bo.filetype == "python" then
    transformed = transformed:gsub("%.", "/")
  end

  -- JS/TS: try index file if path points to a directory
  if vim.fn.isdirectory(transformed) == 1 then
    return transformed .. "/index"
  end

  return transformed
end

return M
