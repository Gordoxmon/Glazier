# Glazier

Hyprland + quickshell desktop config. `hypr/` is the Hyprland Lua config;
`quickshell/` is a vendored fork of end-4's `ii` shell plus `matugen`
theming templates.

Machine-specific bits (monitor layout, keyboard layout) are NOT here — they
live in the consuming NixOS config as `hypr/local.lua`, loaded by
`hypr/hyprland.lua`'s LOCAL OVERRIDES block at runtime. This repo stays
generic.

Delivered via out-of-store symlinks from a NixOS home-manager config
(`home/hyprland.nix`, `home/quickshell.nix`) — that repo owns dependency
wrapping, services, and the per-host layer. This repo is edited live; the
symlink target IS the working tree, so hot edits and git history are the
same act.

Real documentation (dependencies, licensing, credits) is deferred until
this repo is published.
