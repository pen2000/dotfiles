local function open_in_existing_buffer()
  local lib = require("diffview.lib")
  local view = lib.get_current_view()
  if not view then
    return
  end

  local entry = view.cur_entry
  if not entry or not entry.path then
    return
  end

  local file = vim.fn.fnamemodify(entry.path, ":p")

  local current_tab = vim.api.nvim_get_current_tabpage()

  local target_buf = nil
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(bufnr) then
      if vim.api.nvim_buf_get_name(bufnr) == file then
        target_buf = bufnr
        break
      end
    end
  end

  local tabs = vim.api.nvim_list_tabpages()
  local target_tab = nil

  for i = #tabs, 1, -1 do
    local tab = tabs[i]
    if tab ~= current_tab then
      local wins = vim.api.nvim_tabpage_list_wins(tab)
      local is_diffview = false

      for _, win in ipairs(wins) do
        local buf = vim.api.nvim_win_get_buf(win)
        local ft = vim.api.nvim_buf_get_option(buf, "filetype")
        if ft == "DiffviewFiles" or ft == "DiffviewFilePanel" then
          is_diffview = true
          break
        end
      end

      if not is_diffview then
        target_tab = tab
        break
      end
    end
  end

  if not target_tab then
    vim.cmd("tabnew")
    target_tab = vim.api.nvim_get_current_tabpage()
  else
    vim.api.nvim_set_current_tabpage(target_tab)
  end

  if target_buf then
    vim.api.nvim_set_current_buf(target_buf)
  else
    vim.cmd("edit " .. vim.fn.fnameescape(file))
  end

  vim.api.nvim_set_current_tabpage(current_tab)
end

local function get_default_branch()
  local remotes = { "origin", "upstream" }

  for _, remote in ipairs(remotes) do
    local cmd = "git symbolic-ref refs/remotes/" .. remote .. "/HEAD 2>/dev/null"
    local handle = io.popen(cmd)
    if handle then
      local result = handle:read("*a")
      handle:close()

      if result then
        result = result:gsub("%s+$", "")
      end

      local branch = result:match("refs/remotes/" .. remote .. "/(.+)")
      if branch then
        return remote .. "/" .. branch
      end
    end
  end

  return "origin/main"
end

return {
  {
    "sindrets/diffview.nvim",

    cmd = {
      "DiffviewOpen",
      "DiffviewClose",
      "DiffviewFileHistory",
    },

    keys = {
      {
        "<leader>gm",
        function()
          local dv = require("diffview")
          local lib = require("diffview.lib")

          if next(lib.views) ~= nil then
            dv.close()
            return
          end

          local base = get_default_branch()
          dv.open({ base .. "...HEAD" })
        end,
        desc = "Diff: default branch vs HEAD",
      },
    },

    opts = {
      enhanced_diff_hl = true,

      view = {
        default = {
          layout = "diff2_horizontal",
        },
      },

      file_panel = {
        win_config = {
          width = 40,
        },
      },

      keymaps = {
        view = {
          { "n", "go", open_in_existing_buffer, { desc = "Open file in existing buffer (other tab)" } },
        },
        file_panel = {
          { "n", "go", open_in_existing_buffer, { desc = "Open file in existing buffer (other tab)" } },
        },
      },

      hooks = {
        diff_buf_win_enter = function()
          vim.opt_local.foldenable = false
        end,
      },
    },
  },
}
