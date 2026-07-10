#!/bin/sh
# pane-namer.sh — assign NATO-phonetic call signs to the panes of a window.
#
# Pane 1 is always BANKYE (the commander). Every pane after it is numbered by
# position: BRAVO-2, CHARLIE-3, DELTA-4, ... Names are stored in the per-pane
# user option @name (not pane_title) so a program running in the pane — Claude,
# a shell, vim — can't clobber them with its own terminal-title escapes.
#
# Re-run on every split and every pane close so the sequence stays gap-free:
# kill CHARLIE-3 and DELTA-4 slides up to become the new CHARLIE-3.
#
# Usage: pane-namer.sh [window_id]   (defaults to the current window)

WINDOW="$1"

NATO="ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL INDIA JULIETT KILO LIMA MIKE NOVEMBER OSCAR PAPA QUEBEC ROMEO SIERRA TANGO UNIFORM VICTOR WHISKEY XRAY YANKEE ZULU"

if [ -n "$WINDOW" ]; then
  set -- -t "$WINDOW"
else
  set --
fi

pos=0
tmux list-panes "$@" -F '#{pane_id}' | while IFS= read -r pane_id; do
  pos=$((pos + 1))
  if [ "$pos" -eq 1 ]; then
    name="BANKYE"
  else
    word=$(echo "$NATO" | cut -d' ' -f"$pos")
    if [ -n "$word" ]; then
      name="$word-$pos"
    else
      name="UNIT-$pos"
    fi
  fi
  tmux set-option -p -t "$pane_id" @name "$name"
done
