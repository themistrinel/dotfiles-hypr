-- outline.nvim: Uma árvore de símbolos (funções, variáveis, classes) na lateral
return {
  "hedyhli/outline.nvim",
  config = function()
    require("outline").setup({
      outline_window = {
        position = 'right',
        width = 25,
      },
      symbols = {
        filter = nil, -- Mostrar tudo que o LSP detectar
      },
    })

    -- Atalho com Leader para o Which-Key
    vim.keymap.set("n", "<leader>o", "<cmd>Outline<CR>", { desc = "Toggle Code Outline" })
  end,
}
