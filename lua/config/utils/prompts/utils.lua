return {
  code = function(args)
    local context = args.context or {}
    if context.is_visual and context.code then
      return context.code
    end

    local bufnr = context.bufnr or 0
    local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if #lines == 0 then
      return ""
    end

    return vim.pesc(table.concat(lines, "\n"))
  end,
  git_diff = function()
    local result = vim.system({ "git", "diff", "--no-ext-diff" }, { text = true }):wait()
    if result.code ~= 0 or not result.stdout then
      return ""
    end
    return result.stdout
  end,
}
