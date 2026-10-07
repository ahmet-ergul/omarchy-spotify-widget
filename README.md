# omarchy-spotify-widget

A macOS-style Spotify widget for the [Omarchy](https://omarchy.org) shell bar
(Quickshell), plus a SUPER+W override so closing the Spotify window hides it
instead of killing the music.

## Features

- **Always on the bar** — even when Spotify is not running (dimmed icon, click to launch).
  Green icon + scrolling title while playing.
- **Popup** anchored top-right: album art, title / artist / album, seek bar,
  shuffle · previous · play/pause · next · repeat (off → all → one), volume.
- **Click the song** → the Spotify window jumps to your current workspace and gets focus.
- **Show / Hide / Quit Spotify** buttons. *Quit* is the only thing that ends the process.
- **SUPER+W** on the Spotify window parks it on a hidden `special:spotify`
  workspace; every other window closes as before.

| Mouse on the bar icon | Action |
|---|---|
| Left click | open / close the popup |
| Middle click | play / pause |
| Right click | show / hide the Spotify window |
| Scroll | next / previous track |

Keyboard: `omarchy-shell kima.spotify toggle` opens the popup (bind it to a key,
see `hypr/super-w.lua`).

## Install

Requires Omarchy 4 (Quickshell shell, Lua Hyprland config), `spotify-launcher`
(or any Spotify that exposes MPRIS), `jq`.

```sh
git clone https://github.com/<you>/omarchy-spotify-widget ~/Projects/omarchy-spotify-widget
~/Projects/omarchy-spotify-widget/install.sh
omarchy restart shell
```

`install.sh` symlinks `plugin/` to `~/.config/omarchy/plugins/kima.spotify`,
links `bin/spotify-ctl` into `~/.local/bin`, puts the widget at the left of
the right bar section, and appends the SUPER+W override to
`~/.config/hypr/bindings.lua`.

## Files

| Path | What |
|---|---|
| `plugin/manifest.json`, `plugin/BarWidget.qml` | the Quickshell bar widget (MPRIS) |
| `bin/spotify-ctl` | `show` / `hide` / `toggle` / `quit` the Spotify window via `hyprctl` |
| `hypr/super-w.lua` | SUPER+W override |

## License

MIT
