local root = vim.fn.stdpath("config")

local function fail(message)
  error("LSP smoke test failed: " .. message)
end

local function wait_for_clients(expected, timeout)
  local attached = vim.wait(timeout or 15000, function()
    local names = {}
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
      names[client.name] = true
    end
    for _, name in ipairs(expected) do
      if not names[name] then
        return false
      end
    end
    return true
  end, 100)
  if not attached then
    local actual = vim.tbl_map(function(client)
      return client.name
    end, vim.lsp.get_clients({ bufnr = 0 }))
    fail("expected " .. table.concat(expected, ", ") .. "; attached: " .. table.concat(actual, ", "))
  end
end

local function wait_for_diagnostics(expected_sources, timeout)
  if not vim.wait(timeout or 15000, function()
    local found = {}
    for _, diagnostic in ipairs(vim.diagnostic.get(0)) do
      found[(diagnostic.source or ""):lower()] = true
    end
    for _, source in ipairs(expected_sources) do
      if not found[source:lower()] then
        return false
      end
    end
    return true
  end, 100) then
    fail("missing diagnostics from " .. table.concat(expected_sources, ", "))
  end
end

local function assert_completion(client_name)
  local client = vim.lsp.get_clients({ bufnr = 0, name = client_name })[1]
  if not client or not client.server_capabilities.completionProvider then
    fail(client_name .. " has no completion provider")
  end
end

local function assert_mapping(mode, lhs)
  if vim.fn.maparg(lhs, mode) == "" then
    fail("missing " .. mode .. "-mode mapping for " .. lhs)
  end
end

vim.cmd.edit(root .. "/tests/fixtures/python_broken.py")
assert_mapping("n", "Z")
assert_mapping("x", "Z")
assert_mapping("n", "gcc")
assert_mapping("x", "gcc")
wait_for_clients({ "python_ls", "ruff_ls" })
wait_for_diagnostics({ "Pyright", "Ruff" })
assert_completion("python_ls")
local ruff = vim.lsp.get_clients({ bufnr = 0, name = "ruff_ls" })[1]
if not ruff:supports_method("textDocument/formatting") then
  fail("Ruff formatting is unavailable")
end

vim.cmd.edit(root .. "/tests/fixtures/cpp_broken.cpp")
wait_for_clients({ "clangd_ls" })
wait_for_diagnostics({ "clang" })
assert_completion("clangd_ls")

print("LSP_SMOKE_OK python_ls+ruff_ls clangd_ls diagnostics completion formatting")
vim.cmd("qa!")
