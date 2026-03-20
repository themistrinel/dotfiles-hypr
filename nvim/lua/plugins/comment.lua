-- Comment.nvim: Comentários rápidos com 'gcc' ou 'gc' em blocos
return {
  "numToStr/Comment.nvim",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    require("Comment").setup()

    -- Atalhos para comentar com Leader + /
    vim.keymap.set("n", "<leader>/", "gcc", { remap = true, desc = "Comentar linha" })
    vim.keymap.set("v", "<leader>/", "gc", { remap = true, desc = "Comentar seleção" })
  end,
}
