vim.lsp.enable({
  "clangd_ls",
  "lua_ls",
  "python_ls",
  "cmake_ls"
})

vim.diagnostic.config({
  virtual_lines = true,
  virtual_text = false,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
  },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
    numhl = {
      [vim.diagnostic.severity.ERROR] = "ErrorMsg",
      [vim.diagnostic.severity.WARN] = "WarningMsg",
    },
  },
})

-- Define LSP-related keymaps
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
  callback = function(event)
    vim.keymap.set('n', 'gd', function()
      local params = vim.lsp.util.make_position_params(0, 'utf-8')
      vim.lsp.buf_request(0, 'textDocument/definition', params, function(_, result, _, _)
        if not result or vim.tbl_isempty(result) then
          vim.notify('No definition found', vim.log.levels.INFO)
        else
          require('snacks').picker.lsp_definitions()
        end
      end)
    end, { buffer = event.buf, desc = 'LSP: Goto Definition' })

    vim.keymap.set('n', 'gD', function()
      local win = vim.api.nvim_get_current_win()
      local width = vim.api.nvim_win_get_width(win)
      local height = vim.api.nvim_win_get_height(win)

      -- Mimic tmux formula: 8 * width - 20 * height
      local value = 8 * width - 20 * height
      if value < 0 then
        vim.cmd 'split'  -- vertical space is more: horizontal split
      else
        vim.cmd 'vsplit' -- horizontal space is more: vertical split
      end

      vim.lsp.buf.definition()
    end, { buffer = event.buf, desc = 'LSP: Goto Definition (split)' })
    vim.keymap.set('n', 'gr', function()
      -- require('telescope.builtin').lsp_references()
      require('snacks').picker.lsp_references()
    end, { buffer = event.buf, desc = 'LSP: Goto References' })

    -- vim.keymap.set('n', '<leader>a', vim.lsp.buf.code_action, { buffer = event.buf, desc = 'Lsp Action' })
    vim.keymap.set('n', 'gR', vim.lsp.buf.rename, { buffer = event.buf, desc = 'LSP: Rename' })

    -- Diagnostics
    -- vim.keymap.set('n', '<leader>d', function()
    --   vim.diagnostic.open_float { source = true }
    -- end, { buffer = event.buf, desc = 'LSP: Show Diagnostic' })
    vim.keymap.set(
      'n',
      '<leader>t',
      (function()
        local diag_status = 1 -- 1 is show; 0 is hide
        return function()
          if diag_status == 1 then
            diag_status = 0
            vim.diagnostic.config { underline = false, virtual_lines = false, virtual_text = false, signs = false, update_in_insert = false }
          else
            diag_status = 1
            vim.diagnostic.config { underline = true, virtual_lines = true, virtual_text = false, signs = true, update_in_insert = false }
          end
        end
      end)(),
      { buffer = event.buf, desc = 'LSP: Toggle diagnostics display' }
    )

    local client = vim.lsp.get_client_by_id(event.data.client_id)
    -- inlay suppoer
    if client and client:supports_method 'textDocument/inlayHint' then
      vim.lsp.inlay_hint.enable(true, { bufnr = event.buf })
    end
    -- folding
    if client and client:supports_method 'textDocument/foldingRange' then
      local win = vim.api.nvim_get_current_win()
      vim.wo[win][0].foldexpr = 'v:lua.vim.lsp.foldexpr()'
    end

    -- Highlight words under cursor
    if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) and vim.bo.filetype ~= 'bigfile' then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
          -- vim.cmd 'setl foldexpr <'
        end,
      })
    end
  end,
})
