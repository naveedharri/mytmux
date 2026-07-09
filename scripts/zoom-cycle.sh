#!/usr/bin/env bash
# Single-level pane zoom for tmux — a softer alternative to prefix-z fullscreen.
#
# Cmd+l (⌥9) TOGGLES the active pane between the even layout and one big zoom where
# it takes ~7/8 (3.5/4) of the window in each axis. Every other pane stays visible
# and fully interactive (click in, type, send queries). Press Cmd+l again to
# collapse, and switching panes (Cmd+k, ⌥h/j/k/l, arrows, a mouse click) collapses
# it too — the `reset` subcommand is wired to the after-select-pane hook.
#
# There are deliberately NO intermediate levels: one press, one useful zoom. (An
# earlier multi-level version could make the pane briefly *smaller* on the first
# press, because the lowest level was less than a pane's even share.)
#
# No patched tmux, no plugin: the zoom-in just steps `resize-pane` in small
# increments (~100ms) so it reads as a smooth glide; the collapse restores the
# exact saved layout instantly.
#
# Usage: zoom-cycle.sh {toggle|reset} [window-id]
# The window-id is passed from the keybinding / hook as #{window_id} and MUST be
# explicit: this runs backgrounded (run-shell -b), and a backgrounded tmux call
# with no target resolves to the server's "current" window — which on a server
# with many sessions (e.g. the _graveyard) is often NOT the window you acted in.
set -uo pipefail

FRAC=0.875      # active pane's share of each axis when zoomed (3.5 of 4)
STEPS=10        # animation frames for the zoom-in
FRAME=0.010     # seconds per frame (~100ms total glide)

sub="${1:-toggle}"
win="${2:-$(tmux display -p '#{window_id}')}"   # explicit window, fallback if run by hand

get() { tmux show -wqv -t "$win" "$1" 2>/dev/null; }

# Return to the exact layout captured when zoom began, then forget the state.
restore_base() {
  local base; base="$(get @zoom_base)"
  if [ -n "$base" ]; then
    tmux select-layout -t "$win" "$base" 2>/dev/null \
      || tmux select-layout -t "$win" tiled 2>/dev/null || true
  fi
  tmux set -uw -t "$win" @zoom_on 2>/dev/null || true
  tmux set -uw -t "$win" @zoom_base 2>/dev/null || true
}

case "$sub" in
  reset)
    # Cheap no-op on the common path: bail unless a zoom is actually active.
    [ -n "$(get @zoom_on)" ] && restore_base
    exit 0
    ;;

  toggle)
    # Nothing to zoom in a single-pane window.
    [ "$(tmux display -p -t "$win" '#{window_panes}')" -lt 2 ] && exit 0

    # Already zoomed -> collapse back to the even layout.
    if [ -n "$(get @zoom_on)" ]; then
      restore_base
      exit 0
    fi

    pane="$(tmux display -p -t "$win" '#{pane_id}')"   # the window's active pane

    # Remember the even layout so the toggle-off is an exact restore.
    tmux set -w -t "$win" @zoom_base "$(tmux display -p -t "$win" '#{window_layout}')"
    tmux set -w -t "$win" @zoom_on 1

    read -r ww wh cw ch <<<"$(tmux display -p -t "$pane" '#{window_width} #{window_height} #{pane_width} #{pane_height}')"
    tw="$(awk "BEGIN{printf \"%d\", $ww * $FRAC}")"
    th="$(awk "BEGIN{printf \"%d\", $wh * $FRAC}")"

    # Glide from the current size up to the target so the change reads as motion.
    for i in $(seq 1 "$STEPS"); do
      w=$(( cw + (tw - cw) * i / STEPS ))
      h=$(( ch + (th - ch) * i / STEPS ))
      tmux resize-pane -t "$pane" -x "$w" -y "$h" 2>/dev/null || true
      if [ "$i" -lt "$STEPS" ]; then sleep "$FRAME"; fi
    done
    exit 0
    ;;

  *)
    echo "usage: $0 {toggle|reset} [window-id]" >&2
    exit 2
    ;;
esac
