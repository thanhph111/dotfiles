-- https://wezfurlong.org/wezterm/index.html
local wezterm = require "wezterm"

DEFAULT_DARK_THEME_NAME = "Multiplex Dark"
DEFAULT_LIGHT_THEME_NAME = "Multiplex Light"

local function scheme_for_appearance(appearance)
    if appearance:find "Light" then
        return DEFAULT_LIGHT_THEME_NAME
    else
        return DEFAULT_DARK_THEME_NAME
    end
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

    color_scheme = scheme_for_appearance(wezterm.gui.get_appearance()),
    enable_scroll_bar = false,
    default_cwd = string.format("%s/Desktop", wezterm.home_dir),
}

if wezterm.target_triple:find "windows%-msvc" then
    config.font = wezterm.font("FiraCode NF", { weight = 500 })
    config.default_prog = { "powershell.exe", "-NoLogo" }
else
    wezterm.on(
        "window-config-reloaded",
        function(window, pane)
            wezterm.run_child_process {
                "bash",
                "-c",
                "for pid in $(pgrep vim); do kill -SIGUSR1 $pid; done"
            }
        end
    )

    if wezterm.target_triple:find "apple%-darwin" then
        config.font_size = 13
        config.initial_rows = 37
        config.window_decorations = "RESIZE"
    end
end

return config
