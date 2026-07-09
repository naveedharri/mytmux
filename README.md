# mytmux

My portable tmux setup. Clone on any new machine, run one command, and my exact
tmux config, keybindings, custom scripts, and Warp terminal settings are applied.

Built on [Oh My Tmux](https://github.com/gpakosz/.tmux) (gpakosz/.tmux). This
repo only carries the customizations on top of it plus an installer that wires
everything together.

## One-line install

```bash
git clone https://github.com/naveedharri/mytmux.git ~/Downloads/mytmux
cd ~/Downloads/mytmux && ./install.sh
```

Or without cloning first:

```bash
curl -fsSL https://raw.githubusercontent.com/naveedharri/mytmux/develop/install.sh | bash
```

## What gets installed

| File                         | Installed to                          | What it is                                             |
| ---------------------------- | ------------------------------------- | ------------------------------------------------------ |
| (cloned) gpakosz/.tmux       | `~/.local/share/oh-my-tmux`           | Oh My Tmux framework                                   |
| symlink                      | `~/.config/tmux/tmux.conf`            | points at the framework `.tmux.conf`                   |
| `tmux.conf.local`            | `~/.config/tmux/tmux.conf.local`      | my customizations (bindings, status bar, options)      |
| `scripts/pane-graveyard.sh`  | `~/.config/tmux/scripts/`             | "undo close pane" — buries panes instead of killing    |
| `scripts/pulse-border.sh`    | `~/.config/tmux/scripts/`             | animates the active pane border through a cyan gradient |
| `warp/settings.toml`         | `~/.warp/settings.toml`               | Warp prefs, incl. option-as-Meta so `M-` bindings work |

Existing `tmux.conf.local` and Warp `settings.toml` are backed up (`.bak.<timestamp>`)
before being overwritten. Skip the Warp step with `SKIP_WARP=1 ./install.sh`.

## Key bindings (from tmux.conf.local)

Prefix is remapped: `M-b` sends prefix (option+b). Most actions are prefix-less
`M-` (option) chords, which is why the Warp option-as-Meta setting matters.

- `M-t` new window, `M--` split top/bottom, `M-\` split left/right
- `M-h/j/k/l` move between panes, `M-1`..`M-5` jump to window
- `M-z` zoom pane, `M-n` new tiled split, `M-x` kill pane (confirm)
- `M-q` / `M-p` bury current pane (recoverable), `M-r` restore last buried pane

## Pane graveyard

`pane-graveyard.sh` gives "undo close pane". Instead of killing a pane (which
kills its process), it moves the pane into a detached `_graveyard` session so the
running program (e.g. a live Claude session) keeps going and can be pulled back
exactly as it was.

## Animated pane border

`pulse-border.sh` runs a background loop that breathes the active pane border
through a cyan gradient (~1.5s per breath) for a subtle "alive" neon effect. It
kills any prior loop on reload to avoid duplicates and exits when the tmux server
is gone. The mode-aware conditional still wins: the border turns green in copy
mode and coral when panes are synchronized. It's launched from `tmux.conf.local`
via `run -b 'sh ~/.config/tmux/scripts/pulse-border.sh'`.

## Applying updates later

After editing config locally, copy it back into the repo and push:

```bash
cp ~/.config/tmux/tmux.conf.local  ~/Downloads/mytmux/tmux.conf.local
cp ~/.config/tmux/scripts/*.sh ~/Downloads/mytmux/scripts/
cp ~/.warp/settings.toml ~/Downloads/mytmux/warp/settings.toml
cd ~/Downloads/mytmux && git add -A && git commit -m "update config" && git push
```
