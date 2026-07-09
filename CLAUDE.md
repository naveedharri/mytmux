# mytmux — instructions for Claude Code

This repo is a portable tmux setup. When the user clones it onto a new machine
and asks you to "apply my tmux settings" / "set up tmux", do the following.

## Apply the setup

Run the installer. It is idempotent and backs up any existing config first:

```bash
cd "$(git rev-parse --show-toplevel)" && ./install.sh
```

If the user prefers manual steps, or the installer fails, do exactly what it does:

1. Ensure `tmux` is installed (`brew install tmux` on macOS).
2. Clone the framework if missing:
   `git clone https://github.com/gpakosz/.tmux.git ~/.local/share/oh-my-tmux`
3. `mkdir -p ~/.config/tmux/scripts`
4. Symlink: `ln -sf ~/.local/share/oh-my-tmux/.tmux.conf ~/.config/tmux/tmux.conf`
5. Copy this repo's `tmux.conf.local` → `~/.config/tmux/tmux.conf.local`
6. Copy `scripts/pane-graveyard.sh` → `~/.config/tmux/scripts/` and `chmod +x` it
7. Copy `warp/settings.toml` → `~/.warp/settings.toml` (only if Warp is installed;
   back up the existing one first). Restart Warp so option-as-Meta takes effect.
8. Reload: `tmux source ~/.config/tmux/tmux.conf`

## Important details

- Config lives under XDG path `~/.config/tmux/`, NOT `~/.tmux.conf`.
- `tmux.conf.local` is the only file the user edits. The framework `.tmux.conf`
  (the symlink target) is upstream and should stay unmodified.
- Bindings are mostly prefix-less `M-` (Meta/option) chords. On macOS terminals
  the option key must send Meta or the bindings do nothing. The included Warp
  `settings.toml` sets `extra_meta_keys = { left_alt = true, right_alt = false }`.
  For other terminals (iTerm2, Ghostty, Terminal.app), enable "use option as Meta"
  in that terminal's settings.
- `pane-graveyard.sh` is referenced from `tmux.conf.local` via `~/.config/tmux/scripts/…`
  (portable, no absolute user path), so it works on any machine once copied.

## Syncing changes back

If the user changes their live config and wants it saved, copy the live files
back into this repo, then commit and push (ask before pushing):

```bash
cp ~/.config/tmux/tmux.conf.local           tmux.conf.local
cp ~/.config/tmux/scripts/pane-graveyard.sh scripts/
cp ~/.warp/settings.toml                     warp/settings.toml
```
