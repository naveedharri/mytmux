#!/usr/bin/env bash
# Claude pane lifecycle: launch with a known session id, kill for real, resume exactly.
#
# The problem this solves: several Claude panes can share one cwd (this repo, say),
# and Claude stores every session as ~/.claude/projects/<cwd-slug>/<session-id>.jsonl.
# There is no reliable way to tell, after the fact, WHICH transcript belonged to WHICH
# pane. "Newest transcript for the cwd" guesses wrong the moment another Claude in the
# same folder writes more recently (e.g. an active session two panes over).
#
# So we stop guessing: at launch we MINT the session id ourselves (`claude --session-id
# <uuid>`) and stash it on the pane in the @claude_session option. Kill just reads it
# back — exact, every time, even on a hard kill.
#
#   new     Cmd+n — mint a uuid, open a pane running Claude pinned to it, remember it.
#   kill    Cmd+o — read the pane's session id, record (id + cwd), then kill the pane.
#   resume  Cmd+u — open a fresh pane running `claude --resume <id>` in that cwd.
#
# Claude persists every turn to disk, so the conversation survives the kill; only the
# terminal scrollback starts fresh on resume.
set -uo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/mytmux"
STATE="$STATE_DIR/last-killed-claude"   # one line: "<session-id>\t<cwd>"

case "${1:-}" in
  new)
    id="$(uuidgen | tr 'A-Z' 'a-z')"
    cwd="$(tmux display -p '#{pane_current_path}')"
    # -P -F prints the new pane's id so we can tag it with the session we pinned
    newpane="$(tmux split-window -c "$cwd" -P -F '#{pane_id}' \
      "claude --dangerously-skip-permissions --session-id $id")"
    tmux set-option -p -t "$newpane" @claude_session "$id"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  kill)
    src="$(tmux display -p '#{pane_id}')"
    cwd="$(tmux display -p -t "$src" '#{pane_current_path}')"
    # exact id if this pane was launched via `new`; empty for legacy/manual panes
    id="$(tmux show-options -p -t "$src" -qv @claude_session 2>/dev/null || true)"
    mkdir -p "$STATE_DIR"
    printf '%s\t%s\n' "$id" "$cwd" > "$STATE"
    tmux kill-pane -t "$src"
    tmux select-layout tiled 2>/dev/null || true
    ;;
  resume)
    id=""; cwd=""
    [ -f "$STATE" ] && IFS=$'\t' read -r id cwd < "$STATE"
    [ -n "$cwd" ] && [ -d "$cwd" ] || cwd="$(tmux display -p '#{pane_current_path}')"
    if [ -n "$id" ]; then
      # exact conversation, by the id we minted at launch
      tmux split-window -c "$cwd" "claude --resume $id"
    else
      # pane was never pinned (legacy/manual): best effort — latest convo in this cwd
      tmux split-window -c "$cwd" 'claude --continue'
    fi
    rm -f "$STATE"                        # consumed
    tmux select-layout tiled 2>/dev/null || true
    ;;
  *)
    echo "usage: $0 {new|kill|resume}" >&2
    exit 2
    ;;
esac
