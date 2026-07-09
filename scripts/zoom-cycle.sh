#!/usr/bin/env bash
# Single-level "focus" zoom for tmux — a softer alternative to prefix-z fullscreen.
#
# Cmd+l (⌥9) TOGGLES the active pane into a main-vertical layout: the focused pane
# becomes a big pane on the left, and every other pane lines up as a readable
# vertical LIST down the right side. Press Cmd+l again — or switch panes (Cmd+k,
# ⌥h/j/k/l, arrows, a mouse click) — to restore the exact previous layout. The
# `reset` subcommand is wired to the after-select-pane hook for that.
#
# Why a layout swap instead of resizing in place: shrinking panes inside a 2x2 grid
# makes them narrow, and terminal TUIs (Claude Code especially) reflow badly when
# narrow — every word wraps onto its own line, so the background panes look broken.
# The main-vertical list keeps each background pane a sane, full-height-slice width
# so nothing reflows into garbage. One press, one useful focus view; no in-between
# levels.
#
# Usage: zoom-cycle.sh {toggle|reset} [window-id]
# The window-id is passed from the keybinding / hook as #{window_id} and MUST be
# explicit: this runs backgrounded (run-shell -b), and a backgrounded tmux call
# with no target resolves to the server's "current" window — which on a server
# with many sessions (e.g. the _graveyard) is often NOT the window you acted in.
set -uo pipefail

MAIN_PCT=80      # width % of the focused pane; the rest is the sidebar list (80/20).
                 # Set via tmux's native percentage syntax so there is no window-
                 # width math to go wrong. Lower it (e.g. 70) for a wider list.

sub="${1:-toggle}"
win="${2:-$(tmux display -p '#{window_id}')}"   # explicit window, fallback if run by hand

get() { tmux show -wqv -t "$win" "$1" 2>/dev/null; }

# Restore the exact layout captured when zoom began, undoing the active-into-main
# swap first so every pane lands back in its own cell. Then forget the state.
restore_base() {
  local base swap; base="$(get @zoom_base)"; swap="$(get @zoom_swap)"
  if [ -n "$swap" ]; then
    tmux swap-pane -d -s "${swap% *}" -t "${swap#* }" 2>/dev/null || true
  fi
  if [ -n "$base" ]; then
    tmux select-layout -t "$win" "$base" 2>/dev/null \
      || tmux select-layout -t "$win" tiled 2>/dev/null || true
  fi
  tmux set -uw -t "$win" @zoom_on 2>/dev/null || true
  tmux set -uw -t "$win" @zoom_base 2>/dev/null || true
  tmux set -uw -t "$win" @zoom_swap 2>/dev/null || true
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

    ap="$(tmux display -p -t "$win" '#{pane_id}')"                 # active (to focus)
    p0="$(tmux list-panes -t "$win" -F '#{pane_id}' | head -1)"    # current main slot

    # Remember the even layout for an exact restore, then lay out as a list.
    tmux set -w -t "$win" @zoom_base "$(tmux display -p -t "$win" '#{window_layout}')"
    tmux set -w -t "$win" main-pane-width "${MAIN_PCT}%"
    tmux select-layout -t "$win" main-vertical

    # main-vertical makes the FIRST pane the big one; swap the active pane into that
    # slot so the pane you're focused on is the one that grows (swap -d keeps focus,
    # so no select-pane fires and the reset hook stays quiet).
    if [ "$ap" != "$p0" ]; then
      tmux swap-pane -d -s "$ap" -t "$p0"
      tmux set -w -t "$win" @zoom_swap "$ap $p0"
    fi
    tmux set -w -t "$win" @zoom_on 1
    exit 0
    ;;

  *)
    echo "usage: $0 {toggle|reset} [window-id]" >&2
    exit 2
    ;;
esac
