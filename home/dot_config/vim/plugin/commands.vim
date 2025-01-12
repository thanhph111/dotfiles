if exists('g:loaded_custom_commands')
    finish
endif
let g:loaded_custom_commands = 1

": Difference between the current buffer and the file it was loaded from
command DiffOrig vert new | set bt=nofile | r ++edit # | 0d_ | diffthis
    \ | wincmd p | diffthis

": Difference between the current buffer and the file it was loaded from
": https://stackoverflow.com/q/749297#comment33988378_22360650
command! DiffSaved w !vim - -c ":vnew % | windo diffthis"

": Custom command for sudo write
command! -bang W execute 'w !sudo tee % >/dev/null' <bar> edit!
