#!/bin/sh
# Link the widget into the Omarchy shell, install spotify-ctl, add it to the bar.
set -e
here=$(cd "$(dirname "$0")" && pwd)
id=kima.spotify

mkdir -p "$HOME/.config/omarchy/plugins" "$HOME/.local/bin"
ln -sfn "$here/plugin" "$HOME/.config/omarchy/plugins/$id"
ln -sf "$here/bin/spotify-ctl" "$HOME/.local/bin/spotify-ctl"

omarchy-shell -q shell rescanPlugins
omarchy plugin enable "$id" >/dev/null && omarchy bar move "$id" --section right --index 0 >/dev/null

bindings="$HOME/.config/hypr/bindings.lua"
if ! grep -q 'hide Spotify' "$bindings" 2>/dev/null; then
  printf '\n' >> "$bindings"
  grep -v '^-- Append to' "$here/hypr/super-w.lua" >> "$bindings"
  hyprctl reload >/dev/null
fi
echo "Spotify widget installed. Restart the shell if the IPC toggle is missing: omarchy restart shell"
