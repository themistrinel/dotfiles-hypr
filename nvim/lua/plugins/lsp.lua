-- Configuração do LSP (Language Server Protocol)
return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",           -- Gerenciador de binários (LSP, DAP, Linters)
      "williamboman/mason-lspconfig.nvim", -- Ponte entre Mason e lspconfig
      "WhoIsSethDaniel/mason-tool-installer.nvim", -- Instalador automático para Linters e Formatters
      "hrsh7th/cmp-nvim-lsp",              -- Fonte para o autocompletar
      {
        "rachartier/tiny-inline-diagnostic.nvim",
        event = "VeryLazy",
        config = function()
          require("tiny-inline-diagnostic").setup()
        end,
      },
    },
    config = function()
      require("mason").setup()
      -- ... (mason configs)
      require("mason-lspconfig").setup({
        ensure_installed = { "clangd", "lua_ls" },
      })

      -- Configuração Visual de Diagnósticos (Ícones e Comportamento)
      vim.diagnostic.config({
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = " ",
            [vim.diagnostic.severity.WARN] = " ",
            [vim.diagnostic.severity.HINT] = " ",
            [vim.diagnostic.severity.INFO] = " ",
          },
        },
        virtual_text = false, -- Desativado pois usaremos o tiny-inline-diagnostic
        update_in_insert = false,
        underline = true,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
        },
      })

      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier",     -- Formatter para web
          "stylua",       -- Formatter para Lua
          "isort",        -- Formatter para Python
          "black",        -- Formatter para Python
          "clang-format", -- Formatter para C++/C
          "eslint_d",      -- Linter para JS/TS
          "cpplint",      -- Linter para C++
        },
      })

      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Neovim 0.11+ Native LSP Config
      -- Configuração do Clangd (C++)
      vim.lsp.config('clangd', {
        capabilities = capabilities,
        cmd = {
          "clangd",
          "--background-index",
          "--clang-tidy",
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          "--function-arg-placeholders",
          "--fallback-style=llvm", -- O conform agora cuida da formatação, mas deixamos aqui como backup
        },
      })
      vim.lsp.enable('clangd')

      -- Configuração do Lua LS
      vim.lsp.config('lua_ls', {
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = { globals = { 'vim' } }
          }
        }
      })
      vim.lsp.enable('lua_ls')

      -- Teclas de Navegação LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(ev)
          local opts = { buffer = ev.buf }
          
          -- Habilitar Inlay Hints (Textos nas linhas informando tipos e parâmetros)
          if vim.lsp.inlay_hint then
            vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
          end

          vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Go to Definition" })
          vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = ev.buf, desc = "Hover Docs" })
          vim.keymap.set("n", "gi", vim.lsp.buf.implementation, { buffer = ev.buf, desc = "Go to Implementation" })
          vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = ev.buf, desc = "Rename Symbol" })
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = ev.buf, desc = "Code Action" })
          vim.keymap.set("n", "gr", vim.lsp.buf.references, { buffer = ev.buf, desc = "Show References" })
          vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { buffer = ev.buf, desc = "Line Diagnostics" })
          
          -- Atalho para alternar Inlay Hints
          vim.keymap.set("n", "<leader>uh", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
          end, { buffer = ev.buf, desc = "Toggle Inlay Hints" })
        end,
      })
    end,
  },
}
