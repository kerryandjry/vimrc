local M = {}

local function notify_result(label, result)
  local output = table.concat({ result.stdout or "", result.stderr or "" }, "\n"):gsub("^%s+", ""):gsub("%s+$", "")
  if output ~= "" then
    vim.schedule(function()
      vim.notify(output, result.code == 0 and vim.log.levels.INFO or vim.log.levels.ERROR, { title = label })
    end)
  end
  return result.code == 0
end

local function run(command, options, on_success)
  vim.system(command, vim.tbl_extend("force", { text = true }, options or {}), function(result)
    if notify_result(table.concat(command, " "), result) and on_success then
      vim.schedule(on_success)
    end
  end)
end

local function open_terminal(command, cwd)
  vim.cmd("botright new")
  vim.fn.jobstart(command, { term = true, cwd = cwd })
  vim.cmd("startinsert")
end

local function run_python(file)
  local root = vim.fs.root(file, { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", ".git" })
    or vim.fn.fnamemodify(file, ":h")
  local candidates = {}
  if vim.env.VIRTUAL_ENV then
    table.insert(candidates, vim.env.VIRTUAL_ENV .. "/bin/python")
  end
  table.insert(candidates, root .. "/.venv/bin/python")
  table.insert(candidates, root .. "/venv/bin/python")

  local interpreter = ""
  for _, candidate in ipairs(candidates) do
    if vim.fn.executable(candidate) == 1 then
      interpreter = candidate
      break
    end
  end
  interpreter = interpreter ~= "" and interpreter or vim.fn.exepath("python3")
  open_terminal({ interpreter ~= "" and interpreter or "python3", file }, vim.fn.fnamemodify(file, ":h"))
end

local function run_cpp(file)
  local project_root = vim.fs.root(file, { "CMakeLists.txt" })
  if project_root then
    local build_dir = project_root .. "/build"
    run({ "cmake", "-S", project_root, "-B", build_dir, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" }, {}, function()
      run({ "cmake", "--build", build_dir }, {}, function()
        vim.notify("CMake build completed: " .. build_dir, vim.log.levels.INFO)
      end)
    end)
    return
  end

  local env_prefix = vim.env.NVIM_ENV_PREFIX
    or ((vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")) .. "/nvim-portable/env")
  local compiler = vim.fn.exepath("g++")
  if compiler == "" then
    compiler = vim.fn.exepath("c++")
  end
  if compiler == "" then
    local portable_compilers = vim.fn.glob(env_prefix .. "/bin/clang++*", false, true)
    compiler = portable_compilers[#portable_compilers] or vim.fn.exepath("clang++")
  end
  if compiler == "" then
    return vim.notify("clang++ or g++ was not found", vim.log.levels.ERROR)
  end
  local output = vim.fn.stdpath("cache") .. "/nvim-run-" .. vim.fn.getpid()
  run({ compiler, "-std=c++20", "-Wall", "-Wextra", "-g", file, "-o", output }, {}, function()
    open_terminal({ output }, vim.fn.fnamemodify(file, ":h"))
  end)
end

function M.run_current()
  vim.cmd("write")
  local file = vim.api.nvim_buf_get_name(0)
  if vim.bo.filetype == "python" then
    run_python(file)
  elseif vim.bo.filetype == "cpp" then
    run_cpp(file)
  else
    vim.notify("F3 supports Python and C++ files", vim.log.levels.WARN)
  end
end

vim.keymap.set("n", "<F3>", M.run_current, { desc = "Run current Python/C++ file" })
vim.api.nvim_create_user_command("RunFile", M.run_current, { desc = "Run current Python/C++ file" })

return M
