-- mini.indentscope: Destaca visualmente o escopo de indentação atual
return {
	"echasnovski/mini.indentscope",
	version = false, -- Usa a branch master para as últimas atualizações
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		require("mini.indentscope").setup({
			draw = {
				delay = 100,
				animation = function(s, n)
					return 20
				end, -- 20ms entre cada passo da animação
				predicate = function(scope)
					return not scope.body.is_incomplete
				end,
				priority = 2,
			},
			mappings = {
				object_scope = "ii",
				object_scope_with_border = "ai",
				goto_top = "[i",
				goto_bottom = "]i",
			},
			options = {
				border = "both",
				indent_at_cursor = true,
				n_lines = 10000,
				try_as_border = false,
			},
			symbol = "╎",
		})

		-- Cor personalizada para o escopo (Ciano Brilhante)
		vim.api.nvim_set_hl(0, "MiniIndentscopeSymbol", { fg = "#80ffea" })
	end,
}
