#!/usr/bin/env bash
# tmux pane graveyard: "undo close pane".
# Instead of killing a pane (which kills its process), bury it in a detached
# _graveyard session. The process keeps running, so it can be restored exactly
# as it was: same shell, same scrollback, same running program (e.g. Claude).
#
# Usage:  pane-graveyard.sh bury      # hide the current pane (recoverable)
#         pane-graveyard.sh restore   # pull the most-recently buried pane back
set -uo pipefail

GRAVE="_graveyard"

ensure_grave() {
  tmux has-session -t "$GRAVE" 2>/dev/null || \
    tmux new-session -d -s "$GRAVE" -n placeholder 'while :; do sleep 3600; done'
}

case "${1:-}" in
  bury)
    # never bury a pane that already lives in the graveyard
    [ "$(tmux display -p '#{session_name}')" = "$GRAVE" ] && exit 0
    src="$(tmux display -p '#{pane_id}')"
    name="$(tmux display -p -t "$src" '#{pane_current_command}')"
    ensure_grave
    # move the pane into its own graveyard window (append), keep focus where it is
    tmux break-pane -d -s "$src" -t "$GRAVE:" -n "${name:-pane}"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  restore)
    tmux has-session -t "$GRAVE" 2>/dev/null || { tmux display-message "graveyard empty"; exit 0; }
    # most-recently buried window = highest activity timestamp (LIFO undo)
    win="$(tmux list-windows -t "$GRAVE" \
             -F '#{window_activity} #{window_id} #{window_name}' \
           | grep -v ' placeholder$' | sort -nr | head -1 | awk '{print $2}')"
    [ -z "$win" ] && { tmux display-message "graveyard empty"; exit 0; }
    tmux join-pane -s "$win"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 {bury|restore}" >&2
    exit 2
    ;;
esac
