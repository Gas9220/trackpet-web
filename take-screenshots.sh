#!/bin/zsh
# Takes the website's iPhone screenshots in the iOS Simulator, in every language, light and dark,
# into ../trackpet-assets/screenshots/<lang>/iphone/ and iphone-dark/, named as make-images.sh
# expects. Run it on a Mac that runs the simulator well (the MacBook Pro, not the 8 GB Air), with
# the three projects side by side: ../Trackpet, ../trackpet-assets (made here) and this one.
#
#     ./take-screenshots.sh                       # iPhone 18 Pro Max, every language
#     ./take-screenshots.sh "iPhone 18 Pro Max" it fr
#
# It copies screenshots/TrackpetScreenshots.swift into Trackpet's UI tests for the run and takes it
# out again, so Trackpet's repository is left as it was: the test is throwaway, as the app's
# CLAUDE.md asks of screenshot tests. It builds once, then runs the test once per language and
# appearance (about a minute each), with the status bar at 9:41 and full. Then:
#
#     ./make-images.sh && python3 build.py && swift make-social-images.swift
set -eu
cd "$(dirname "$0")"
site=$PWD
trackpet=${site:h}/Trackpet
assets=${site:h}/trackpet-assets/screenshots
device_name=${1:-iPhone 18 Pro Max}
languages=(en it fr es)
if (( $# > 1 )); then languages=(${@[2,-1]}); fi

typeset -A regions=(en en_GB it it_IT fr fr_FR es es_ES)

[[ -d $trackpet/TrackpetUITests ]] || { echo "Trackpet isn't at $trackpet" >&2; exit 1; }

udid=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
devices = [d for runtime in json.load(sys.stdin)['devices'].values() for d in runtime]
print(next((d['udid'] for d in devices if d['name'] == sys.argv[1]), ''))
" "$device_name")
[[ -n $udid ]] || { echo "No simulator named \"$device_name\": xcrun simctl list devices" >&2; exit 1; }

# Its own build folder, named .noindex so Spotlight leaves it alone, and away from an open Xcode's.
work=$(mktemp -d)/trackpet-screenshots.noindex
mkdir -p $work
test_file=$trackpet/TrackpetUITests/TrackpetScreenshots.swift
cp screenshots/TrackpetScreenshots.swift $test_file
cleanup() { rm -f $test_file; }
trap cleanup EXIT INT TERM

echo "Booting $device_name…"
xcrun simctl boot $udid 2> /dev/null || true
xcrun simctl bootstatus $udid -b > /dev/null
xcrun simctl status_bar $udid override --time 9:41 --dataNetwork wifi --wifiMode active --wifiBars 3 \
  --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100
open -a Simulator

echo "Building (log: $work/build.log)…"
xcodebuild -project $trackpet/Trackpet.xcodeproj -scheme Trackpet -destination "id=$udid" \
  -derivedDataPath $work/DerivedData build-for-testing > $work/build.log 2>&1 \
  || { tail -30 $work/build.log; echo "The build failed: $work/build.log" >&2; exit 1; }

# run <language> <appearance>: the test once, its screenshots exported and renamed.
run() {
  local language=$1 appearance=$2
  local name=$language-$appearance
  local folder=$assets/$language/$([[ $appearance == dark ]] && echo iphone-dark || echo iphone)
  xcrun simctl ui $udid appearance $appearance
  sleep 5  # The simulator redraws in its new appearance.

  rm -rf $work/$name.xcresult $work/$name
  # xcodebuild sometimes stays after the tests: read the result from its log, then stop it.
  # TEST_RUNNER_<NAME> in xcodebuild's environment reaches the test as <NAME>.
  TEST_RUNNER_LANGUAGE=$language TEST_RUNNER_REGION=${regions[$language]} \
  xcodebuild -project $trackpet/Trackpet.xcodeproj -scheme Trackpet -destination "id=$udid" \
    -derivedDataPath $work/DerivedData -resultBundlePath $work/$name.xcresult \
    -only-testing:TrackpetUITests/TrackpetScreenshots/testWebsiteScreenshots \
    test-without-building > $work/$name.log 2>&1 &
  local test=$!
  local result=""
  for _ in {1..600}; do
    result=$(grep -o '\*\* TEST [A-Z]* \*\*' $work/$name.log 2> /dev/null || true)
    [[ -n $result ]] && break
    kill -0 $test 2> /dev/null || break
    sleep 1
  done
  sleep 3
  kill $test 2> /dev/null || true
  if [[ $result != "** TEST SUCCEEDED **" ]]; then
    grep -E 'error|failed|XCTAssert' $work/$name.log | tail -10
    echo "$name: the test failed ($work/$name.log). Fix it in screenshots/TrackpetScreenshots.swift." >&2
    exit 1
  fi

  xcrun xcresulttool export attachments --path $work/$name.xcresult --output-path $work/$name > /dev/null
  mkdir -p $folder
  python3 - $work/$name $folder <<'PYTHON'
import json, shutil, sys
from pathlib import Path

exported, folder = Path(sys.argv[1]), Path(sys.argv[2])

def attachments(node):
    if isinstance(node, dict):
        if "exportedFileName" in node:
            yield node
        for value in node.values():
            yield from attachments(value)
    elif isinstance(node, list):
        for value in node:
            yield from attachments(value)

count = 0
for attachment in attachments(json.loads((exported / "manifest.json").read_text())):
    # "01-pets_0_<UUID>.png": the name the test gave it, before the first underscore.
    name = attachment["suggestedHumanReadableName"].split("_")[0]
    shutil.copy(exported / attachment["exportedFileName"], folder / f"{name}.png")
    count += 1
print(f"wrote {count} screenshots into {folder}")
PYTHON
}

for language in $languages; do
  for appearance in light dark; do
    echo "$language, $appearance…"
    run $language $appearance
  done
done
xcrun simctl ui $udid appearance light
xcrun simctl status_bar $udid clear
echo "Done. Now: ./make-images.sh && python3 build.py && swift make-social-images.swift"
