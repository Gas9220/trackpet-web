#!/bin/zsh
# Renders the app's Classic icon (../Trackpet/Trackpet/AppIcons/AppIcon.icon) with Icon Composer's
# ictool, which comes with Xcode, into the site's three: app-icon.png (three times the 88 points
# the home page shows it at), apple-touch-icon.png (the Home Screen's) and favicon.png. PNG, as
# Xcode's tools don't write WebP and the three are small. Run it after the icon changes:
#
#     ./make-app-icons.sh
set -eu
cd "$(dirname "$0")"
ictool="$(xcode-select -p)/../Applications/Icon Composer.app/Contents/Executables/ictool"
full=$(mktemp -d)/AppIcon-1024.png
trap 'rm -rf "${full:h}"' EXIT

"$ictool" ../Trackpet/Trackpet/AppIcons/AppIcon.icon --export-image --output-file $full \
  --platform iOS --rendition Default --width 1024 --height 1024 --scale 1 > /dev/null
sips -Z 264 $full --out images/app-icon.png > /dev/null
sips -Z 180 $full --out images/apple-touch-icon.png > /dev/null
sips -Z 64 $full --out images/favicon.png > /dev/null
echo "wrote images/app-icon.png, apple-touch-icon.png and favicon.png"
