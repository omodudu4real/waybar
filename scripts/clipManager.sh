#!/usr/bin/env bash
## /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Clipboard Manager. This script uses cliphist, rofi, and wl-copy.

# Actions:
# CTRL Del to delete an entry
# ALT Del to wipe clipboard contents
#!/usr/bin/env bash
#!/usr/bin/env bash

while true; do
    list=$(cliphist list)

    menu=$(echo "$list" | awk '
    {
        id=$1
        $1=""
        sub(/^ /, "")
        print NR ".   " $0
    }')

    result=$(echo "$menu" | rofi -dmenu \
        -kb-custom-1 "Control-Delete" \
        -kb-custom-2 "Alt-Delete" \
        -config ~/.config/rofi/themes/clipboard.rasi)

    case "$?" in
        1)
            exit
            ;;
        0)
            [ -z "$result" ] && continue
            index=$(echo "$result" | cut -d'.' -f1)
            selected=$(echo "$list" | sed -n "${index}p")
            cliphist decode <<<"$selected" | wl-copy
            exit
            ;;
        10)
            [ -z "$result" ] && continue
            index=$(echo "$result" | cut -d'.' -f1)
            selected=$(echo "$list" | sed -n "${index}p")
            cliphist delete <<<"$selected"
            ;;
        11)
            cliphist wipe
            ;;
    esac
done
