-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- ターミナルモード脱出
vim.keymap.set("t", "<C-q>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- カーソル下の単語でファイル名検索
vim.keymap.set("n", "<leader>fw", function()
  local word = vim.fn.expand("<cword>")
  Snacks.picker.files({ pattern = word })
end, { desc = "Find files (cursor word)" })
