-- Configuração de Formatação Automática
return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local conform = require("conform")

    conform.setup({
      formatters_by_ft = {
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
        lua = { "stylua" },
        python = { "isort", "black" },
        cpp = { "clang-format" },
        c = { "clang-format" },
      },
      format_on_save = function(bufnr)
        -- Desativar format_on_save se a variável global estiver setada
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        return {
          lsp_fallback = true,
          async = false,
          timeout_ms = 1000,
        }
      end,
      formatters = {
        black = {
          prepend_args = { "--line-length", "120" },
        },
        prettier = {
          prepend_args = { "--print-width", "120" },
        },
        stylua = {
          prepend_args = { "--column-width", "120" },
        },
        ["clang-format"] = {
          prepend_args = { "--style={BasedOnStyle: llvm, ColumnLimit: 120}" },
        },
      },
    })

    -- Comandos para ativar/desativar formatação globalmente ou localmente
    vim.api.nvim_create_user_command("FormatDisable", function(args)
      if args.bang then
        -- FormatDisable! desativa apenas para este buffer
        vim.b.disable_autoformat = true
      else
        vim.g.disable_autoformat = true
      end
    end, {
      desc = "Desativar autoformatar ao salvar",
      bang = true,
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
      vim.b.disable_autoformat = false
      vim.g.disable_autoformat = false
    end, {
      desc = "Reativar autoformatar ao salvar",
    })

    -- Atalho para formatar manualmente
    vim.keymap.set({ "n", "v" }, "<leader>cf", function()
      conform.format({
        lsp_fallback = true,
        async = false,
        timeout_ms = 1000,
      })
    end, { desc = "Format file or range (Code Format)" })
    
    -- Atalho para alternar autoformat
    vim.keymap.set("n", "<leader>uf", function()
      if vim.g.disable_autoformat then
        vim.cmd("FormatEnable")
        print("Autoformat Habilitado")
      else
        vim.cmd("FormatDisable")
        print("Autoformat Desabilitado")
      end
    end, { desc = "Toggle Autoformat on Save" })
  end,
}
