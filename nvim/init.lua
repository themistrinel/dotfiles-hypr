-- Ponto de entrada da configuração de Neovim
-- Designer: Antigravity AI

-- Definir a tecla 'leader' antes de carregar os plugins
-- O espaço é a melhor opção para ergonomia no terminal.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Importar as configurações de sistema da pasta lua/core/
require("core.options")
require("core.keymaps")

-- Bootstrap do lazy.nvim (Gerenciador de Plugins)
-- Ele clona o lazy.nvim automaticamente se você abrir o nvim pela primeira vez.
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Carregar todos os plugins definidos em lua/plugins/*.lua
require("lazy").setup("plugins", {
  change_detection = {
    notify = false, -- Não notificar toda vez que mudar um arquivo de config
  },
})
