#!/bin/sh
# Breathe the active pane border through a cyan gradient for a subtle neon "alive" effect.
# Keeps the thin border style; the mode-aware conditional still wins, so the border
# turns green in copy-mode and coral when panes are synchronized.

# kill any previously running pulse loop (avoids duplicates on config reload)
for pid in $(pgrep -f "pulse-border.sh"); do
  [ "$pid" != "$$" ] && kill "$pid" 2>/dev/null
done

# smooth ramp from dim to bright cyan and back — one full breath ~= 1.5s
colors="#2e5f78 #3b7896 #4a91b4 #5cb0d6 #7dcfff #a3e0ff #7dcfff #5cb0d6 #4a91b4 #3b7896"

while tmux has-session 2>/dev/null; do
  for c in $colors; do
    tmux set -g pane-active-border-style \
      "fg=#{?pane_in_mode,#9ece6a,#{?synchronize-panes,#f7768e,$c}}" 2>/dev/null || exit 0
    sleep 0.15
  done
done
