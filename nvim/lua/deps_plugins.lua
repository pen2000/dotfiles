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
  require('mini.pick').setup({
    mappings = {
      move_down = "<C-j>",
      move_up   = "<C-k>",
    },
  })

  vim.ui.select = MiniPick.ui_select

  vim.keymap.set('n', '<leader>f', MiniPick.builtin.files, {
    desc = 'Find files',
  })

  vim.keymap.set('n', '<leader>g', function()
    MiniPick.builtin.files({ tool = 'git' })
  end, { desc = 'Pick from git' })

  vim.keymap.set('n', '<leader>b', function()
    local wipeout_cur = function()
      vim.api.nvim_buf_delete(MiniPick.get_picker_matches().current.bufnr, {})
    end
    local buffer_mappings = { wipeout = { char = '<c-d>', func = wipeout_cur } }
    MiniPick.builtin.buffers({ include_current = false }, { mappings = buffer_mappings })
  end, { desc = 'Pick from buffers' })

  require('mini.visits').setup()
  vim.keymap.set('n', '<leader>l', function()
    require('mini.extra').pickers.visit_paths()
  end, { desc = 'Pick from histories' })
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
  add('kevinhwang91/nvim-bqf')
end)

later(function()
  add('sindrets/diffview.nvim')
  vim.keymap.set('n', '<leader>dd', '<cmd>DiffviewOpen<CR>', { desc = 'Open Diffview' })
  vim.keymap.set('n', '<leader>dh', '<cmd>DiffviewFileHistory<CR>', { desc = 'Open FileHistory' })
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

      -- Actions
      map('n', '<leader>hs', gitsigns.stage_hunk, { desc = 'Stage hunk' })
      map('n', '<leader>hr', gitsigns.reset_hunk, { desc = 'Reset hunk' })

      map('v', '<leader>hs', function()
        gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end, { desc = 'Stage hunk' })

      map('v', '<leader>hr', function()
        gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
      end)

      map('n', '<leader>hS', gitsigns.stage_buffer, { desc = 'Stage buffer' })
      map('n', '<leader>hR', gitsigns.reset_buffer, { desc = 'Reset buffer' })
      map('n', '<leader>hp', gitsigns.preview_hunk, { desc = 'Preview hunk' })
      map('n', '<leader>hi', gitsigns.preview_hunk_inline, { desc = 'Preview hunk inline' })

      map('n', '<leader>hb', function()
        gitsigns.blame_line({ full = true })
      end, { desc = 'Blame line' })

      map('n', '<leader>hd', gitsigns.diffthis, { desc = 'Diff from index' })

      map('n', '<leader>hD', function()
        gitsigns.diffthis('~')
      end, { desc = 'Diff from parent '})

      map('n', '<leader>hQ', function() gitsigns.setqflist('all') end, { desc = 'Quickfix from all' })
      map('n', '<leader>hq', gitsigns.setqflist, { desc = 'Quickfix from current ' })

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

