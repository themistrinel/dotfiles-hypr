return {
  "Exafunction/codeium.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("codeium").setup({
      enable_chat = true,
      virtual_text = {
        enabled = true,
        key_bindings = {
          accept = "<C-g>", -- Atalho para aceitar a sugestão cinza
          next = "<M-]>",
          prev = "<M-[>",
        }
      }
    })
  end,
}
