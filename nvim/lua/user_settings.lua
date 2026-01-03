vim.opt.expandtab = true
vim.opt.shiftround = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.tabstop = 2
vim.keymap.set("n", "<Esc><Esc>", function()
  vim.cmd("nohlsearch")
end, { silent = true })

