#!/usr/bin/env bash

# ---------------------------------------
# GTK Theme + Random Wallpaper Launcher
# Hyprland + Rofi + Matugen + Swww
# ---------------------------------------

themeDir="$HOME/.themes"
systemThemeDir="/usr/share/themes"

wallpaperDir="$HOME/Pictures/wallpapers"

rofiTheme="$HOME/.config/rofi/themes/theme-selector.rasi"

icon="$HOME/.config/swaync/icons/palette.png"

stateFile="$HOME/.cache/current-wallpaper"

MATUGEN="$(command -v matugen)"

# ---------------------------------------
# Get Installed Themes
# ---------------------------------------

get_themes() {
    {
        find "$themeDir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
        find "$systemThemeDir" -maxdepth 1 -mindepth 1 -type d 2>/dev/null
    } | xargs -I{} basename "{}" | sort -u
}

# ---------------------------------------
# Update GTK settings.ini
# ---------------------------------------

update_ini() {

    local file="$1"
    local theme="$2"

    mkdir -p "$(dirname "$file")"

    if [ ! -f "$file" ]; then
        cat > "$file" <<EOF
[Settings]
gtk-theme-name=$theme
gtk-application-prefer-dark-theme=1
EOF
        return
    fi

    if ! grep -q "^\[Settings\]" "$file"; then
        sed -i '1i [Settings]' "$file"
    fi

    if grep -q "^gtk-theme-name=" "$file"; then
        sed -i "s/^gtk-theme-name=.*/gtk-theme-name=$theme/" "$file"
    else
        echo "gtk-theme-name=$theme" >> "$file"
    fi

    if grep -q "^gtk-application-prefer-dark-theme=" "$file"; then
        sed -i "s/^gtk-application-prefer-dark-theme=.*/gtk-application-prefer-dark-theme=1/" "$file"
    else
        echo "gtk-application-prefer-dark-theme=1" >> "$file"
    fi
}

# ---------------------------------------
# Apply Theme
# ---------------------------------------

apply_theme() {

    selectedTheme="$1"

    # GTK theme
    gsettings set org.gnome.desktop.interface gtk-theme "$selectedTheme"
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"

    update_ini "$HOME/.config/gtk-3.0/settings.ini" "$selectedTheme"
    update_ini "$HOME/.config/gtk-4.0/settings.ini" "$selectedTheme"

    # -----------------------------------
    # Pick Random Wallpaper
    # -----------------------------------

    mapfile -t wallpapers < <(
        find "$wallpaperDir" -type f \
        \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \)
    )

    if [ "${#wallpapers[@]}" -gt 0 ]; then

        random_wallpaper="${wallpapers[RANDOM % ${#wallpapers[@]}]}"

        # init swww
        swww query >/dev/null 2>&1 || swww init

        # apply wallpaper
        swww img "$random_wallpaper" \
            --transition-type any \
            --transition-duration 2 \
            --transition-fps 60

        echo "$random_wallpaper" > "$stateFile"

        # -----------------------------------
        # RUN MATUGEN (FIXED STABLE TIMING)
        # -----------------------------------

        if command -v matugen >/dev/null 2>&1; then
            echo "Running Matugen..."

            # allow wallpaper render to fully settle
            sleep 0.6

            matugen image "$random_wallpaper" --source-color-index 0

            wait
        else
            echo "Matugen not found in PATH"
        fi
    fi

    # Notification
    notify-send \
        -e \
        -u low \
        -i "$icon" \
        "Theme Applied" \
        "$selectedTheme"
}

# ---------------------------------------
# Launch Rofi
# ---------------------------------------

chosenTheme=$(
    get_themes | rofi \
        -dmenu \
        -i \
        -p "󰉼 Theme" \
        -theme "$rofiTheme"
)

[ -z "$chosenTheme" ] && exit 0

apply_theme "$chosenTheme"
