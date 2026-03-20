-- nvim-autopairs: Fecha automaticamente parênteses, chaves e aspas
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  opts = {
    check_ts = true, -- Usa Treesitter para ser mais inteligente
    ts_config = {
      lua = { "string" }, -- Não adicionar pares em strings de Lua
      javascript = { "template_string" },
    },
  },
  config = function(_, opts)
    require("nvim-autopairs").setup(opts)

    -- Integrar com o nvim-cmp para fechar funções automaticamente
    local cmp_autopairs = require("nvim-autopairs.completion.cmp")
    local cmp = require("cmp")
    cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
  end,
}
