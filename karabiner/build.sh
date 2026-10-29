#!/bin/bash
# build.sh LAYER_DIR... — merge each layer's karabiner.json fragment into
# Karabiner's live config.
#
# The repo owns the selected profile's complex rules, simple modifications,
# devices and virtual keyboard type. Everything else in karabiner.json (menu
# bar icon, other profiles, global settings) is left as Karabiner's GUI set
# it. Remaps changed in the GUI are overwritten on the next run: change the
# fragments instead.
#
# Layers are given in order, e.g. gnome pc-keyboard personal. Complex rules
# from later layers go first, because Karabiner uses the first rule that
# matches, so a later layer can override an earlier one.
#
# Fragments may carry "_comment" keys anywhere; they're stripped, since
# JSON has no comments and Karabiner shouldn't see them.
#
# Writes only if something changed, so re-running doesn't make Karabiner
# reload for nothing.

set -euo pipefail

OUT="${KARABINER_JSON:-$HOME/.config/karabiner/karabiner.json}"
[ $# -gt 0 ] || { echo "usage: $0 LAYER_DIR..." >&2; exit 1; }

fragments=()
for layer in "$@"; do
  [ -f "$layer/karabiner.json" ] && fragments+=("$layer/karabiner.json")
done

existing='{"profiles":[{"name":"Default profile","selected":true}]}'
[ -s "$OUT" ] && existing="$(cat "$OUT")"

new="$(jq -s --argjson existing "$existing" '
  def strip: walk(if type == "object" then with_entries(select(.key | startswith("_") | not)) else . end);
  map(strip) as $layers
  | ($layers | reverse | [.[].rules[]?]) as $rules
  | ($layers | reverse | [.[].simple_modifications[]?]) as $simple
  | ($layers | [.[].devices[]?]
      | group_by(.identifiers)
      | map(reduce .[] as $d ({}; . * ($d | del(.simple_modifications)))
            + {simple_modifications: [.[].simple_modifications[]?]})) as $devices
  | ($layers | reduce .[].virtual_hid_keyboard? as $v ({}; . * ($v // {}))) as $vhk
  | $existing
  | (.profiles | map(.selected == true) | index(true) // 0) as $i
  | .profiles[$i].complex_modifications.rules = $rules
  | .profiles[$i].simple_modifications = $simple
  | .profiles[$i].devices = $devices
  | .profiles[$i].virtual_hid_keyboard = ((.profiles[$i].virtual_hid_keyboard // {}) * $vhk)
' "${fragments[@]}")"

if [ -s "$OUT" ] && [ "$(jq -S . "$OUT")" = "$(jq -S . <<<"$new")" ]; then
  echo "   ok    $OUT"
  exit 0
fi

mkdir -p "$(dirname "$OUT")"
tmp="$(mktemp "$OUT.XXXXXX")"
jq . <<<"$new" > "$tmp"
mv "$tmp" "$OUT"
echo "   done  $OUT (from: $*)"
