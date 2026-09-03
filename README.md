# Glazier

A Hyprland + [quickshell](https://quickshell.org/) desktop config: `hypr/hyprland.lua`
plus `quickshell/ii`, a modified fork of [end-4's `dots-hyprland`](https://github.com/end-4/dots-hyprland)
shell, and `quickshell/matugen`, its Material You theming templates.

Licensed GPL-3.0 as a whole, as a derivative work of end-4's project — see `LICENSE`
and `CREDITS.md` for the handful of bundled files under other licenses.

![screenshot](docs/screenshot.png)
<!-- Replace with an actual screenshot before publishing. -->

## What's ours vs. upstream

`quickshell/ii` and `quickshell/matugen` are a frozen file copy of end-4's tree at a
pinned commit, not a submodule or a flake input — see `quickshell/UPSTREAM` for the
exact commit, the refetch procedure, and the full changelog of local divergences.
Recent ones, as an idea of what "ours" means in practice:

- A Wi-Fi hotspot quick toggle, added end-to-end (service, model, toggle widgets,
  dialog) — upstream has no hotspot control at all.
- The weather backend swapped from wttr.in to Open-Meteo: wttr.in's free-text city
  lookup was resolving Portuguese civil parishes to the wrong municipality.
- A new "Widgets" tab in the left sidebar (media/weather/news/resources cards),
  entirely new files plus three small edits to upstream ones.
- The static-wallpaper path now also drives Hyprland's own `hyprpaper` layer, so the
  compositor's background and the shell's stay in sync.

`hypr/hyprland.lua`'s `general`/`decoration`/`animations` block is adapted from
end-4's own `hypr/hyprland/general.lua` — the values, not their file layout (their
`hypr/` tree assumes Arch and machine-written env, which this project doesn't adopt).

## Layout

```
hypr/
  hyprland.lua      Hyprland Lua config: binds, look and feel, LOCAL OVERRIDES
quickshell/
  UPSTREAM           provenance, refetch procedure, changelog of local divergences
  ii/                the shell itself (vendored + modified)
  matugen/           Material You theming templates (vendored + modified)
```

## Using this on a machine

This repo is delivered by a NixOS home-manager config as an out-of-store symlink
(`~/.config/hypr/hyprland.lua` → `hypr/hyprland.lua`, `~/.config/quickshell/ii` →
`quickshell/ii`, same for `matugen`), so the QML and Lua can be edited live and the
compositor/shell pick up the change immediately — editing hot and keeping it in git
are the same act. That wiring — dependency wrapping, systemd service, per-host
overrides — lives in the consuming config, not here. See its `home/hyprland.nix` and
`home/quickshell.nix` for the exact symlink targets.

**Bootstrap on a new machine:** clone this repo before the first
`nixos-rebuild switch`. Without it, home-manager creates dangling symlinks and the
desktop comes up with no config — no error, just an empty session.

### `hypr/local.lua` — your machine's identity

`hypr/hyprland.lua` is deliberately generic: no hostname branching, no hardcoded
monitor layout or keyboard layout. Machine-specific overrides load from
`~/.config/hypr/local.lua`, which this repo does **not** provide — it's meant to be
delivered by whatever config consumes this repo, one file per host. Minimal example:

```lua
hl.monitor({ output = "DP-2", mode = "1920x1080@60", position = "0x0", scale = "1" })
hl.config({ input = { kb_layout = "us" } })
```

It's loaded last, in `hyprland.lua`'s `LOCAL OVERRIDES` block, alongside two other
optional layers, from least to most authoritative:

1. `hypr/local.lua` — you, or your consuming config.
2. `hypr/hyprland/monitors.lua` — machine-written. Meant to be a snapshot of
   `hyprctl monitors`, refreshed by a `wdisplays`-drag-then-save workflow, so a GUI
   layout change is the last word over the declarative one above it.
3. `hyprland/colors.lua` — machine-written by `matugen` on every wallpaper change.

All three are loaded with `pcall`, so a fresh install with none of them present
degrades to the generic catch-all monitor block and default colors — not a crash.

## Dependencies

None of this is installed by this repo — it assumes a consuming config provides
everything below. Grouped by what actually needs it:

**Runtime binaries** (35, on the shell process's `PATH`, not the interactive
user's): theming — `matugen`, `imagemagick`; the shell's utility belt — `jq` (the
single most-used binary here), `bc`, `curl`, `libnotify`, `glib`, `procps`,
`systemd`, `xdg-utils`, `coreutils`; hardware/session — `brightnessctl`, `ddcutil`
(external monitor brightness over DDC/CI), `upower`, `networkmanager`,
`pulseaudio`, `wireplumber`, `playerctl`, `cava`; capture/pointing — `grim`,
`slurp`, `swappy`, `hyprpicker`, `hyprsunset`, `wf-recorder`, `ffmpeg`,
`tesseract` + `translate-shell` (the screen translator), `wl-clipboard`,
`cliphist`, `ydotool`, `wtype`; misc — `libqalculate` (`qalc`, the launcher's
calculator), `fuzzel`, `libsecret` (AI key storage).

**QML modules** quickshell itself doesn't ship: `Qt5Compat.GraphicalEffects`,
`org.kde.kirigami`, `org.kde.syntaxhighlighting`, `QtPositioning`. Trap worth
knowing if you package this yourself: on Nix, `kdePackages.kirigami` is a wrapper
derivation with no QML in it — the real modules are in `kirigami.unwrapped`.

**Python** (10 packages, run through a venv-shaped shim rather than a bare
interpreter — see the note below): `materialyoucolor` (the HCT/Material You
palette generator), `opencv4` + `pillow` + `numpy` (wallpaper region detection,
thumbnails), `loguru`, `tqdm`, `click`, `pygobject3` (thumbnail generation via
GdkPixbuf), `google-auth` + `google-auth-oauthlib` (AI service auth). Trap: the
scripts' shebang does `source $ILLOGICAL_IMPULSE_VIRTUAL_ENV/bin/activate`, which
doesn't exist for a plain Nix Python environment — whatever wires this up needs to
fabricate that `activate` shim and set the variable.

**Fonts** (7): `material-symbols` is **structural, not cosmetic** — this shell
draws every icon from that font's glyph range rather than shipping SVGs for
chrome; without it the bar, sidebars and launcher render empty boxes. Plus two
Nerd Font variants (FiraCode, JetBrains Mono, for terminal/status-bar glyphs),
`readexpro`, `rubik`, `twemoji-color-font`, and Space Grotesk.

**Process environment the launcher must set:** `QT_QPA_PLATFORMTHEME=gtk3` — without
a platform theme, `QIcon::fromTheme` falls back to an empty `hicolor` and every
icon lookup fails silently, with no error anywhere. `QT_PLUGIN_PATH` needs Qt's
image format plugins for thumbnails to render. `QML2_IMPORT_PATH` needs the QML
modules above.

**System services**, for full functionality: Bluetooth (`bluez`) and `upower`, or
the battery/Bluetooth widgets go dead silently; `geoclue2`, with an explicit
allow+`isSystem` grant for the shell's app ID — without it, location clamps to
city-level accuracy regardless of what Wi-Fi positioning can actually resolve,
and the weather widget is wrong without ever erroring.

## Credits

See `CREDITS.md` for the full breakdown of upstream attribution and bundled
third-party licenses.

## Glossary

A few `ADR-NNNN` / `TM-NNNN` references remain in code comments, pointing at
design decisions recorded in a private knowledge base (not this repo). Kept
rather than stripped, because a comment explaining *why* is worth more than one
that doesn't — even if the doc it points to isn't public. What each one is about:

| Ref | Decision |
|---|---|
| ADR-0001 | Quickshell as the shell layer |
| ADR-0002 | Home Manager as the sole dotfile manager |
| ADR-0009 | Vendored fork of end-4 |
| ADR-0010 | Theming governed by end-4 |
| TM-0001 | Desktop shell — requirements |
| TM-0002 | end-4 bring-up |
