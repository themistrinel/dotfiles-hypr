-- Gitsigns: Integração visual com Git direto na lateral (gutter)
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    on_attach = function(bufnr)
      local gs = package.loaded.gitsigns

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Navegação entre "hunks"
      map("n", "]c", function()
        if vim.api.nvim_get_option_value("diff", {}) then return "]c" end
        vim.schedule(function() gs.next_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "Next Hunk" })

      map("n", "[c", function()
        if vim.api.nvim_get_option_value("diff", {}) then return "[c" end
        vim.schedule(function() gs.prev_hunk() end)
        return "<Ignore>"
      end, { expr = true, desc = "Prev Hunk" })

      -- Ações do Git
      map("n", "<leader>gs", gs.stage_hunk, { desc = "Stage Hunk" })
      map("n", "<leader>gr", gs.reset_hunk, { desc = "Reset Hunk" })
      map("n", "<leader>gp", gs.preview_hunk, { desc = "Preview Hunk" })
      map("n", "<leader>gb", function() gs.blame_line { full = true } end, { desc = "Blame Line" })
    end,
  },
}
