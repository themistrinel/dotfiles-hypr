-- todo-comments.nvim: Destaca e lista comentários de TODO, FIXME, BUG, etc.
return {
  "folke/todo-comments.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  opts = {
    -- Configurações padrão são excelentes
  },
  config = function(_, opts)
    require("todo-comments").setup(opts)

    -- Atalhos de navegação
    vim.keymap.set("n", "]t", function()
      require("todo-comments").jump_next()
    end, { desc = "Next todo comment" })

    vim.keymap.set("n", "[t", function()
      require("todo-comments").jump_prev()
    end, { desc = "Previous todo comment" })

    -- Integração com Telescope (Buscar todos os TODOs no projeto)
    vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find TODOs" })
  end,
}
