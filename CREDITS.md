# Credits

Glazier is licensed under GPL-3.0 as a whole (see `LICENSE`). This file lists
where each part came from, and the more restrictive terms that apply to a few
individual files bundled inside the GPL-3.0 tree.

## The base

| Component | Source | License |
|---|---|---|
| `quickshell/ii`, `quickshell/matugen` | [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) @ [`42d0aae`](https://github.com/end-4/dots-hyprland/commit/42d0aae17b744a38cd05c9044c189bfc9b13869a) | GPL-3.0 |
| `hypr/hyprland.lua` — `general`/`decoration`/`animations` block | adapted from the same project's `dots/.config/hypr/hyprland/general.lua` | GPL-3.0 |

See `quickshell/UPSTREAM` for the exact vendoring commit, the refetch procedure,
and everything that has diverged from it since.

## Bundled third-party components

These files carry their own license, separate from and more permissive than
the GPL-3.0 that covers the rest of the tree. Each is reproduced in `licenses/`.

| Component | License | Notes |
|---|---|---|
| `quickshell/ii/modules/common/widgets/shapes/` | Apache-2.0 | [end-4/rounded-polygon-qmljs](https://github.com/end-4/rounded-polygon-qmljs) @ `e31ec4c`, vendored as a submodule upstream. `LICENSE` ships in-tree at that path. |
| `quickshell/ii/modules/common/functions/fuzzysort.js` | MIT, © 2018 Stephen Kamenar | [farzher/fuzzysort](https://github.com/farzher/fuzzysort). `licenses/MIT-fuzzysort.txt`. |
| `quickshell/ii/scripts/thumbnails/thumbgen.py` | MIT, © 2019 Functional Paradigms Pvt Ltd | [difference-engine/thumbnail-generator-ubuntu](https://github.com/difference-engine/thumbnail-generator-ubuntu). `licenses/MIT-thumbgen.txt`. |
| `quickshell/matugen/templates/ags/sourceviewtheme.xml` | LGPL-2.1-or-later, © 2014 Leo Iannacone | `licenses/LGPL-2.1.txt`. |
| `quickshell/ii/assets/icons/fluent/{start-here,search,task-view}*` | CC BY 4.0 | [Windows 11 icon set by Joshua Oghenekaro Okwe](https://www.figma.com/community/file/1123040825921884189/windows-11) (Figma), with modifications — see `quickshell/ii/assets/icons/fluent/README.md`. `licenses/CC-BY-4.0.txt`. The rest of `fluent/` is end-4's own GPL-3.0 tree. |
| `quickshell/ii/assets/icons/fedora-symbolic.svg` | CC BY 4.0 (icon), © 2022 Fonticons, Inc. | Font Awesome Free 6.2.1. `licenses/CC-BY-4.0.txt`. |

## Credited-in-file (GPL-3.0, no separate obligation)

These were adapted from other GPLv3 projects and already carry their own
attribution comment at the top of the file. They're covered by the same
GPL-3.0 as the rest of the tree, listed here for completeness rather than as
a distinct obligation.

- `quickshell/ii/modules/common/Icons.qml`, `services/Network.qml` — from
  [caelestia-dots/shell](https://github.com/caelestia-dots/shell)
- `quickshell/ii/modules/common/widgets/DirectoryIcon.qml`,
  `services/Brightness.qml`,
  `quickshell/ii/modules/common/functions/levendist.js` — GPLv3, per their
  own file headers
- `quickshell/ii/defaults/ai/` — the Acchan avatar is from
  [NyarchLinux/NyarchAssistant](https://github.com/NyarchLinux/NyarchAssistant)
  (GPLv3), see `quickshell/ii/defaults/ai/README.md`
