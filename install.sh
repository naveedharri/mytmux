#!/usr/bin/env bash
# mytmux installer: reproduce Naveed's tmux setup on a fresh machine.
#
#   curl -fsSL https://raw.githubusercontent.com/naveedharri/mytmux/develop/install.sh | bash
#   # or, after cloning:
#   ./install.sh          # copy mode: drop files into ~/.config/tmux (independent copies)
#   ./install.sh link     # link mode: symlink ~/.config/tmux -> this checkout
#
# Link mode makes THIS git checkout the single source of truth: editing files
# here, or `git pull`, changes your live tmux config directly. This is the
# recommended way to keep settings in one place and load them from GitHub.
#
# What it does:
#   1. installs tmux (via Homebrew) if missing
#   2. clones Oh My Tmux (gpakosz/.tmux) into ~/.local/share/oh-my-tmux
#   3. symlinks ~/.config/tmux/tmux.conf -> the framework .tmux.conf
#   4. copies (or, in link mode, symlinks) tmux.conf.local + scripts into ~/.config/tmux
#   5. (optional) installs the Warp settings.toml with the option-as-meta keys
set -euo pipefail

MODE="${1:-copy}"   # copy | link
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OMT_DIR="$HOME/.local/share/oh-my-tmux"
TMUX_DIR="$HOME/.config/tmux"

say() { printf '\033[1;36m==>\033[0m %s\n' "$1"; }

# 1. tmux ----------------------------------------------------------------------
if ! command -v tmux >/dev/null 2>&1; then
  say "tmux not found, installing via Homebrew"
  if command -v brew >/dev/null 2>&1; then
    brew install tmux
  else
    echo "Homebrew not installed. Install tmux manually, then re-run." >&2
    exit 1
  fi
else
  say "tmux already installed ($(tmux -V))"
fi

# 2. Oh My Tmux framework ------------------------------------------------------
if [ -d "$OMT_DIR/.git" ]; then
  say "Oh My Tmux present, pulling latest"
  git -C "$OMT_DIR" pull --ff-only || true
else
  say "cloning Oh My Tmux -> $OMT_DIR"
  mkdir -p "$(dirname "$OMT_DIR")"
  git clone https://github.com/gpakosz/.tmux.git "$OMT_DIR"
fi

# 3 + 4. config ----------------------------------------------------------------
say "installing config into $TMUX_DIR (mode: $MODE)"
mkdir -p "$TMUX_DIR/scripts"
ln -sf "$OMT_DIR/.tmux.conf" "$TMUX_DIR/tmux.conf"

# back up an existing real (non-symlink) local config before replacing it
if [ -f "$TMUX_DIR/tmux.conf.local" ] && [ ! -L "$TMUX_DIR/tmux.conf.local" ] \
   && ! cmp -s "$TMUX_DIR/tmux.conf.local" "$REPO_DIR/tmux.conf.local"; then
  cp "$TMUX_DIR/tmux.conf.local" "$TMUX_DIR/tmux.conf.local.bak.$(date +%s)"
  say "backed up existing tmux.conf.local"
fi

if [ "$MODE" = "link" ]; then
  ln -sf "$REPO_DIR/tmux.conf.local" "$TMUX_DIR/tmux.conf.local"
  for f in "$REPO_DIR"/scripts/*.sh; do
    chmod +x "$f"
    ln -sf "$f" "$TMUX_DIR/scripts/$(basename "$f")"
  done
  say "linked config to checkout at $REPO_DIR (single source of truth)"
else
  cp "$REPO_DIR/tmux.conf.local" "$TMUX_DIR/tmux.conf.local"
  cp "$REPO_DIR"/scripts/*.sh "$TMUX_DIR/scripts/"
  chmod +x "$TMUX_DIR"/scripts/*.sh
fi

# 5. Warp settings (optional) --------------------------------------------------
if [ "${SKIP_WARP:-}" != "1" ] && [ -d "$HOME/.warp" ]; then
  if [ -f "$HOME/.warp/settings.toml" ]; then
    cp "$HOME/.warp/settings.toml" "$HOME/.warp/settings.toml.bak.$(date +%s)"
    say "backed up existing Warp settings.toml"
  fi
  cp "$REPO_DIR/warp/settings.toml" "$HOME/.warp/settings.toml"
  say "installed Warp settings (option key sends Meta). Restart Warp to apply."
else
  say "skipped Warp settings (set SKIP_WARP=0 and install Warp to enable)"
fi

say "done. Start tmux, or reload with:  tmux source ~/.config/tmux/tmux.conf"
