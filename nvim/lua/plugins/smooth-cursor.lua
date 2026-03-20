-- SmoothCursor: Adiciona um cursor suave que segue o cursor principal
-- Ideal para rastrear o movimento em pulos grandes
return {
  "gen740/SmoothCursor.nvim",
  event = "VeryLazy",
  config = function()
    require("smoothcursor").setup({
      autostart = true,
      cursor = "➤",              -- Caractere que segue o cursor
      texthl = "SmoothCursor",   -- Grupo de destaque
      linehl = nil,              -- Highlight da linha inteira (opcional)
      type = "default",          -- "default", "exp", "matrix"
      fancy = {
        enable = true,           -- Ativa modo "chique" com rastro de caracteres
        head = { cursor = "▷", texthl = "SmoothCursor", linehl = nil },
        body = {
          { cursor = "·", texthl = "SmoothCursorRed" },
          { cursor = "·", texthl = "SmoothCursorOrange" },
          { cursor = "·", texthl = "SmoothCursorYellow" },
          { cursor = "·", texthl = "SmoothCursorGreen" },
          { cursor = "·", texthl = "SmoothCursorAqua" },
          { cursor = "·", texthl = "SmoothCursorBlue" },
          { cursor = "·", texthl = "SmoothCursorPurple" },
        },
        tail = { cursor = nil, texthl = "SmoothCursor" },
      },
      speed = 25,                -- Velocidade (ms)
      intervals = 35,            -- Intervalo de atualização
      priority = 10,
      timeoutcall = 100,         -- Tempo para parar após o movimento
      threshold = 3,             -- Distância mínima para a animação começar
      disable_float_win = true,  -- Desativa em janelas flutuantes
      enabled_filetypes = nil,
      disabled_filetypes = nil,
    })

    -- Cores para o rastro (fading effect)
    vim.api.nvim_set_hl(0, "SmoothCursor", { fg = "#7aa2f7" })
    vim.api.nvim_set_hl(0, "SmoothCursorRed", { fg = "#f7768e" })
    vim.api.nvim_set_hl(0, "SmoothCursorOrange", { fg = "#ff9e64" })
    vim.api.nvim_set_hl(0, "SmoothCursorYellow", { fg = "#e0af68" })
    vim.api.nvim_set_hl(0, "SmoothCursorGreen", { fg = "#9ece6a" })
    vim.api.nvim_set_hl(0, "SmoothCursorAqua", { fg = "#73daca" })
    vim.api.nvim_set_hl(0, "SmoothCursorBlue", { fg = "#7aa2f7" })
    vim.api.nvim_set_hl(0, "SmoothCursorPurple", { fg = "#bb9af7" })
  end,
}
