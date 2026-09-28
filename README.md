# After Rain Hyprland

An opinionated, reversible Hyprland desktop for Ubuntu: rainy visual-novel art,
semantic color roles, compact glass surfaces and practical keyboard-first workflows.

![After Rain Hyprland desktop](assets/preview.png)

![Rainlight launcher](assets/rainlight-preview.png)

> Independent community project inspired by Omarchy's design discipline. This
> repository is not affiliated with, endorsed by, or part of Omarchy or Hyprland.

## What is included

- Modular Hyprland 0.56 configuration with a machine-local override
- **Rainlight**, a custom GTK4 launcher with app, file, web, command, calculator,
  workspace and wallpaper search modes
- Workspace-aware character art: Super+1 through Super+4 select Lin Wan, Aoi
  Takamori, Seo Ji-an and Clara Reed
- Floating-pill Waybar and matching SwayNC notification center
- Hyprlock, Hypridle, Hyprpaper, SwayOSD, Wlogout and four ultrawide artworks
- Matching Ghostty, Kitty, GTK3/4, btop and Hyprtoolkit palettes
- Transactional backup/install/restore, diagnostics, asset verification, CI and
  working-tree plus Git-history secret scanning

The visual system follows one rule: themes are data, components consume semantic
roles. The canonical palette is [colors.toml](themes/after-rain/colors.toml).

## Install

Review the files first, then run:

~~~bash
./scripts/install.sh
~~~

The installer validates the repository, creates a timestamped backup under
~/.local/state/after-rain-hyprland/backups/, installs the configuration, reloads
the live desktop and prints the exact rollback command.

Run **after-rain-doctor** after installation. Log out and back in once so session
environment variables are applied consistently.

For details, see [中文安装说明](docs/INSTALL.zh-CN.md),
[快捷键](docs/KEYBINDINGS.zh-CN.md), [架构](docs/ARCHITECTURE.zh-CN.md),
[主题定制](docs/THEMING.zh-CN.md), and
[theme research notes](docs/DESIGN-NOTES.zh-CN.md).

![After Rain lock screen](assets/lockscreen-preview.png)

## License

Code and documentation are MIT licensed. Artwork has separate terms in
[ASSETS.md](LICENSES/ASSETS.md); the MIT license does not cover it.
