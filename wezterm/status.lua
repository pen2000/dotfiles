local wezterm = require 'wezterm'

-- Equivalent to POSIX basename(3)
-- Given "/foo/bar" returns "bar"
-- Given "c:\\foo\\bar" returns "bar"
local function basename(s)
  return string.gsub(s, "(.*[/\\])(.*)", "%2")
end

local function os_icon(triple)
  if triple == 'x86_64-pc-windows-msvc' then
    return wezterm.nerdfonts.md_microsoft_windows
  end
  if triple == 'x86_64-apple-darwin' then
    return wezterm.nerdfonts.md_apple
  end
  if triple == 'aarch64-apple-darwin' then
    return wezterm.nerdfonts.md_apple
  end
  if triple == 'x86_64-unknown-linux-gnu' then
    return wezterm.nerdfonts.md_linux
  end
  if triple == 'aarch64-unknown-linux-gnu' then
    return wezterm.nerdfonts.md_linux
  end
  return wezterm.nerdfonts.oct_question
end

-- Tab Customize
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  -- プロセスに合わせてアイコン表示
  local nerd_icons = {
    nvim = wezterm.nerdfonts.custom_vim,
    vim = wezterm.nerdfonts.custom_vim,
    bash = wezterm.nerdfonts.dev_terminal,
    zsh = wezterm.nerdfonts.dev_terminal,
    ssh = wezterm.nerdfonts.md_server,
    top = wezterm.nerdfonts.md_monitor,
    docker = wezterm.nerdfonts.dev_docker,
    node = wezterm.nerdfonts.dev_nodejs_small,
    less = wezterm.nerdfonts.dev_less,
    ruby = wezterm.nerdfonts.dev_ruby,
    python = wezterm.nerdfonts.dev_python,
  }
  local zoomed = ""
  if tab.active_pane.is_zoomed then
    zoomed = "[Z] "
  end
  local pane = tab.active_pane
  local process_name = basename(pane.foreground_process_name)
  local icon = nerd_icons[process_name]
  local index = tab.tab_index + 1
  local cwd = basename(pane.current_working_dir.path)

  -- 例) 1:project_dir | zsh
  local title = index .. ": " .. cwd .. "  | " .. process_name
  if icon ~= nil then
    title = icon .. "  " .. zoomed .. title
  end
  return {
    { Text = " " .. title .. " " },
  }
end)

-- Right Status Customize
wezterm.on('update-right-status', function(window, pane)
  -- Each element holds the text for a cell in a "powerline" style << fade
  local cells = {}

  -- Figure out the cwd and host of the current pane.
  -- This will pick up the hostname for the remote host if your
  -- shell is using OSC 7 on the remote host.
  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local cwd = ''
    local hostname = ''

    if type(cwd_uri) == 'userdata' then
      -- Running on a newer version of wezterm and we have
      -- a URL object here, making this simple!

      cwd = cwd_uri.file_path
      hostname = cwd_uri.host or wezterm.hostname()
    else
      -- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
      -- which doesn't have the Url object
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find '/'
      if slash then
        hostname = cwd_uri:sub(1, slash - 1)
        -- and extract the cwd from the uri, decoding %-encoding
        cwd = cwd_uri:sub(slash):gsub('%%(%x%x)', function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    -- Remove the domain name portion of the hostname
    local dot = hostname:find '[.]'
    if dot then
      hostname = hostname:sub(1, dot - 1)
    end
    if hostname == '' then
      hostname = wezterm.hostname()
    end

    table.insert(cells, wezterm.nerdfonts.md_folder_open .. ' ' .. cwd)
    table.insert(cells, wezterm.nerdfonts.md_desktop_mac .. ' ' .. hostname)
  end

  local date = wezterm.strftime '%a %b %-d'
  table.insert(cells, wezterm.nerdfonts.md_calendar_month .. ' ' .. date)

  local time = wezterm.strftime '%H:%M:%S'
  table.insert(cells, wezterm.nerdfonts.md_clock .. ' ' .. time)

  local os_icon = os_icon(wezterm.target_triple)
  table.insert(cells, os_icon .. '  ')

  -- The powerline < symbol
  local LEFT_ARROW = utf8.char(0xe0b3)
  -- The filled in variant of the < symbol
  -- local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
  local SOLID_LEFT_ARROW = ' '

  -- Color palette for the backgrounds of each cell
  local colors = {
    '#1d2b38',
    '#2b4055',
    '#385572',
    '#476a8d',
    '#5580aa',
  }

  -- Foreground color for the text across the fade
  local text_fg = '#c0c0c0'

  -- The elements to be formatted
  local elements = {}
  -- How many cells have been formatted
  local num_cells = 0

  -- Translate a cell into elements
  function push(text, is_last)
    local cell_no = num_cells + 1
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = text .. ' ' })
    if not is_last then
      table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
      table.insert(elements, { Text = SOLID_LEFT_ARROW })
    end
    num_cells = num_cells + 1
  end

  table.insert(elements, { Foreground = { Color = colors[1] } })
  table.insert(elements, { Text = SOLID_LEFT_ARROW })
  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  window:set_right_status(wezterm.format(elements))
end)

