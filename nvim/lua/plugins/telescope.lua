-- O famoso Fuzzy Finder (Essencial para navegar em projetos grandes)
return {
  "nvim-telescope/telescope.nvim",
  -- Removida a branch 0.1.x para compatibilidade com Neovim 0.11 Nightly
  -- A master do telescope possui as correções de Treesitter necessárias.
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local builtin = require("telescope.builtin")
    vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Buscar arquivos" })
    vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Buscar texto (grep)" })
    vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Buscar buffers abertos" })
  end,
}
