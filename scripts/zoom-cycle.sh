#!/usr/bin/env bash
# Leveled progressive zoom for tmux — a softer alternative to prefix-z fullscreen.
#
# Each `cycle` invocation grows the ACTIVE pane one level larger while every other
# pane stays visible and fully interactive (you can still click into them, type,
# send queries). Levels run 1..5; the 6th press wraps back to the original even
# layout — same loop-and-reset feel as the ⌥0 "cycle panes" chord. Moving focus to
# another pane resets the zoom: the `reset` subcommand is wired to tmux's
# after-select-pane hook, so navigating away (⌥h/j/k/l, the ⌥0 cycle, arrows, or a
# mouse click) always lands you back on a clean even layout.
#
# No patched tmux, no plugin: this is just `resize-pane` stepped in small
# increments to fake a smooth transition (tmux itself can't tween). At level 5 the
# active pane takes ~7/8 (0.875, "3.5 of 4") of the window in each axis; the rest
# share the remaining strip. Applied to BOTH width and height so it behaves for
# side-by-side, stacked, and grid layouts alike.
set -uo pipefail

LEVELS=5
# Linear fraction of the window the active pane occupies at each level (index 0
# is the even layout and unused). Even-ish steps from mid-screen up to 7/8.
FRACS=(0 0.45 0.56 0.67 0.78 0.875)
STEPS=10        # animation frames per press
FRAME=0.010     # seconds per frame (~100ms total glide)

win="$(tmux display -p '#{window_id}')"

get() { tmux show -wqv "$1" 2>/dev/null; }

# Return to the exact layout captured when zoom began, then forget the state.
restore_base() {
  local base; base="$(get @zoom_base)"
  if [ -n "$base" ]; then
    tmux select-layout -t "$win" "$base" 2>/dev/null \
      || tmux select-layout -t "$win" tiled 2>/dev/null || true
  fi
  tmux set -uw -t "$win" @zoom_level 2>/dev/null || true
  tmux set -uw -t "$win" @zoom_base 2>/dev/null || true
}

case "${1:-cycle}" in
  reset)
    # Cheap no-op on the common path: bail unless a zoom is actually active.
    lvl="$(get @zoom_level)"; lvl="${lvl:-0}"
    if [ "$lvl" -gt 0 ] 2>/dev/null; then restore_base; fi
    exit 0
    ;;

  cycle)
    # Nothing to zoom in a single-pane window.
    [ "$(tmux display -p '#{window_panes}')" -lt 2 ] && exit 0

    lvl="$(get @zoom_level)"; lvl="${lvl:-0}"
    next=$(( (lvl + 1) % (LEVELS + 1) ))

    # Wrapped past the top level: collapse back to the even layout.
    if [ "$next" -eq 0 ]; then
      restore_base
      exit 0
    fi

    # First step out of the even layout: remember it for an exact reset.
    [ "$lvl" -eq 0 ] && tmux set -w -t "$win" @zoom_base "$(tmux display -p '#{window_layout}')"
    tmux set -w -t "$win" @zoom_level "$next"

    frac="${FRACS[$next]}"
    read -r ww wh cw ch <<<"$(tmux display -p '#{window_width} #{window_height} #{pane_width} #{pane_height}')"
    tw="$(awk "BEGIN{printf \"%d\", $ww * $frac}")"
    th="$(awk "BEGIN{printf \"%d\", $wh * $frac}")"

    # Glide from the current size to the target so the change reads as motion.
    for i in $(seq 1 "$STEPS"); do
      w=$(( cw + (tw - cw) * i / STEPS ))
      h=$(( ch + (th - ch) * i / STEPS ))
      tmux resize-pane -x "$w" -y "$h" 2>/dev/null || true
      [ "$i" -lt "$STEPS" ] && sleep "$FRAME"
    done
    ;;

  *)
    echo "usage: $0 {cycle|reset}" >&2
    exit 2
    ;;
esac
