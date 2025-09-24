---@class CMakeInitializeResult: lsp.InitializeResult

return {
  cmd = { 'cmake-language-server' }, -- 如果 brew 安裝後不在 PATH，可改成絕對路徑
  filetypes = { 'cmake' },
  root_markers = {
    'CMakeLists.txt',
    'compile_commands.json',
    '.git',
  },
  init_options = {
    buildDirectory = 'build', -- 預設 build 資料夾
  },
  capabilities = {},
  ---@param client vim.lsp.Client
  ---@param _ CMakeInitializeResult
  on_init = function(client, _)
    -- 這裡通常不需要特別處理
  end,
  on_attach = function(_, bufnr)
    -- 這邊可以放專屬 keymaps, 例如:
    -- vim.keymap.set('n', '<leader>cb', ':!cmake --build build<CR>', { buffer = bufnr, desc = 'CMake Build' })
  end,
}
