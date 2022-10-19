-- https://wezfurlong.org/wezterm/index.html
local wezterm = require "wezterm"
local action = wezterm.action

DEFAULT_DARK_THEME_NAME = "Multiplex Dark"
DEFAULT_LIGHT_THEME_NAME = "Multiplex Light"

if wezterm.gui.get_appearance():find "Light" then
    SYSTEM_THEME_NAME = DEFAULT_LIGHT_THEME_NAME
    INVERSE_SYSTEM_THEME_NAME = DEFAULT_DARK_THEME_NAME
else
    SYSTEM_THEME_NAME = DEFAULT_DARK_THEME_NAME
    INVERSE_SYSTEM_THEME_NAME = DEFAULT_LIGHT_THEME_NAME
end

THEMES = { SYSTEM_THEME_NAME, INVERSE_SYSTEM_THEME_NAME }

-- Cycle through the themes
wezterm.on(
    "switch-theme",
    function()
        local current_theme_index = wezterm.GLOBAL.current_theme_index or 1
        local next_theme_index = current_theme_index % #THEMES + 1
        wezterm.GLOBAL.current_theme_index = next_theme_index
        wezterm.reload_configuration()
    end
)

-- Get the current theme based on the current theme index in the global storage
local function get_current_theme()
    return THEMES[wezterm.GLOBAL.current_theme_index or 1]
end

local config = {
    font = wezterm.font("FiraCode Nerd Font", { weight = 500 }),
    font_size = 10,
    line_height = 1.0,
    default_cursor_style = "SteadyBar",
    check_for_updates = false,
    window_padding = {
        left = "1cell",
        right = "1cell",
        top = "0.5cell",
        bottom = "0.5cell"
    },
    initial_cols = 122,
    initial_rows = 35,
    use_resize_increments = true,

    use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_bar_at_bottom = true,

    color_scheme = get_current_theme(),
    enable_scroll_bar = false,
    default_cwd = ("%s/Desktop"):format(wezterm.home_dir),

    keys = {
        {
            key = "k",
            mods = "CMD",
            action = action.Multiple {
                action.ClearScrollback "ScrollbackAndViewport",
                action.SendKey { key = "l", mods = "CTRL" },
            },
        },
        {
            key = "s",
            mods = "CTRL|SHIFT",
            action = action.EmitEvent("switch-theme"),
        }
    }
}

-- Windows specific configurations
if wezterm.target_triple:find "windows%-msvc" then
    config.font = wezterm.font("FiraCode NF", { weight = 500 })
    config.default_prog = { "powershell.exe", "-NoLogo" }

    return config
end

-- Set Vim background color based on the current theme when the config is loaded
wezterm.on(
    "window-config-reloaded",
    function(window, pane)
        local process_name = pane:get_foreground_process_name()
        if not process_name then
            return
        end

        local executable = process_name:gsub("(.*[/\\])(.*)", "%2")
        if not executable:match "vim[.$]?" then
            return
        end

        if get_current_theme() == DEFAULT_DARK_THEME_NAME then
            pane:send_text(":set background=dark\n")
        else
            pane:send_text(":set background=light\n")
        end
    end
)

-- macOS specific configurations
if wezterm.target_triple:find "apple%-darwin" then
    config.window_decorations = "RESIZE"
    config.font_size = 13
    config.initial_rows = 37

    return config
end

-- Linux specific configurations

return config
