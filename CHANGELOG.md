# Changelog

## Unreleased

- Migrated the canonical Hyprland 0.56 configuration to modular Lua while retaining
  the old Hyprlang files for one rollback cycle.
- Added a complete searchable GTK4 keybinding browser backed by live
  `hyprctl -j binds`, available on Super+F1 and Super+Shift+K.
- Added the Omarchy 4 gap analysis and staged Quickshell architecture plan.
- Documented the host-side LibPinyin Lua-extension switch that captured `i` for
  its built-in minor mode.
- Added the first-party Quickshell MVP foundation with typed IPC, a searchable
  live keybinding overlay, generated theme tokens and GTK fallback.
- Added a pinned, reproducible Quickshell 0.3.1 source build for a user-local
  prefix, plus a Hyprland-only user service and generic-session isolation.
- Hardened first-login startup by importing the Hyprland systemd environment
  before service activation and requiring the typed IPC health check to pass.
- Fixed Hyprland 0.56 Lua-provider dispatches for workspace switching, DPMS and
  logout, and made Ctrl+Space recover a missing IBus daemon before switching.
- Added deterministic regression coverage for IBus offline recovery and
  English/LibPinyin switching.

## 0.2.0 — 2026-09-29

- Added Rainlight, a custom GTK4 search and command palette with seven modes.
- Added workspace-aware character wallpapers for workspaces 1 through 4.
- Added a Hyprland-owned Ctrl+Space English/LibPinyin toggle and race-free IBus startup.
- Added a clickable EN/中 input-method indicator to Waybar.
- Replaced the resident Hyprlauncher daemon with Rainlight; Hyprlauncher remains an on-demand dmenu backend.
- Added a canonical theme renderer covering Hyprland, Waybar, SwayNC, SwayOSD,
  Wlogout, Hyprtoolkit, Ghostty, Kitty, GTK and btop.
- Added transactional install/restore, custom-XDG integration coverage, asset
  verification, stronger secret scanning and pinned CI actions.
- Replaced character sheets with real ultrawide scene wallpapers and added live
  desktop and lock-screen previews.

## 0.1.0 — 2026-09-28

- Initial independent Ubuntu/Hyprland release.
- Added the After Rain semantic palette and four adult-character artworks.
- Added reversible installation, validation, diagnostics and secret scanning.
