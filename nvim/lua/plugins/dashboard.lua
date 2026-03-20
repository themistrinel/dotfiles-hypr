-- Dashboard
return {
  "goolord/alpha-nvim",
  event = "VimEnter",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  config = function()
    local alpha = require("alpha")
    local dashboard = require("alpha.themes.dashboard")

    -- ASCII Art Customizada: "The Mistrinel"
    dashboard.section.header.val = {
      [[                                                              ]],
      [[  ███╗   ███╗██╗███████╗████████╗██████╗ ██╗███╗   ██╗███████╗██╗     ]],
      [[  ████╗ ████║██║██╔════╝╚══██╔══╝██╔══██╗██║████╗  ██║██╔════╝██║     ]],
      [[  ██╔████╔██║██║███████╗   ██║   ██████╔╝██║██╔██╗ ██║█████╗  ██║     ]],
      [[  ██║╚██╔╝██║██║╚════██║   ██║   ██╔══██╗██║██║╚██╗██║██╔══╝  ██║     ]],
      [[  ██║ ╚═╝ ██║██║███████║   ██║   ██║  ██║██║██║ ╚████║███████╗███████╗]],
      [[  ╚═╝     ╚═╝╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝]],
      [[                                                              ]],
      [[             --- ENGINEERING & PERFORMANCE SETUP ---          ]],
    }

    -- Botões de Menu (Integrados com Telescope)
    dashboard.section.buttons.val = {
      dashboard.button("f", "  Find File", ":Telescope find_files <CR>"),
      dashboard.button("r", "  Recent Files", ":Telescope oldfiles <CR>"),
      dashboard.button("n", "  New File", ":ene <BAR> startinsert <CR>"),
      dashboard.button("c", "  Configuration", ":e ~/.config/nvim/init.lua <CR>"),
      dashboard.button("q", "󰈆  Quit", ":qa<CR>"),
    }

    -- Rodapé Estilizado
    dashboard.section.footer.val = "C++ is high performance energy."

    -- Estilização de Cores (Mocha/Catppuccin)
    dashboard.section.header.opts.hl = "AlphaHeader"
    dashboard.section.buttons.opts.hl = "AlphaButtons"
    dashboard.section.footer.opts.hl = "AlphaFooter"

    alpha.setup(dashboard.config)

    -- Aplicar cores se o tema suportar
    vim.cmd([[
      highlight AlphaHeader guifg=#89b4fa
      highlight AlphaButtons guifg=#cdd6f4
      highlight AlphaFooter guifg=#fab387
    ]])
  end,
}
