-- Tokyo Night: Tema moderno e vibrante
return {
  "folke/tokyonight.nvim",
  lazy = false,
  priority = 1000,
  config = function()
    require("tokyonight").setup({
      style = "night", -- storm, moon, night, day
      transparent = false, -- background transparente
      terminal_colors = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    })
    vim.cmd.colorscheme("tokyonight")
  end,
}
