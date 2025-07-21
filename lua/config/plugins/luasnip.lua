return {
  {
    "L3MON4D3/LuaSnip",
    version = "v2.*",
    build = "make install_jsregexp",
    dependencies = {
      {
        "rafamadriz/friendly-snippets",
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
    },
    config = function()
      local ls = require("luasnip")
      local s = ls.snippet
      local t = ls.text_node
      local i = ls.insert_node
      local rep = require("luasnip.extras").rep

      -- Python snippets
      ls.add_snippets("python", {
        s("def", {
          t({ "def " }), i(1, "function_name"), t("("), i(2, "args"), t({ "):", "    " }),
          i(0, "pass"),
        }),
        s("class", t({
            "class ", -- 加上插入點後會拼接
          }), i(1, "ClassName"),
          t({
            ":",
            "    def __init__(self):",
            "        ",
          }),
          i(0)
        ),
      })
      -- C snippets
      ls.add_snippets("c", {
        s("main", {
          t({ "#include <stdio.h>", "", "int main() {", "    " }),
          i(1, "// code"), t({ "", "    return 0;", "}" }),
        }),
      })

      -- C++ snippets
      ls.add_snippets("cpp", {
        s("main", {
          t({ "#include <iostream>", "", "int main() {", "    " }),
          i(1, "// code"), t({ "", "    return 0;", "}" }),
        }),
        s("fori", {
          t("for (int "), i(1, "i"), t(" = 0; "), rep(1), t(" < "), i(2, "n"),
          t("; "), rep(1), t("++) {\n    "), i(0), t("\n}"),
        }),
      })

      -- CUDA snippets
      ls.add_snippets("cuda", {
        s("kernel", {
          t("__global__ void "), i(1, "kernel_name"), t("("), i(2, "args"), t(") {\n    "),
          i(0, "// CUDA code"), t("\n}"),
        }),
      })

      -- Luasnip 全域設定
      ls.config.set_config({
        history = true,
        updateevents = "TextChanged,TextChangedI",
        enable_autosnippets = false,
      })
      -- 這是 Enter 跳下一個輸入點的 keymap 綁定
      vim.keymap.set({ "i", "s" }, "<CR>", function()
        if ls.expand_or_jumpable() then
          return ls.expand_or_jump()
        else
          return "<CR>"
        end
      end, { expr = true, silent = true })

      vim.keymap.set({ "i", "s" }, "<S-CR>", function()
        if ls.jumpable(-1) then
          return ls.jump(-1)
        else
          return "<S-CR>"
        end
      end, { expr = true, silent = true })
    end,
  },
}
