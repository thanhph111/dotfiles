-- https://wezfurlong.org/wezterm/index.html
local wezterm = require "wezterm";
local config = {
    font = wezterm.font("FiraCode Nerd Font"),
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
    enable_scroll_bar = true,
    use_fancy_tab_bar = false,
    hide_tab_bar_if_only_one_tab = true,
    tab_bar_at_bottom = true,
    default_cwd = "/home/thanhph111/Desktop",
    color_scheme = "Multiplex",
    color_schemes = {
        ["Multiplex"] = {
            foreground = "#FFFAF4",
            background = "#0E1019",
            cursor_bg = "#91805a",
            cursor_fg = "black",
            cursor_border = "#52ad70",
            selection_fg = "#181c27",
            selection_bg = "#FFFFFF",
            ansi = {
                "#181A1B",
                "#A91409",
                "#38803A",
                "#CC7A00",
                "#0A6AB6",
                "#522E92",
                "#37AAB9",
                "#788187"
            },
            brights = {
                "#555B5E",
                "#FF3078",
                "#ADDD1E",
                "#FFEC16",
                "#0287C3",
                "#D10AFF",
                "#4AE3F7",
                "#DCDFE4"
            },
            indexed = {
                [136] = "#af8700"
            },
            scrollbar_thumb = "#222222",
            split = "#444444",
            dead_key_cursor = "orange"
        }
    },
    colors = {
        tab_bar = {
            background = "#444",
            active_tab = {
                fg_color = "#000",
                bg_color = "#eee",
                intensity = "Bold",
                underline = "None",
                italic = false,
                strikethrough = false
            },
            inactive_tab = {
                fg_color = "#444",
                bg_color = "#999"
            },
            new_tab = {
                fg_color = "#444",
                bg_color = "#999"
            },
            inactive_tab_hover = {
                fg_color = "#444",
                bg_color = "#999"
            },
            new_tab_hover = {
                fg_color = "#444",
                bg_color = "#999"
            }
        }
    }
}

return config
