-- Configuração de Linter (Linters externos além do LSP)
return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    lint.linters_by_ft = {
      javascript = { "eslint_d" },
      typescript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      python = { "pylint" },
      cpp = { "cpplint" },
    }

    -- Configuração customizada para Linters
    lint.linters.cpplint.args = {
      "--filter=-legal/copyright,-whitespace/comments,-readability/todo",
      "--linelength=120",
    }

    lint.linters.pylint.args = {
      "--max-line-length=120",
      "--disable=C0114,C0115,C0116,W0511", -- Desativa avisos de docstrings e TODOs
    }

    local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
      group = lint_augroup,
      callback = function()
        lint.try_lint()
      end,
    })

    -- Atalho para disparar o lint manualmente
    vim.keymap.set("n", "<leader>cl", function()
      lint.try_lint()
    end, { desc = "Trigger linting for current file" })

    -- Atalho para alternar a exibição de avisos (Diagnostics)
    local diagnostics_active = true
    vim.keymap.set("n", "<leader>ud", function()
      diagnostics_active = not diagnostics_active
      if diagnostics_active then
        vim.diagnostic.show()
        print("Diagnostics Habilitados")
      else
        vim.diagnostic.hide()
        print("Diagnostics Desabilitados")
      end
    end, { desc = "Toggle Diagnostics (Warnings)" })
  end,
}
