-- Which-key: Ajuda a memorizar os atalhos e organiza o menu leader
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  init = function()
    vim.opt.timeout = true
    vim.opt.timeoutlen = 300
  end,
  opts = {
    -- Configurações padrão são ótimas
  },
  config = function(_, opts)
    local wk = require("which-key")
    wk.setup(opts)
    
    -- Registrar grupos para o leader
    -- Registrar grupos e atalhos individuais para o leader
    wk.add({
      { "<leader>f", group = "Find (Telescope)" },
      { "<leader>c", group = "Code/LSP" },
      { "<leader>d", group = "Debug/DAP" },
      { "<leader>g", group = "Git" },
      { "<leader>n", group = "No Highlight/New File" },
      { "<leader>t", group = "Terminal" },
      { "<leader>u", group = "UI/Toggle" },
      { "<leader>uf", desc = "Toggle Format" },
      { "<leader>ud", desc = "Toggle Diagnostics" },
      { "<leader>uh", desc = "Toggle Inlay Hints" },
      { "<leader>us", desc = "Toggle Spellcheck (PT/EN)" },
      { "<leader>o", desc = "Outline (Símbolos)" },
      { "<leader>e", desc = "Explorador de Arquivos (Oil)" },
      
      -- Novas categorias para iniciantes gravarem
      { "<leader>w", group = "Windows (Janelas)" },
      { "<leader>w", proxy = "<C-w>", group = "Windows (Janelas)" },
      { "<leader>b", group = "Buffers (Arquivos)" },
      { "<leader>l", group = "Lines (Mover Linhas)" },
      { "<leader>x", desc = "Close Current File" },
      { "<leader>q", desc = "Quit Neovim (Exit All)" },

      -- Guia de Programação Rápida (Atalhos de Alta Produtividade)
      { "<leader>h", group = "Guia Rápido: Atalhos de Velocidade" },
      { "<leader>hf", desc = "Format Code (<leader>cf)" },
      { "<leader>hl", desc = "Trigger Lint (<leader>cl)" },
      { "<leader>hr", desc = "Rename Symbol (<leader>cr)" },
      { "<leader>ha", desc = "Code Actions (<leader>ca)" },
      { "<leader>hd", desc = "Definitions (gd)" },
      { "<leader>hu", desc = "References (gr)" },
      { "<leader>hs", desc = "Save File (CTRL+S)" },
      { "<leader>hm", desc = "Move Lines (ALT+j/k)" },
      { "<leader>hj", desc = "Join/Delete (Visual dd)" },
      { "<leader>hc", desc = "Accept AI (CTRL+G)" },

      -- Tutorial de Vim interativo
      { "<leader>T", group = "󟐦 Vim Tutorial (Guia)", icon = "󰉖 " },
      
      -- Movimentação
      { "<leader>Tm", group = "󰆾 Movimentação" },
      { "<leader>Tmw", desc = "w: Próxima palavra" },
      { "<leader>Tmb", desc = "b: Palavra anterior" },
      { "<leader>Tme", desc = "e: Fim da palavra" },
      { "<leader>TM", group = "󰒭 Movimentação Avançada" },
      { "<leader>TMf", desc = "f{char}: Pula para o caractere" },
      { "<leader>TMt", desc = "t{char}: Pula antes do caractere" },
      { "<leader>TM%", desc = "%: Pula para o par (parentêses, etc)" },
      { "<leader>TMG", desc = "G: Fim do arquivo" },
      { "<leader>TMg", desc = "gg: Início do arquivo" },
      
      -- Edição
      { "<leader>Te", group = "󰏫 Edição Essencial" },
      { "<leader>Tei", desc = "i: Inserir (antes)" },
      { "<leader>Tea", desc = "a: Inserir (depois)" },
      { "<leader>Tec", desc = "c: Mudar (deleta e insere)" },
      { "<leader>Ted", desc = "d: Deletar" },
      { "<leader>Tey", desc = "y: Copiar (yank)" },
      { "<leader>Tep", desc = "p: Colar" },
      { "<leader>Teu", desc = "u: Desfazer (undo)" },
      { "<leader>Ter", desc = "<C-r>: Refazer (redo)" },
      
      -- Objetos de Texto
      { "<leader>To", group = "󰦨 Objetos de Texto (Vim Magic)" },
      { "<leader>Toi", group = "i (Inside...)" },
      { "<leader>Toiw", desc = "iw: Dentro da palavra" },
      { "<leader>Toi(", desc = "i(: Dentro de parênteses" },
      { "<leader>Toi\"", desc = "i\": Dentro de aspas" },
      { "<leader>Toit", desc = "it: Dentro de tag HTML" },
      { "<leader>Toa", group = "a (Around...)" },
      { "<leader>Toaw", desc = "aw: Palavra + espaço" },
      { "<leader>Toa(", desc = "a(: Parênteses + bordas" },
      
      -- Visual
      { "<leader>Tv", group = "󰒅 Modos Visuais" },
      { "<leader>Tvv", desc = "v: Seleção por caractere" },
      { "<leader>TvV", desc = "V: Seleção por linha" },
      { "<leader>Tvb", desc = "<C-v>: Seleção em bloco" },
      
      -- Macros & Registros
      { "<leader>Tr", group = "󰑋 Macros & Registros" },
      { "<leader>Trq", desc = "q{letra}: Gravar macro" },
      { "<leader>Tr@", desc = "@{letra}: Executar macro" },
      { "<leader>Tr\"", desc = "\"{letra}y: Copiar p/ registro específico" },
      
      -- Prática
      { "<leader>TT", desc = "󰛨 Iniciar VimTutor Oficial", icon = "󰉖 ", cmd = "<cmd>Tutor<cr>" },
    })
  end,
}
