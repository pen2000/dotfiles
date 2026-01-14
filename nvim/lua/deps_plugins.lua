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
  require('mini.notify').setup({
    lsp_progress = { enable = false },
  })
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
  vim.keymap.set('n', '<leader>fg', builtin.git_files, { desc = 'Find git files' })
  vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = 'Find buffers' })
  vim.keymap.set('n', '<leader>fd', builtin.lsp_definitions, { desc = 'Find definitions' })
  vim.keymap.set('n', '<leader>fr', builtin.lsp_references, { desc = 'Find references' })
  vim.keymap.set('n', '<leader>fh', require('telescope').extensions.frecency.frecency, { desc = 'Find histories' })
  vim.keymap.set('n', '<leader>gf', builtin.live_grep, { desc = 'Grep files' })
  vim.keymap.set('n', '<leader>gs', builtin.grep_string, { desc = 'Grep by select string' })
  vim.keymap.set('n', '<leader>hs', builtin.git_status, { desc = 'Git status' })
end)

later(function()
  add('sindrets/diffview.nvim')
  vim.keymap.set('n', '<leader>hd', '<cmd>DiffviewOpen<CR>', { desc = 'Open Diffview' })
  vim.keymap.set('n', '<leader>hh', '<cmd>DiffviewFileHistory %<CR>', { desc = 'Open Current History' })
  vim.keymap.set('n', '<leader>hH', '<cmd>DiffviewFileHistory<CR>', { desc = 'Open All History' })
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

  add({source = 'tpope/vim-fugitive'})
  add({ source = 'tpope/vim-rhubarb' })
  vim.keymap.set('n', '<leader>ho', ':GBrowse<CR>', { desc = 'Open file on GitHub' })
  vim.keymap.set('v', '<leader>ho', ':GBrowse<CR>', { desc = 'Open selection on GitHub' })
end)

later(function ()
  add('https://github.com/y3owk1n/undo-glow.nvim')
  local undo_glow = require('undo-glow')
  undo_glow.setup()
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

later(function()
  add({
      source = 'neovim/nvim-lspconfig',
      checkout = 'v1.8.0',
      depends = {
          {
            source = 'williamboman/mason.nvim',
            checkout = 'v1.11.0'
          },
          {
            source = 'williamboman/mason-lspconfig.nvim',
            checkout = 'v1.32.0'
          }
      }
  })

  require('mason').setup()
  local lspconfig = require('lspconfig')
  local capabilities = vim.lsp.protocol.make_client_capabilities()
  capabilities.textDocument.foldingRange = {
    dynamicRegistration = false,
    lineFoldingOnly = true,
  }

  require('mason-lspconfig').setup {
    ensure_installed = {
      'lua_ls',
      'bashls',
      'html',
      'cssls',
      'jsonls',
      'ts_ls',
      'solargraph',
      'dockerls',
      'docker_compose_language_service',
      'marksman',
    },
  }

  require('mason-lspconfig').setup_handlers {
    function(server_name)
      lspconfig[server_name].setup {
        capabilities = capabilities,
      }
    end,
  }

  local opts = { noremap=true, silent=true }
  vim.keymap.set('n', '<space>ld', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, opts)
  vim.keymap.set('n', ']d', vim.diagnostic.goto_next, opts)

  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(args)
      vim.keymap.set("n", "<leader>lf", function()
        vim.lsp.buf.format({ async = true })       -- 非同期でフォーマットを実行
      end, { buffer = args.buf, desc = "Format Buffer" })
      vim.keymap.set("v", "<leader>lf", function()
        vim.lsp.buf.format()
      end, { buffer = args.buf, desc = "Format Selection" })
    end
  })
end)

