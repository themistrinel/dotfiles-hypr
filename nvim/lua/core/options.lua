-- Configurações globais do editor
local opt = vim.opt

-- Números de linha (Híbrido)
-- Ajuda a pular linhas rapidamente (ex: 5j) sabendo a distância exata.
opt.relativenumber = true
opt.number = true

-- Indentação (Padrão Engenharia de Software)
opt.tabstop = 4         -- Tamanho visual do tab
opt.shiftwidth = 4      -- Tamanho da indentação automática
opt.expandtab = true    -- Transforma tabs em espaços (padrão C++)
opt.autoindent = true
opt.smartindent = true

-- Interface Visual
opt.termguicolors = true
opt.cursorline = true   -- Destaca a linha do cursor
opt.signcolumn = "yes"  -- Coluna para erros/diagnósticos fixa (evita saltos)
opt.scrolloff = 8       -- Mantém o cursor longe das bordas da tela
opt.mouse = "a"         -- Habilita mouse se necessário

-- Busca
opt.ignorecase = true   -- Ignora caixa na busca...
opt.smartcase = true    -- ...a menos que você use uma letra maiúscula

-- Performance e UX
opt.updatetime = 250    -- Atualização mais rápida de diagnósticos
opt.timeoutlen = 300    -- Tempo de espera para comandos de teclas
opt.completeopt = "menuone,noselect" -- Melhor experiência de autocompletar
opt.clipboard = "unnamedplus"       -- Integra com o CTRL+C/V do Sistema

-- Esconder mensagens e modo (Redundantes com Lualine/Noice)
opt.showmode = false    -- Não mostra "-- INSERT --" embaixo
opt.showcmd = false     -- Não mostra comandos parciais
opt.shortmess:append("cIAt") -- Reduz mensagens do prompt
opt.cmdheight = 0       -- REMOVE O ESPAÇO EM BAIXO (Comando só aparece quando você digita)

-- Ajustes de Popup (ajuda a caber acima da linha)
opt.pumheight = 10      -- Limita o menu de sugestões a 10 itens
opt.pumwidth = 20       -- Menu mais estreito

-- Suporte a Português e Inglês (Dicionários)
opt.spelllang = { "en", "pt" }
opt.spell = false -- Desativado por padrão, use <leader>us para ligar

-- Restaurar o formato do cursor (barra vertical) ao sair do Neovim
-- Isso evita que o cursor fique como um bloco no terminal após fechar o editor.
vim.cmd([[
  augroup RestoreCursorShapeOnExit
      autocmd!
      autocmd VimLeave * set guicursor=a:ver25
  augroup END
]])

