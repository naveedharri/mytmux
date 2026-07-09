#!/usr/bin/env bash
# tmux pane graveyard: "undo close pane".
# Instead of killing a pane (which kills its process), bury it in a detached
# _graveyard session. The process keeps running, so it can be restored exactly
# as it was: same shell, same scrollback, same running program (e.g. Claude).
#
# Usage:  pane-graveyard.sh bury           # hide the current pane (recoverable)
#         pane-graveyard.sh restore        # pull the most-recently buried pane back
#         pane-graveyard.sh smart-restore  # restore a buried pane, else resume Claude
set -uo pipefail

GRAVE="_graveyard"

ensure_grave() {
  tmux has-session -t "$GRAVE" 2>/dev/null || \
    tmux new-session -d -s "$GRAVE" -n placeholder 'while :; do sleep 3600; done'
}

# echo the window id of the most-recently buried pane (LIFO), or nothing
latest_buried() {
  tmux has-session -t "$GRAVE" 2>/dev/null || return 0
  tmux list-windows -t "$GRAVE" \
      -F '#{window_activity} #{window_id} #{window_name}' \
    | grep -v ' placeholder$' | sort -nr | head -1 | awk '{print $2}'
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
    win="$(latest_buried)"
    [ -z "$win" ] && { tmux display-message "graveyard empty"; exit 0; }
    tmux join-pane -s "$win"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  smart-restore)
    # 1) a recoverably-closed pane still alive in the graveyard? bring it back untouched.
    win="$(latest_buried)"
    if [ -n "$win" ]; then
      tmux join-pane -s "$win"
      tmux select-layout tiled 2>/dev/null || true
      exit 0
    fi
    # 2) nothing buried (pane was truly killed / crashed): open a fresh pane and
    #    resume the last Claude conversation from history.
    tmux split-window -c '#{pane_current_path}' 'claude --continue'
    tmux select-layout tiled 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 {bury|restore|smart-restore}" >&2
    exit 2
    ;;
esac
