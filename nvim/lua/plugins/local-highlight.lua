-- local-highlight.nvim: Destaca automaticamente outras ocorrências da palavra sob o cursor
-- Muito útil para ver onde uma variável está sendo usada sem precisar buscar.
return {
  "tzachar/local-highlight.nvim",
  config = function()
    require("local-highlight").setup({
      -- file_types = { 'python', 'cpp', 'lua' }, -- Se quiser limitar a certas linguagens
      disable_filenames = { "NvimTree", "Outline" },
      hlgroup = "Visual", -- Usa o destaque do modo visual (discreto e elegante)
      cw_hlgroup = nil,   -- Não destaca a palavra atual, apenas as outras instâncias
    })
  end,
}
