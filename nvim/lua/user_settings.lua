vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2

vim.keymap.set("n", "<leader>l", function()
  vim.cmd("nohlsearch")
end, { silent = true })

vim.opt.listchars = { tab = ">.", trail = "_", eol = "$" }
vim.opt.list = true

-- ウィンドウ移動を楽にするキーマップ
vim.keymap.set('n', '<A-j>', '<C-w>w')
vim.keymap.set('i', '<A-j>', '<Esc><C-w>w')
vim.keymap.set('t', '<A-j>', '<C-\\><C-n><C-w>w')
