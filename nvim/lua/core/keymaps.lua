-- Atalhos de teclado customizados
local keymap = vim.keymap

-- Navegação entre janelas (CTRL + h/j/k/l)
keymap.set("n", "<C-h>", "<C-w>h", { desc = "Janela à esquerda" })
keymap.set("n", "<C-j>", "<C-w>j", { desc = "Janela abaixo" })
keymap.set("n", "<C-k>", "<C-w>k", { desc = "Janela acima" })
keymap.set("n", "<C-l>", "<C-w>l", { desc = "Janela à direita" })

-- Sair do modo inserção com 'jk' (muito comum em setups profissionais)
keymap.set("i", "jk", "<ESC>", { desc = "Sair do modo inserção" })

-- Limpar destaques de busca com <leader>nh
keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Limpar busca" })

-- Comandos úteis para Terminal
keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Sair do modo terminal" })

-- Mover linhas (Alt + j/k ou Leader + l)
keymap.set("n", "<A-j>", ":m .+1<CR>==", { desc = "Mover linha para baixo" })
keymap.set("n", "<A-k>", ":m .-2<CR>==", { desc = "Mover linha para cima" })
keymap.set("n", "<leader>lj", ":m .+1<CR>==", { desc = "Mover linha para baixo" })
keymap.set("n", "<leader>lk", ":m .-2<CR>==", { desc = "Mover linha para cima" })

-- Buffers (Arquivos abertos)
keymap.set("n", "<S-l>", ":bnext<CR>", { desc = "Próximo arquivo" })
keymap.set("n", "<S-h>", ":bprevious<CR>", { desc = "Arquivo anterior" })
keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next Buffer" })
keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous Buffer" })
keymap.set("n", "<leader>x", ":bdelete<CR>", { desc = "Fechar arquivo atual" })

-- Janelas (Navegação fácil via Leader + w)
keymap.set("n", "<leader>wh", "<C-w>h", { desc = "Move to Left Window" })
keymap.set("n", "<leader>wj", "<C-w>j", { desc = "Move to Down Window" })
keymap.set("n", "<leader>wk", "<C-w>k", { desc = "Move to Up Window" })
keymap.set("n", "<leader>wl", "<C-w>l", { desc = "Move to Right Window" })
keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split Vertical" })
keymap.set("n", "<leader>ws", "<C-w>s", { desc = "Split Horizontal" })

-- Janelas (Resize com setas)
keymap.set("n", "<C-Up>", ":resize -2<CR>", { desc = "Diminuir altura" })
keymap.set("n", "<C-Down>", ":resize +2<CR>", { desc = "Aumentar altura" })
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Diminuir largura" })
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Aumentar largura" })

-- Salvar arquivo com CTRL+S e avisar
keymap.set({ "n", "i", "v" }, "<C-s>", function()
  vim.cmd("silent! w")
  vim.notify("Arquivo salvo!", vim.log.levels.INFO, { title = "Sistema" })
end, { desc = "Salvar arquivo" })

-- Sair do Neovim (<leader>q)
keymap.set("n", "<leader>q", ":qa<CR>", { desc = "Sair do Neovim (Sair de Tudo)" })

-- Run/Build simplificado (Assumindo que você tem um Makefile ou executa o compilado)
-- Para projetos complexos, você usará o Makefile no terminal.
keymap.set("n", "<leader>dr", ":!./build/main<CR>", { desc = "Run Output (./build/main)" })
