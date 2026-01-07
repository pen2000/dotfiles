-- Put this at the top of 'init.lua'
local path_package = vim.fn.stdpath('data') .. '/site'
local mini_path = path_package .. '/pack/deps/start/mini.nvim'
if not vim.loop.fs_stat(mini_path) then
  vim.cmd('echo "Installing `mini.nvim`" | redraw')
  local clone_cmd = {
    'git', 'clone', '--filter=blob:none',
    'https://github.com/nvim-mini/mini.nvim', mini_path
  }
  vim.fn.system(clone_cmd)
  vim.cmd('packadd mini.nvim | helptags ALL')
  vim.cmd('echo "Installed `mini.nvim`" | redraw')
end

-- Set up 'mini.deps' (customize to your liking)
require('mini.deps').setup({ path = { package = path_package } })

-- Use 'mini.deps'. `now()` and `later()` are helpers for a safe two-stage
-- startup and are optional.
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later


-- Safely execute immediately
now(function()
  require('mini.basics').setup()
end)

now(function()
  vim.o.termguicolors = true
  vim.cmd('colorscheme miniwinter')
end)

now(function()
  require('mini.notify').setup()
end)

now(function()
  require('mini.icons').setup()
end)

now(function()
  require('mini.tabline').setup()
end)

now(function()
  require('mini.statusline').setup()
end)

now(function()
  require('mini.indentscope').setup()
end)

now(function()
  require('mini.completion').setup()
end)

now(function()
  require('mini.misc').setup()
end)

now(function()
  require('mini.files').setup()
  vim.keymap.set('n', '<Leader>e', MiniFiles.open, { desc = 'Open file exproler' })
end)


-- Safely execute later
later(function()
  require('mini.ai').setup()
end)

later(function()
  require('mini.comment').setup()
end)

later(function()
  require('mini.surround').setup()
end)

later(function()
  require('mini.notify').setup()
end)

later(function()
  require('mini.bracketed').setup()
end)

later(function()
  require('mini.cursorword').setup()
end)

later(function()
  require('mini.diff').setup()
end)

later(function()
  require('mini.trailspace').setup()
end)

later(function()
  require('mini.pairs').setup()
end)

later(function()
  require('mini.bufremove').setup()
end)

later(function()
  require('mini.splitjoin').setup({
    mappings = {
      toggle = 'gS',
      split = 'ss',
      join = 'sj',
    },
  })
end)

later(function()
  add('https://github.com/vim-jp/vimdoc-ja')
  -- Prefer Japanese as the help language
  vim.opt.helplang:prepend('ja')
end)

later(function()
  add({
    source = 'nvim-telescope/telescope.nvim',
    checkout = 'v0.1.9',
    depends = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'nvim-treesitter/nvim-treesitter'
    }
  })

  add({
    source = 'nvim-telescope/telescope-frecency.nvim',
    checkout = '^0.9.0'
  })

  require('telescope').load_extension 'frecency'
  require('telescope').setup()

  local builtin = require('telescope.builtin')
  vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = 'Find files' })
  vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = 'Grep files' })
  vim.keymap.set('n', '<leader>fs', builtin.grep_string, { desc = 'Grep by select string' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
  vim.keymap.set('n', '<leader>h', require('telescope').extensions.frecency.frecency, { desc = 'List histories' })
  vim.keymap.set('n', '<leader>gs', builtin.git_status, { desc = 'List git status' })
end)

later(function()
  add('sindrets/diffview.nvim')
  vim.keymap.set('n', '<leader>gd', '<cmd>DiffviewOpen<CR>', { desc = 'Open Diffview' })
  vim.keymap.set('n', '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', { desc = 'Open Current History' })
  vim.keymap.set('n', '<leader>gH', '<cmd>DiffviewFileHistory<CR>', { desc = 'Open All History' })
end)

later(function()
  add('lewis6991/gitsigns.nvim')
  require('gitsigns').setup({
    on_attach = function(bufnr)
      local gitsigns = require('gitsigns')

      local function map(mode, l, r, opts)
        opts = opts or {}
        opts.buffer = bufnr
        vim.keymap.set(mode, l, r, opts)
      end

      -- Toggles
      map('n', '<leader>tb', gitsigns.toggle_current_line_blame, { desc = 'Toggle current line blame' })
      map('n', '<leader>tw', gitsigns.toggle_word_diff, { desc = 'Toggle word diff' })

      -- Text object
      map({'o', 'x'}, 'ih', gitsigns.select_hunk, { desc = 'Select hunk'})
    end
  })
end)

later(function()
  local function mode_nx(keys)
    return { mode = 'n', keys = keys }, { mode = 'x', keys = keys }
  end
  local clue = require('mini.clue')
  clue.setup({
    window = {
      delay = 800
    },
    triggers = {
      -- Leader triggers
      mode_nx('<leader>'),

      -- Built-in completion
      { mode = 'i', keys = '<c-x>' },

      -- `g` key
      mode_nx('g'),

      -- Marks
      mode_nx("'"),
      mode_nx('`'),

      -- Registers
      mode_nx('"'),
      { mode = 'i', keys = '<c-r>' },
      { mode = 'c', keys = '<c-r>' },

      -- Window commands
      { mode = 'n', keys = '<c-w>' },

      -- bracketed commands
      { mode = 'n', keys = '[' },
      { mode = 'n', keys = ']' },

      -- `z` key
      mode_nx('z'),

      -- surround
      mode_nx('s'),

      -- text object
      { mode = 'x', keys = 'i' },
      { mode = 'x', keys = 'a' },
      { mode = 'o', keys = 'i' },
      { mode = 'o', keys = 'a' },

      -- option toggle (mini.basics)
      { mode = 'n', keys = 'm' },
    },

    clues = {
      -- Enhance this by adding descriptions for <Leader> mapping groups
      clue.gen_clues.builtin_completion(),
      clue.gen_clues.g(),
      clue.gen_clues.marks(),
      clue.gen_clues.registers({ show_contents = true }),
      clue.gen_clues.windows({ submode_resize = true, submode_move = true }),
      clue.gen_clues.z(),
    },
  })
end)

