 return {
  "nvim-tree/nvim-tree.lua",
  dependencies = {
    'nvim-tree/nvim-web-devicons',
  },
  config = function()
    require("nvim-tree").setup({
       update_cwd = true,
       git = {
          enable = true,
          ignore = true,
          timeout = 500,
        },
     })
    local api = require "nvim-tree.api"
    -- 標準ファイラを無効にする
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    -- showing the tree of my current buffer from where i open up nvim-tree
    vim.g.nvim_tree_respect_buf_cwd = 1
    -- nvim-treeを最初から開く
    -- api.tree.toggle(false, true)
    -- トグルのキーマップ
    vim.keymap.set("n", "<C-n>", api.tree.toggle)
  end,
}
