-- Debug Adapter Protocol (DAP)
-- O ecossistema de debug no Neovim requer alguns plugins trabalhando em conjunto
return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "rcarriga/nvim-dap-ui", -- Interface visual (Watch, Stacks, Breakpoints)
      "nvim-neotest/nvim-nio", -- Dependência obrigatória para as versões novas do dap-ui
      "williamboman/mason.nvim",
      "jay-babu/mason-nvim-dap.nvim", -- Instalação automática do codelldb
      "theHamsta/nvim-dap-virtual-text", -- Mostra valores das variáveis ao lado do código
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb" },
        automatic_installation = true,
      })

      require("nvim-dap-virtual-text").setup({})

      dapui.setup({
        icons = { expanded = "▾", collapsed = "▸", current_frame = "▸" },
        mappings = {
          -- Use a table to apply multiple mappings
          expand = { "<CR>", "<2-LeftMouse>" },
          open = "o",
          remove = "d",
          edit = "e",
          repl = "r",
          toggle = "t",
        },
      })

      -- Ícones bonitos para breakpoints
      vim.fn.sign_define("DapBreakpoint", { text = "🔴", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "🔍", texthl = "DapBreakpoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapLogPoint", { text = "📝", texthl = "DapLogPoint", linehl = "", numhl = "" })
      vim.fn.sign_define("DapStopped", { text = "➡️", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" })

      -- Abrir/Fechar UI do Debug automaticamente ao iniciar/parar
      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      -- Comentado para evitar que a UI feche rápido demais se o programa terminar rápido
      -- dap.listeners.before.event_terminated["dapui_config"] = function()
      --   dapui.close()
      -- end
      -- dap.listeners.before.event_exited["dapui_config"] = function()
      --   dapui.close()
      -- end

      -- Atalhos de Debug (Padrão F-keys)
      vim.keymap.set("n", "<F5>", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Debug: Step Out" })

      -- Atalhos de Debug (Leader d)
      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Debug: Toggle Breakpoint" })
      vim.keymap.set("n", "<leader>dB", function()
        dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
      end, { desc = "Debug: Set Breakpoint with Condition" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Debug: Start/Continue" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Debug: Step Into" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Debug: Step Over" })
      vim.keymap.set("n", "<leader>du", dap.step_out, { desc = "Debug: Step Out" })
      vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Debug: Terminate" })
      vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Debug: Open REPL" })
      vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Debug: Run Last" })
      vim.keymap.set("n", "<leader>dui", dapui.toggle, { desc = "Debug: Toggle UI" })

      -- Configuração específica para C++ / C / Rust (codelldb)
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          -- O Mason instala em ~/.local/share/nvim/mason/bin/codelldb
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      local common_config = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      dap.configurations.cpp = common_config
      dap.configurations.c = common_config
      dap.configurations.rust = common_config
    end,
  },
}
