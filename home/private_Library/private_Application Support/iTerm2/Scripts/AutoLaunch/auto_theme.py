#!/usr/bin/env python3

# Reference: https://gist.github.com/jamesmacfie/2061023e5365e8b6bfbbc20792ac90f8

import iterm2


DARK_THEME_NAME = "Multiplex Dark"
LIGHT_THEME_NAME = "Multiplex Light"


async def main(connection):
    async with iterm2.VariableMonitor(
        connection, iterm2.VariableScopes.APP, "effectiveTheme", None
    ) as mon:
        while True:
            # Block until theme changes
            theme = await mon.async_get()

            # Themes have space-delimited attributes, one of which will be light or dark
            parts = theme.split(" ")
            theme_name = DARK_THEME_NAME if "dark" in parts else LIGHT_THEME_NAME
            try:
                preset = await iterm2.ColorPreset.async_get(connection, theme_name)
            except iterm2.colorpresets.ListPresetsException:
                pass
            else:
                # Update the list of all profiles and iterate over them.
                profiles = await iterm2.PartialProfile.async_query(connection)
                for partial in profiles:
                    # Fetch the full profile and then set the color preset in it.
                    profile = await partial.async_get_full_profile()
                    await profile.async_set_color_preset(preset)


iterm2.run_forever(main)
