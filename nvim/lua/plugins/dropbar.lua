-- Dropbar: Barra de navegação (breadcrumbs) no topo
return {
  "Bekaboo/dropbar.nvim",
  dependencies = {
    "nvim-tree/nvim-web-devicons",
    "nvim-telescope/telescope-fzf-native.nvim",
  },
  config = function()
    require("dropbar").setup({
    })
  end,
}
