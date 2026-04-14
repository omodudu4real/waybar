#!/bin/bash

HYPRLOCK="$HOME/.config/hypr/hyprlock/hyprlock.conf"

print_status() {
    if pgrep -x "hyprlock" >/dev/null ; then
        echo '{"text": "", "class": "active", "tooltip": ""}'
    else
        echo '{"text": "", "class": "notactive", "tooltip": ""}'
    fi
}

case "$1" in
    status)
        sleep 0.2
        print_status
        ;;
    toggle)
        # Lock the screen using your custom config
        hyprlock -c "$HYPRLOCK" &
        sleep 0.2
        print_status
        ;;
    *)
        echo "Usage: $0 {status|toggle}"
        exit 1
        ;;
esac
