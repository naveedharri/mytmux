#!/bin/sh
# pane-namer.sh — assign NATO-phonetic call signs to the panes of a window.
#
# Pane call signs are STICKY: once a pane is named it keeps that name for life,
# stored in its @name option. This script only ever names panes that don't have
# one yet, giving each the lowest unused sign (1=BANKYE, 2=BRAVO-2, 3=CHARLIE-3,
# ...). It NEVER renames a pane that already has a name.
#
# Why sticky and not by-position: the zoom (Cmd+l / zoom-cycle.sh) swaps the
# focused pane into slot 1 to make it the big pane. A by-position namer would then
# relabel whatever landed in slot 1 as BANKYE — so zooming CHARLIE-3 would rename
# it BANKYE. Binding the name to the pane instead of the slot makes names immune to
# swaps, layout changes, and zoom.
#
# Killing a pane frees its sign; the next new pane reuses the lowest free one, so
# the numbering stays compact without ever renaming a living pane.
#
# Usage: pane-namer.sh [window_id]   (defaults to the current window)

WINDOW="$1"

NATO="ALPHA BRAVO CHARLIE DELTA ECHO FOXTROT GOLF HOTEL INDIA JULIETT KILO LIMA MIKE NOVEMBER OSCAR PAPA QUEBEC ROMEO SIERRA TANGO UNIFORM VICTOR WHISKEY XRAY YANKEE ZULU"

if [ -n "$WINDOW" ]; then
  set -- -t "$WINDOW"
else
  set --
fi

# call sign for a slot number: 1 -> BANKYE, N -> <Nth NATO word>-N
name_for() {
  n="$1"
  [ "$n" -eq 1 ] && { echo "BANKYE"; return; }
  w=$(echo "$NATO" | cut -d' ' -f"$n")
  [ -n "$w" ] && echo "$w-$n" || echo "UNIT-$n"
}

# slot number carried by an existing call sign (BANKYE -> 1, "BRAVO-2" -> 2)
slot_of() {
  case "$1" in
    BANKYE) echo 1 ;;
    *-*)    echo "${1##*-}" ;;
    *)      echo 0 ;;
  esac
}

panes=$(tmux list-panes "$@" -F '#{pane_id}|#{@name}')

# Pass 1: record which slots are already taken; collect the still-unnamed panes.
used=" "
unnamed=""
while IFS='|' read -r pid nm; do
  [ -z "$pid" ] && continue
  if [ -n "$nm" ]; then
    used="$used$(slot_of "$nm") "
  else
    unnamed="$unnamed$pid "
  fi
done <<EOF
$panes
EOF

# Pass 2: give each unnamed pane (in index order) the lowest unused slot.
for pid in $unnamed; do
  n=1
  while echo "$used" | grep -q " $n "; do n=$((n + 1)); done
  used="$used$n "
  tmux set-option -p -t "$pid" @name "$(name_for "$n")"
done
