-- https://wezfurlong.org/wezterm/index.html
local wezterm = require "wezterm"

DEFAULT_DARK_THEME_NAME = "Multiplex Dark"
DEFAULT_LIGHT_THEME_NAME = "Multiplex Light"

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

    color_scheme = wezterm.gui.get_appearance():find "Light" and
        DEFAULT_LIGHT_THEME_NAME or
        DEFAULT_DARK_THEME_NAME,
    enable_scroll_bar = false,
    default_cwd = string.format("%s/Desktop", wezterm.home_dir),
}

if wezterm.target_triple:find "windows%-msvc" then
    config.font = wezterm.font("FiraCode NF", { weight = 500 })
    config.default_prog = { "powershell.exe", "-NoLogo" }

    return config
end

-- Send SIGUSR1 to every Vim processes to trigger a check on system theme
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
    config.window_decorations = "RESIZE"
    config.font_size = 13
    config.initial_rows = 37
end

return config
