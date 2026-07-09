# mytmux

My portable tmux setup. Clone on any new machine, run one command, and my exact
tmux config, keybindings, custom scripts, and Warp terminal settings are applied.

Built on [Oh My Tmux](https://github.com/gpakosz/.tmux) (gpakosz/.tmux). This
repo only carries the customizations on top of it plus an installer that wires
everything together.

## Install (single source of truth — recommended)

Clone once to a stable home and run in **link mode**. This symlinks your live
tmux config at the checkout, so editing here or running `git pull` changes your
tmux setup directly. Settings live in one place, loaded straight from GitHub.

```bash
git clone https://github.com/naveedharri/mytmux.git ~/.config/mytmux
cd ~/.config/mytmux && ./install.sh link
```

Update any machine later with just:

```bash
cd ~/.config/mytmux && git pull && tmux source ~/.config/tmux/tmux.conf
```

## Install (copy mode)

If you'd rather have independent copies instead of symlinks:

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
| `scripts/zoom-cycle.sh`      | `~/.config/tmux/scripts/`             | leveled progressive zoom of the active pane (Cmd+l)    |
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
- `M-0` cycle to next pane (loops), `M-9` leveled progressive zoom of active pane

Cmd-key equivalents are routed through Karabiner (Cmd -> Option+key inside Warp),
so on this machine Cmd+k = `M-0` (cycle) and Cmd+l = `M-9` (zoom).

## Leveled zoom

`zoom-cycle.sh` is a softer alternative to `M-z` fullscreen. Each Cmd+l (`M-9`)
press grows the **active** pane one level (5 levels; the 6th press wraps back to
the even layout, same loop feel as the Cmd+k pane cycle). Every other pane stays
visible and interactive the whole time — at level 5 the active pane takes ~7/8 of
the window in each axis and the rest share the remaining strip. Moving focus to
another pane (Cmd+k, `M-h/j/k/l`, arrows, or a mouse click) collapses the zoom back
to the even layout, wired via an `after-select-pane[99]` hook so it never clobbers
other hooks. No patched tmux and no plugin: it just steps `resize-pane` in small
increments (~100ms) so the change reads as a smooth glide.

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

In link mode (the recommended install) your live `tmux.conf.local` and
`scripts/*.sh` are symlinks into this checkout, so editing them edits the repo
directly. No copying. Every tmux change goes through GitHub like this:

```bash
# edit ~/.config/tmux/tmux.conf.local or ~/.config/tmux/scripts/*.sh
cd ~/.config/mytmux
git add -A && git commit -m "update config" && git push
tmux source ~/.config/tmux/tmux.conf     # apply to the running session
```

Warp's `settings.toml` is the one exception: it is copied, not symlinked. If you
changed Warp prefs, copy that file back before committing (restart Warp to apply):

```bash
cp ~/.warp/settings.toml ~/.config/mytmux/warp/settings.toml
```
