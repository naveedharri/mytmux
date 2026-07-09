# mytmux

**In simple words:** this is the easiest way to lay out your terminal for running
multiple AI agents at once. You split one window into several panes (split screens),
run a Claude/agent session in each, and zoom into whichever one you're focused on
without losing sight of the others. One command sets it all up, and the same layout,
keybindings, and zoom behavior follow you to any machine. It's built for agentic work:
watch many agents side by side, jump between them fast, and blow one up big when you
need to read it.

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
| `scripts/zoom-cycle.sh`      | `~/.config/tmux/scripts/`             | focus zoom: active pane big, others as a side list (Cmd+l) |
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
- `M-0` cycle to next pane (loops), `M-9` toggle a big zoom of the active pane

Cmd-key equivalents are routed through Karabiner (Cmd -> Option+key inside Warp),
so on this machine Cmd+k = `M-0` (cycle) and Cmd+l = `M-9` (zoom).

## Pane zoom

`zoom-cycle.sh` is a softer alternative to `M-z` fullscreen. Cmd+l (`M-9`) toggles
the window into a **main-vertical** layout: the **active** pane becomes one big pane
on the left, and every other pane lines up as a readable vertical list down the
right. Press Cmd+l again — or switch panes (Cmd+k, `M-h/j/k/l`, arrows, a mouse
click) — to restore the exact previous layout, wired via an `after-select-pane[99]`
hook so it never clobbers other hooks. There are deliberately no intermediate
levels: one press, one useful focus view.

A layout swap is used instead of resizing panes in place because shrinking panes
inside a grid makes them narrow, and terminal TUIs (Claude Code especially) reflow
badly when narrow — every word wraps onto its own line and the background panes look
broken. The list keeps each background pane a full-height slice wide enough to render
cleanly. The focused pane's width share is `MAIN_FRAC` in the script (default `0.72`);
raise it for more focus at the cost of a narrower list. No patched tmux, no plugin.

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
