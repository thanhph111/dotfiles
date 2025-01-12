": Change the background mode based on macOS's `Appearance` setting
": Limitation: Vim won't execute the callback until its buffers are focused
function! utils#change_background()
    if (
        \ has("macunix") &&
        \ system("defaults read -g AppleInterfaceStyle") =~ '^Dark'
    \ ) || (
        \ has("unix") &&
        \ executable("/bin/gsettings") &&
        \ system(
            \ "/bin/gsettings get org.gnome.desktop.interface color-scheme"
        \ ) =~ 'prefer-dark'
    \ ) || (
        \ has("win32") &&
        \ system(
            \ "for /f \"tokens=2*\" %a in (
                \ 'reg query
    \ HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Themes\\Personalize
    \ /v AppsUseLightTheme'
            \ ) do echo %~b"
        \ ) =~ '0x0'
    \)
        set background=dark
    else
        set background=light
    endif
endfunction
