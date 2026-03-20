-- Smear Cursor: Efeito de rastro no cursor para melhor feedback visual
return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    -- Velocidade e suavidade da animação (0 a 1)
    -- Valores menores = rastro mais longo e fluido
    stiffness = 0.6,               -- Rigidez da mola (padrão ~0.6)
    trailing_stiffness = 0.3,      -- Rigidez do rastro (padrão ~0.3)
    distance_stop_animating = 0.1, -- Distância mínima para parar (padrão 0.1)

    -- Cor do cursor (seguindo a paleta do Tokyo Night para um visual premium)
    cursor_color = "#7aa2f7", -- Azul vibrante do Tokyo Night

    -- Configurações visuais adicionais
    hide_target_hack = false, -- Se true, esconde o cursor real do sistema
    gamma = 1.0,              -- Correção de brilho do rastro
    
    -- Desativar em arquivos muito grandes para manter performance
    max_kept_files = 10,
  },
}
