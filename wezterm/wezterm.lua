require 'status'
-- require 'event'

-- Pull in the wezterm API
local wezterm = require 'wezterm'

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.automatically_reload_config = true

-- scroll backline
config.scrollback_lines = 10000

-- ime
config.use_ime = true

-- exit
config.exit_behavior = 'CloseOnCleanExit'

-- colors
config.color_scheme = 'nord'

-- window
config.initial_cols = 150
config.initial_rows = 40
config.window_background_opacity = 0.88
config.macos_window_background_blur = 34
-- config.window_decorations = "RESIZE"

-- local mux = wezterm.mux
-- wezterm.on("gui-startup", function()
--   local tab, pane, window = mux.spawn_window(cmd or {})
--   window:gui_window():maximize()
-- end)

-- font
config.font = wezterm.font_with_fallback({
  { family = "Cica" },
  { family = "Cica", assume_emoji_presentation = true },
})
config.font_size = 14
config.window_frame = {
  font = wezterm.font { family ='Roboto', weight = 'Bold' },
  font_size = 11.0,
}

-- visual bell
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 105,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}
config.colors = {
  visual_bell = '#0A0A0A',
}

-- cursor
-- config.default_cursor_style = 'BlinkingBlock'
-- config.cursor_blink_rate = 800

-- key bindings
config.keys = {
  {
    key = 'd',
    mods = 'CMD',
    action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'd',
    mods = 'SHIFT|CMD',
    action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
  },
  {
    key = 'w',
    mods = 'CMD',
    action = wezterm.action.CloseCurrentPane { confirm = true },
  },
  -- {
  --   key = 'b',
  --   mods = 'CMD',
  --   action = wezterm.action.EmitEvent 'show-title-bar',
  -- },
}

-- and finally, return the configuration to wezterm
return config
