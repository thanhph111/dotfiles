-- https://wezfurlong.org/wezterm/index.html
local wezterm = require "wezterm";

local config = {
    font = wezterm.font("FiraCode Nerd Font", { weight = 500 }),
    font_size = 13,
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
    initial_rows = 37,
    use_resize_increments = true,

    use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_bar_at_bottom = true,

    enable_scroll_bar = false,
    default_cwd = string.format("%s/Desktop", wezterm.home_dir),
    color_scheme = "Multiplex Light",
    window_decorations = "RESIZE",
}

return config
