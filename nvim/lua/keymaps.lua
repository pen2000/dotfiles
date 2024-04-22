-- キーバインド

-- 定義元へジャンプ
vim.keymap.set('n', 'gd', '<Plug>(coc-definition)', {})

-- ウィンドウ移動を楽にするキーマップ
vim.keymap.set('n', '<A-j>', '<C-w>w')
vim.keymap.set('i', '<A-j>', '<Esc><C-w>w')
vim.keymap.set('t', '<A-j>', '<C-\\><C-n><C-w>w')

-- ターミナルモードからの離脱を楽にする
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>')
