return {
  'akinsho/toggleterm.nvim',
  version = "*", 
  config = function()
    require("toggleterm").setup()
    local Terminal = require("toggleterm.terminal").Terminal

    -- lazygit
    local lazygit = Terminal:new({
      cmd = 'lazygit',
      direction = "float",
      hidden = true
    })
    function _lazygit_toggle()
      lazygit:toggle()
    end
    vim.keymap.set("n", "<leader>lg", "<cmd>lua _lazygit_toggle()<CR>", { noremap = true, silent = true })

    -- ターミナル
    local innerterminal = Terminal:new({
      direction = "float",
      hidden = true,
      on_open = function(term)
        vim.api.nvim_buf_set_keymap(term.bufnr, "t", ";t", "<CMD>close<CR>", { noremap = true, silent = true })
      end,
    })
    function _terminal_toggle()
      innerterminal:toggle()
    end
    vim.keymap.set("n", ";t", "<cmd>lua _terminal_toggle()<CR>", { noremap = true, silent = true })
  end,
}
