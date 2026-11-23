#!/bin/zsh
# Writes the screenshots the pages show, in WebP, from the full-size originals in ../trackpet-assets,
# which stay out of this repository, into images/<lang>/, each with a -dark version for the site's
# dark theme. At this size WebP looks the same as PNG in about a fifteenth of the room, which counts
# on a phone. Run it after new screenshots, then `python3 build.py` (the first ones turn the
# screenshots' sections on) and draw the pictures for shared links again (make-social-images.swift).
# It needs cwebp: brew install webp.
#
#     ./make-images.sh
set -eu
cd "$(dirname "$0")"
assets=../trackpet-assets

# webp <source> <width, 0 to keep it> <destination>
webp() {
  if (( $2 )); then
    cwebp -quiet -q 82 -m 6 -sharp_yuv -resize $2 0 "$1" -o "$3"
  else
    cwebp -quiet -q 82 -m 6 -sharp_yuv "$1" -o "$3"
  fi
}

for language in en it fr es; do
  source=$assets/screenshots/$language
  output=images/$language
  mkdir -p $output
  for screen in 01-pets:pets 02-pet:pet 03-weights:weights 04-vaccinations:vaccinations \
                05-therapy:therapy 06-calendar:calendar 07-documents:documents 08-costs:costs \
                09-clinic:clinic 10-settings:settings 11-health-report:health-report; do
    webp $source/iphone/${screen%%:*}.png 660 $output/${screen##*:}.webp
    webp $source/iphone-dark/${screen%%:*}.png 660 $output/${screen##*:}-dark.webp
  done
  # The Mac's, taken by hand (README, "Screenshots"), once they're there.
  if [[ -f $source/mac/01-window.png ]]; then
    webp $source/mac/01-window.png 1100 $output/mac-window.webp
    webp $source/mac-dark/01-window.png 1100 $output/mac-window-dark.webp
    webp $source/mac/02-menu-bar.png 360 $output/mac-menu-bar.webp
    webp $source/mac-dark/02-menu-bar.png 360 $output/mac-menu-bar-dark.webp
  fi
  echo "wrote images/$language: $(du -sk $output/*.webp | awk '{sum += $1} END {print sum}') KB"
done
