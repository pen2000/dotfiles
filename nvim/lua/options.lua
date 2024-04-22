-- vim.opt対象を記述
local options = {
  -- 文字コード関連
  encoding = "utf-8",
  fileencoding = "utf-8",
  -- デザイン崩れ防止
  ambiwidth = 'single',
  title = true,
  backup = false,
  completeopt = { "menuone", "noselect" },
  conceallevel = 0,
  hlsearch = true,
  ignorecase = true,
  mouse = "a",
  smartcase = true,
  smartindent = true,
  swapfile = false,
  termguicolors = true,
  undofile = true,
  writebackup = false,
  -- タブ関連
  expandtab = true,
  shiftwidth = 2,
  tabstop = 2,
  cursorline = true,
  number = true,
  relativenumber = false,
  signcolumn = "yes",
  wrap = true,
  winblend = 0,
  wildoptions = "pum",
  pumblend = 5,
  background = "dark",
  scrolloff = 8,
  sidescrolloff = 8,
  splitbelow = false, -- オンのとき、ウィンドウを横分割すると新しいウィンドウはカレントウィンドウの下に開かれる
  splitright = false, -- オンのとき、ウィンドウを縦分割すると新しいウィンドウはカレントウィンドウの右に開かれる
  -- 不可視文字可視化
  list = true,
  listchars = { tab = '>>', trail = '_', nbsp = '+' },
}

for k, v in pairs(options) do
  vim.opt[k] = v
end

