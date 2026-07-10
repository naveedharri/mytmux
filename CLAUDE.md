# mytmux — instructions for Claude Code

This repo is a portable tmux setup. When the user clones it onto a new machine
and asks you to "apply my tmux settings" / "set up tmux", do the following.

## Rule: this repo IS the live config — always edit here

On Naveed's machine the live tmux files are **symlinked** into this checkout
(`install.sh link`): `~/.config/tmux/tmux.conf.local` and
`~/.config/tmux/scripts/*.sh` point at `~/.config/mytmux/...`. So any request to
change a tmux setting, keybinding, colour, script, or Warp config must be made by
editing the files in THIS repo (`~/.config/mytmux/`), never by editing the
`~/.config/tmux/` symlinks or hand-tweaking the running server. Then:

1. `git add -A && git commit` in this repo (simple one-line message, no co-author).
2. Ask Naveed before `git push`.
3. Reload the live config so a running session picks it up:
   `tmux source ~/.config/tmux/tmux.conf`.

If a machine was set up with copy mode instead of `link`, run `./install.sh link`
first so edits here flow through, or copy the files back (see "Syncing changes back").

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
6. Copy every `scripts/*.sh` → `~/.config/tmux/scripts/` and `chmod +x` them
   (currently `claude-recover.sh`, `pane-namer.sh`, `pulse-border.sh`, `zoom-cycle.sh`)
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
- Scripts are referenced from `tmux.conf.local` via `~/.config/tmux/scripts/…`
  (portable, no absolute user path), so they work on any machine once copied.
- `pulse-border.sh` is launched in the background (`run -b`) from `tmux.conf.local`
  and animates the active pane border. It self-guards against duplicate loops on
  reload and exits when the server dies, so re-sourcing the config is safe.

## Syncing changes back

This machine is installed in link mode: `~/.config/tmux/tmux.conf.local` and each
`~/.config/tmux/scripts/*.sh` are symlinks into this checkout. Editing the live
files edits the repo directly, so tmux changes need no copy step. Just commit and
push from the checkout (ask before pushing):

```bash
cd ~/.config/mytmux
git add -A && git commit -m "update config" && git push
```

Only `~/.warp/settings.toml` is a copy, not a symlink. If Warp prefs changed, copy
it back first:

```bash
cp ~/.warp/settings.toml ~/.config/mytmux/warp/settings.toml
```

(If a machine was set up in copy mode instead, `tmux.conf.local` and `scripts/*.sh`
are plain copies and must be copied back the same way.)
