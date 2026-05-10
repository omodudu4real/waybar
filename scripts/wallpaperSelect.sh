#!/usr/bin/env bash

iDIR="$HOME/.config/swaync/icons"

wallpaperDir="$HOME/Pictures/wallpapers"
themesDir="$HOME/.config/rofi/themes"

cacheDir="$HOME/.cache/wallpaper-menu"
stateFile="$HOME/.cache/current-wallpaper"

randomPreview="$cacheDir/random-preview.png"

mkdir -p "$cacheDir"

FPS=60
TYPE="any"
DURATION=3
BEZIER="0.4,0.2,0.4,1.0"

SWWW_PARAMS="--transition-fps ${FPS} \
--transition-type ${TYPE} \
--transition-duration ${DURATION} \
--transition-bezier ${BEZIER}"

# --------------------------------------------------
# GTK + THEME REFRESH
# --------------------------------------------------
refresh_theme() {

  # Reload GTK theme session-wide
  current_theme=$(gsettings get org.gnome.desktop.interface gtk-theme | tr -d "'")

  gsettings set org.gnome.desktop.interface gtk-theme "$current_theme"

  # Restart GTK portal for stubborn GTK apps
  pkill xdg-desktop-portal-gtk 2>/dev/null

  # Optional lightweight GTK apps refresh
  pkill gsimplecal 2>/dev/null
}

# --------------------------------------------------
# RESTORE MODE (NO ANIMATION ON STARTUP)
# --------------------------------------------------
if [[ "$1" == "--restore" ]]; then

  if [ -f "$stateFile" ]; then
    wallpaper="$(cat "$stateFile")"

    if [ -f "$wallpaper" ]; then

      swww query >/dev/null 2>&1 || swww init

      # No animation during startup restore
      swww img "$wallpaper" --transition-type none

      matugen image "$wallpaper" --source-color-index 0

      refresh_theme
    fi
  fi

  exit 0
fi

# --------------------------------------------------
# LOAD WALLPAPERS
# --------------------------------------------------
mapfile -t PICS < <(
  find -L "$wallpaperDir" -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) \
  | sort
)

if [ "${#PICS[@]}" -eq 0 ]; then
  notify-send "Wallpaper" "No wallpapers found"
  exit 1
fi

randomNumber=$(( $(date +%s) + RANDOM + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"

randomChoice="Random"

rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

# --------------------------------------------------
# RANDOM PREVIEW
# --------------------------------------------------
generateRandomPreview() {

  mapfile -t previewFiles < <(
    find -L "$wallpaperDir" -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) \
    | shuf -n 5
  )

  if [ "${#previewFiles[@]}" -lt 5 ]; then
    cp "$iDIR/picture.png" "$randomPreview" 2>/dev/null
    return
  fi

  convert -size 320x220 xc:none \
    \( "${previewFiles[0]}" -resize 150x95^ -gravity center -extent 150x95 -background none -rotate -10 \) -gravity center -geometry -70-20 -composite \
    \( "${previewFiles[1]}" -resize 150x95^ -gravity center -extent 150x95 -background none -rotate 8 \) -gravity center -geometry +0-35 -composite \
    \( "${previewFiles[2]}" -resize 150x95^ -gravity center -extent 150x95 -background none -rotate -6 \) -gravity center -geometry +65+0 -composite \
    \( "${previewFiles[3]}" -resize 150x95^ -gravity center -extent 150x95 -background none -rotate 12 \) -gravity center -geometry -45+45 -composite \
    \( "${previewFiles[4]}" -resize 150x95^ -gravity center -extent 150x95 -background none -rotate -8 \) -gravity center -geometry +45+55 -composite \
    "$randomPreview"
}

# --------------------------------------------------
# APPLY WALLPAPER
# --------------------------------------------------
apply_wallpaper() {

  wallpaper="$1"

  # Animated transitions only for manual changes
  swww img "$wallpaper" ${SWWW_PARAMS}

  sleep 0.2

  # Generate Matugen theme
  matugen image "$wallpaper" --source-color-index 0

  # Refresh GTK apps/theme
  refresh_theme

  # Save wallpaper state
  echo "$wallpaper" > "$stateFile"

  notify-send \
    -e \
    -h string:x-canonical-private-synchronous:wallpaper_notif \
    -u low \
    -i "$iDIR/picture.png" \
    "Wallpaper changed" "$(basename "${wallpaper%.*}")"
}

# --------------------------------------------------
# ROFI MENU
# --------------------------------------------------
menu() {

  printf "%s\x00icon\x1f%s\n" "$randomChoice" "$randomPreview"

  for file in "${PICS[@]}"; do

    if [[ ! "$file" =~ \.gif$ ]]; then

      name="$(basename "$file")"
      name="${name%.*}"

      printf "%s\x00icon\x1f%s\n" "$name" "$file"

    else
      printf "%s\n" "$(basename "$file")"
    fi

  done
}

# --------------------------------------------------
# MAIN
# --------------------------------------------------
main() {

  generateRandomPreview

  choice=$(menu | ${rofiCommand})

  [ -z "$choice" ] && exit 0

  if [[ "$choice" = "$randomChoice" ]]; then
    apply_wallpaper "$randomPicture"
    exit 0
  fi

  selectedFile=""

  for file in "${PICS[@]}"; do

    name="$(basename "$file")"
    name="${name%.*}"

    if [[ "$name" = "$choice" || "$(basename "$file")" = "$choice" ]]; then
      selectedFile="$file"
      break
    fi

  done

  if [[ -n "$selectedFile" ]]; then
    apply_wallpaper "$selectedFile"
  else
    notify-send "Wallpaper" "Image not found"
    exit 1
  fi
}

# --------------------------------------------------
# INIT SWWW
# --------------------------------------------------
swww query >/dev/null 2>&1 || swww init

main

