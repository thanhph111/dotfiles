#!/bin/bash

show_colors() {
    echo
    for x in $(seq 0 8); do
        for i in $(seq 30 37); do
            for a in $(seq 40 47); do
                echo -ne "\e[$x;$i;$a""m\\\e[$x;$i;$a""m\e[0;37;40m "
            done
            echo
        done
    done
    echo
}

show_colors_16() {
    T='gYw'
    echo -e "\n              \
40m   41m   42m   43m   44m   45m   46m   47m   \
100m  101m  102m  103m  104m  105m  106m  107m"
    for FGs in \
        '    m' '   1m' '  30m' '1;30m' '  31m' '1;31m' '  32m' '1;32m' \
        '  33m' '1;33m' '  34m' '1;34m' '  35m' '1;35m' '  36m' '1;36m' \
        '  37m' '1;37m' '  90m' '1;90m' '  91m' '1;91m' '  92m' '1;92m' \
        '  93m' '1;93m' '  94m' '1;94m' '  95m' '1;95m' '  96m' '1;96m' \
        '  97m' '1;97m'; do
        FG=${FGs// /}
        echo -en " $FGs \033[$FG $T "
        for BG in 40m 41m 42m 43m 44m 45m 46m 47m \
            100m 101m 102m 103m 104m 105m 106m 107m; do
            echo -en "$EINS \033[$FG\033[$BG $T \033[0m"
        done
        echo
    done
    echo
}

show_colors_256() {
    echo
    for i in {0..255} ; do
        printf "\x1b[48;5;%sm%3d\e[0m " "$i" "$i"
        if (( i == 15 )) || (( i > 15 )) && (( (i-15) % 6 == 0 )); then
            printf "\n";
        fi
    done
    echo
}

test_true_color() {
    awk -v term_cols="${width:-$(tput cols || echo 80)}" 'BEGIN{
        s="/\\";
        for (colnum = 0; colnum<term_cols; colnum++) {
            r = 255-(colnum*255/term_cols);
            g = (colnum*510/term_cols);
            b = (colnum*255/term_cols);
            if (g>255) g = 510-g;
            printf "\033[48;2;%d;%d;%dm", r,g,b;
            printf "\033[38;2;%d;%d;%dm", 255-r,255-g,255-b;
            printf "%s\033[0m", substr(s,colnum%2+1,1);
        }
        printf "\n";
    }'
}
