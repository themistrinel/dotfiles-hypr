-- Temas disponíveis: gruvbox (i3/retro) | catppuccin-mocha (hyprland)
-- Trocar: :lua ThemeToggle()  ou  leader+tt

local theme_file = vim.fn.stdpath("data") .. "/theme.txt"

local function read_theme()
  local f = io.open(theme_file, "r")
  if f then
    local t = f:read("*l")
    f:close()
    return t
  end
  return "catppuccin-mocha"
end

local function write_theme(name)
  local f = io.open(theme_file, "w")
  if f then f:write(name); f:close() end
end

function ThemeToggle()
  local current = vim.g.colors_name or ""
  local next = current:find("gruvbox") and "catppuccin-mocha" or "gruvbox"
  write_theme(next)
  vim.cmd.colorscheme(next)
  vim.notify("Tema: " .. next, vim.log.levels.INFO)
end

vim.keymap.set("n", "<leader>tt", ThemeToggle, { desc = "Toggle theme" })

return {
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    priority = 1000,
    opts = { contrast = "hard", transparent_mode = false },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = { flavour = "mocha" },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme(read_theme())
    end,
  },
}
