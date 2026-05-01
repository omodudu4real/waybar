#!/usr/bin/env bash

THEME="$HOME/.config/rofi/themes/wifi-menu.rasi"

wifi_status=$(nmcli radio wifi)
wifi_device=$(nmcli -t -f DEVICE,TYPE device status | awk -F: '$2=="wifi"{print $1; exit}')

options="󰖩  Scan networks\n󰖪  Disconnect\n󰖩  Toggle WiFi ($wifi_status)"

networks=$(nmcli -t -f IN-USE,SSID,SIGNAL,SECURITY dev wifi list --rescan yes | awk -F: '
$2 != "" {
    lock = ($4 == "" || $4 == "--") ? "" : ""
    active = ($1 == "*") ? "  connected" : ""
    printf "%s  %s%%  %s%s\n", lock, $3, $2, active
}')

chosen=$(printf "%b\n%s" "$options" "$networks" | rofi -dmenu -i -p "WiFi" -theme "$THEME")

[ -z "$chosen" ] && exit 0

case "$chosen" in
    *"Scan networks"*)
        exec "$0"
        ;;

    *"Disconnect"*)
        if [ -n "$wifi_device" ]; then
            nmcli device disconnect "$wifi_device" \
                && notify-send "WiFi" "Disconnected from network" \
                || notify-send "WiFi" "Failed to disconnect"
        else
            notify-send "WiFi" "No WiFi device found"
        fi
        exit 0
        ;;

    *"Toggle WiFi"*)
        if [ "$wifi_status" = "enabled" ]; then
            nmcli radio wifi off && notify-send "WiFi" "WiFi disabled"
        else
            nmcli radio wifi on && notify-send "WiFi" "WiFi enabled"
        fi
        exit 0
        ;;
esac

ssid=$(echo "$chosen" | sed -E 's/^[^ ]+  [0-9]+%  //; s/  connected$//')

[ -z "$ssid" ] && exit 0

security=$(nmcli -t -f SSID,SECURITY dev wifi list | awk -F: -v s="$ssid" '$1 == s {print $2; exit}')

if [ -n "$security" ] && [ "$security" != "--" ]; then
    password=$(rofi -dmenu -password -p "Password for $ssid" -theme "$THEME")
    [ -z "$password" ] && exit 0

    nmcli dev wifi connect "$ssid" password "$password" \
        && notify-send "WiFi" "Connected to $ssid" \
        || notify-send "WiFi" "Failed to connect to $ssid"
else
    nmcli dev wifi connect "$ssid" \
        && notify-send "WiFi" "Connected to $ssid" \
        || notify-send "WiFi" "Failed to connect to $ssid"
fi
