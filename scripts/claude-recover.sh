#!/usr/bin/env bash
# Claude pane kill + resume-by-id.
#
# Replaces the old pane-graveyard. Instead of hiding panes (which left their
# Claude processes running forever in a detached _graveyard session, leaking
# RAM), this KILLS the pane for real and remembers how to bring the exact
# conversation back:
#
#   kill    Cmd+o — record the pane's (session-id + cwd), then kill it. Claude
#           persists every turn to disk, so the conversation survives the kill.
#   resume  Cmd+u — open a fresh pane running `claude --resume <id>` in that cwd,
#           reloading the exact conversation. Terminal scrollback starts fresh;
#           the conversation itself is intact.
#
# Session id == the transcript filename under
#   ~/.claude/projects/<cwd-with-nonalnum-turned-to-dashes>/<session-id>.jsonl
# The pane's live session is the most-recently-written transcript for its cwd,
# so at kill time we grab the newest .jsonl in that project folder.
set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mytmux"
STATE="$STATE_DIR/last-killed-claude"   # one line: "<session-id>\t<cwd>"

# session id of the Claude running in cwd $1 (newest transcript), or empty
session_for_cwd() {
  local cwd="$1" slug proj newest
  slug=$(printf '%s' "$cwd" | sed 's/[^A-Za-z0-9]/-/g')
  proj="$HOME/.claude/projects/$slug"
  [ -d "$proj" ] || return 0
  newest=$(ls -t "$proj"/*.jsonl 2>/dev/null | head -1)
  [ -n "$newest" ] && basename "$newest" .jsonl
}

case "${1:-}" in
  kill)
    src="$(tmux display -p '#{pane_id}')"
    cwd="$(tmux display -p -t "$src" '#{pane_current_path}')"
    id="$(session_for_cwd "$cwd")"
    if [ -n "$id" ]; then
      mkdir -p "$STATE_DIR"
      printf '%s\t%s\n' "$id" "$cwd" > "$STATE"
    fi
    # kill for real (frees the process); re-balance the surviving grid
    tmux kill-pane -t "$src"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  resume)
    id=""; cwd=""
    if [ -f "$STATE" ]; then
      IFS=$'\t' read -r id cwd < "$STATE"
    fi
    if [ -n "$id" ] && [ -d "$cwd" ]; then
      tmux split-window -c "$cwd" "claude --resume $id"
      rm -f "$STATE"                 # consumed: the session is back on screen
    else
      # nothing recorded (or the folder moved): resume the latest conversation here
      here="$(tmux display -p '#{pane_current_path}')"
      tmux split-window -c "$here" 'claude --continue'
    fi
    tmux select-layout tiled 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 {kill|resume}" >&2
    exit 2
    ;;
esac
