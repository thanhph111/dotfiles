-- https://wezfurlong.org/wezterm/
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

-- Get the current theme based on the current theme index in the global storage
local function get_current_theme()
    return THEMES[wezterm.GLOBAL.current_theme_index or 1]
end

local function get_window_background_gradient()
    local theme = get_current_theme()
    if theme == DEFAULT_DARK_THEME_NAME then
        return {
            colors = { "#0e101a", "#121432" },
            orientation = { Linear = { angle = 45.0 } },
            noise = 100,
        }
    end
    if theme == DEFAULT_LIGHT_THEME_NAME then
        return {
            colors = { "#ffefba", "#ffffff" },
            orientation = { Radial = { cx = 0.8, cy = 0.8, radius = 1.5 } }
        }
    end
    return nil
end

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

-- Set Vim background color based on the current theme when the config is loaded
wezterm.on(
    "window-config-reloaded",
    function(_, pane)
        local process_name = pane:get_foreground_process_name()
        if not process_name then
            return
        end

        local executable = process_name:gsub("(.*[/\\])(.*)", "%2")
        if not (executable == "vim" or executable:find "^vim%.") then
            return
        end

        if get_current_theme() == DEFAULT_DARK_THEME_NAME then
            pane:send_text ":set background=dark\n"
        else
            pane:send_text ":set background=light\n"
        end
    end
)

local HALF_LEFT_CIRCLE = utf8.char(0xe0b6)
local HALF_RIGHT_CIRCLE = utf8.char(0xe0b4)
local UPPER_LEFT_TRIANGLE = utf8.char(0xe0bc)
local SEPARATOR = utf8.char(0xe0bb)

wezterm.on(
    "format-tab-title",
    function(tab, tabs, panes, config, hover, max_width)
        local tab_bar_background = "#444444"

        local inactive_foreground = "#444444"
        local inactive_background = "#999999"
        local active_foreground = inactive_foreground
        local active_background = "#eeeeee"

        local index_buble_foreground = "white"
        local index_buble_background = "#696969"

        -- Current tab color
        local current_tab_foreground = inactive_foreground
        local current_tab_background = inactive_background
        if tab.is_active then
            current_tab_background = active_background
            current_tab_foreground = active_foreground
        end

        -- Next tab color
        local next_tab_background = inactive_background
        local next_tab = tabs[tab.tab_index + 2]
        if next_tab and next_tab.is_active then
            next_tab_background = active_background
        end

        -- Tab title
        local tab_index = tostring(tab.tab_index + 1)
        local tab_title = wezterm.truncate_right(
            tab.active_pane.title, max_width - 7 - #tab_index
        )
        tab_title = tab_title .. "… "

        -- Separator
        local separator = {
            { Foreground = { Color = active_background } },
            { Background = { Color = current_tab_background } },
            { Text = SEPARATOR },
        }
        if not next_tab then
            separator = {
                { Foreground = { Color = current_tab_background } },
                { Background = { Color = tab_bar_background } },
                { Text = UPPER_LEFT_TRIANGLE },
            }
        end
        if tab.is_active or (next_tab and next_tab.is_active) then
            local background = next_tab_background
            if not next_tab then
                background = tab_bar_background
            end
            separator = {
                { Foreground = { Color = current_tab_background } },
                { Background = { Color = background } },
                { Text = UPPER_LEFT_TRIANGLE },
            }
        end

        return {
            { Foreground = { Color = index_buble_background } },
            { Background = { Color = current_tab_background } },
            { Text = " " .. HALF_LEFT_CIRCLE },

            { Foreground = { Color = index_buble_foreground } },
            { Background = { Color = index_buble_background } },
            { Text = tab_index },

            { Foreground = { Color = index_buble_background } },
            { Background = { Color = current_tab_background } },
            { Text = HALF_RIGHT_CIRCLE .. " " },

            { Foreground = { Color = current_tab_foreground } },
            { Attribute = { Intensity = "Bold" } },
            { Text = tab_title },

            table.unpack(separator)
        }
    end
)


local config = {
    font = wezterm.font("FiraCode Nerd Font", { weight = 500 }),
    font_size = 10,
    line_height = 1.0,
    default_cursor_style = "BlinkingBar",
    cursor_thickness = "1pt",
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
    -- window_background_gradient = get_window_background_gradient(),
    enable_scroll_bar = false,
    window_decorations = "RESIZE",
    default_cwd = ("%s/Desktop"):format(wezterm.home_dir),

    colors = {
        tab_bar = {
            new_tab = {
                fg_color = "#999999",
                bg_color = "#444444",
            },
            background = "#444444",
        }
    },

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
            action = action.EmitEvent "switch-theme",
        },
        {
            key = "F1",
            action = wezterm.action_callback(
                function()
                    wezterm.open_with "https://wezfurlong.org/wezterm/"
                end
            )
        },
    }
}

-- Windows specific configurations
if wezterm.target_triple:find "windows%-msvc" then
    config.font = wezterm.font("FiraCode NF", { weight = 500 })
    config.default_prog = { "powershell.exe", "-NoLogo" }

    return config
end

-- macOS specific configurations
if wezterm.target_triple:find "apple%-darwin" then
    config.font_size = 13
    config.initial_rows = 37
    config.default_prog = {
        "zsh",
        "-ils",
        "eval",
        "piccel ~/.local/bin/pac-man.json"
    }

    return config
end

-- Linux specific configurations
config.window_decorations = nil
config.default_prog = {
    "bash",
    "-is",
    "eval",
    "piccel ~/.local/bin/pac-man.json"
}

return config
