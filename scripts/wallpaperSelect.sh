#!/usr/bin/env bash

iDIR="$HOME/.config/swaync/icons"

wallpaperDir="$HOME/Pictures/wallpapers"
themesDir="$HOME/.config/rofi/themes"
cacheDir="$HOME/.cache/wallpaper-menu"
randomPreview="$cacheDir/random-preview.png"

FPS=60
TYPE="any"
DURATION=3
BEZIER="0.4,0.2,0.4,1.0"
SWWW_PARAMS="--transition-fps ${FPS} --transition-type ${TYPE} --transition-duration ${DURATION} --transition-bezier ${BEZIER}"

mapfile -t PICS < <(find -L "$wallpaperDir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.gif" \) | sort)

if [ "${#PICS[@]}" -eq 0 ]; then
  notify-send "Wallpaper" "No wallpapers found"
  exit 1
fi

randomNumber=$(( $(date +%s) + RANDOM + $$ ))
randomPicture="${PICS[$(( randomNumber % ${#PICS[@]} ))]}"
randomChoice="Random"

rofiCommand="rofi -show -dmenu -theme ${themesDir}/wallpaper-select.rasi"

generateRandomPreview() {
  mkdir -p "$cacheDir"

  mapfile -t previewFiles < <(find -L "$wallpaperDir" -type f \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" \) | shuf -n 5)

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

executeCommand() {
  wallpaper="$1"
  wallpaperName="$(basename "$wallpaper")"
  wallpaperName="${wallpaperName%.*}"

  if command -v swww &>/dev/null; then
    swww img "$wallpaper" ${SWWW_PARAMS}
    matugen image "$wallpaper" --source-color-index 0

    notify-send \
      -e \
      -h string:x-canonical-private-synchronous:wallpaper_notif \
      -h int:value:0 \
      -u low \
      -i "$iDIR/picture.png" \
      "Wallpaper changed" "$wallpaperName"
  fi
}

menu() {
  printf "%s\x00icon\x1f%s\n" "$randomChoice" "$randomPreview"

  for i in "${!PICS[@]}"; do
    if [[ ! "${PICS[$i]}" =~ \.gif$ ]]; then
      name="$(basename "${PICS[$i]}")"
      name="${name%.*}"
      printf "%s\x00icon\x1f%s\n" "$name" "${PICS[$i]}"
    else
      printf "%s\n" "$(basename "${PICS[$i]}")"
    fi
  done
}

if command -v swww &>/dev/null; then
  swww query >/dev/null 2>&1 || swww init
fi

main() {
  generateRandomPreview

  choice=$(menu | ${rofiCommand})

  if [[ -z "$choice" ]]; then
    exit 0
  fi

  if [[ "$choice" = "$randomChoice" ]]; then
    executeCommand "$randomPicture"
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
    executeCommand "$selectedFile"
  else
    notify-send "Wallpaper" "Image not found"
    exit 1
  fi
}

main
