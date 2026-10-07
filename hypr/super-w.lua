-- Append to ~/.config/hypr/bindings.lua
-- SUPER+W hides Spotify instead of killing it (was: close window).
-- Spotify is parked on special:spotify; quit it from the bar widget.
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window (hide Spotify)", function()
  local window = hl.get_active_window()
  if window and window.class == "Spotify" then
    hl.dispatch(hl.dsp.window.move({ workspace = "special:spotify", follow = false }))
  else
    hl.dispatch(hl.dsp.window.close())
  end
end)

-- Optional: toggle the widget popup from the keyboard.
-- o.bind("SUPER + M", "Spotify", "omarchy-shell kima.spotify toggle")
