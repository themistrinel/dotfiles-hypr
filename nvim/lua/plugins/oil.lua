-- Oil.nvim: Edite o sistema de arquivos como se fosse um buffer de texto
return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    require("oil").setup({
      -- O Neovim abrirá o Oil automaticamente ao abrir um diretório
      default_file_explorer = true,
      columns = {
        "icon",
        -- "permissions",
        -- "size",
        -- "mtime",
      },
      view_options = {
        show_hidden = true, -- Mostrar arquivos ponto (.) por padrão
      },
    })

    -- Atalhos intuitivos para abrir o Oil
    vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Abrir explorador de arquivos (Oil)" })
    vim.keymap.set("n", "<leader>e", "<CMD>Oil<CR>", { desc = "Explorador de arquivos (Oil)" })
  end,
}
