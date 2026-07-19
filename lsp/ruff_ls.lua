return {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = {
    "pyproject.toml",
    "ruff.toml",
    ".ruff.toml",
    "setup.py",
    "setup.cfg",
    ".git",
  },
  init_options = {
    settings = {
      lint = { run = "onType" },
    },
  },
  on_attach = function(client)
    -- Pyright provides richer hover information; Ruff owns linting/formatting.
    client.server_capabilities.hoverProvider = false
  end,
}
