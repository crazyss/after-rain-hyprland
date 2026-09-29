# 主题定制

## 修改颜色

只编辑 `themes/after-rain/colors.toml`。颜色必须是六位十六进制；建议保持：

- `background` 最暗，承担桌面与终端底色；
- `surface` / `surface_high` 形成两级玻璃面；
- `foreground` 与背景保持高可读性；
- `accent` 用于焦点、选择与链接；
- `accent_warm` 只作少量暖色提示；
- `urgent` 仅用于错误和危险动作。

生成并验证：

~~~bash
./scripts/render-theme.py
./scripts/validate.sh
~~~

不要直接编辑任何 `colors.css`、`05-theme.conf`、终端配色或 btop 主题；下一次
渲染会覆盖它们。

## 更换角色壁纸

将 PNG 放入 `assets/wallpapers/`，保持文件名前缀 `01` 到 `04` 的角色顺序，
更新 `assets/manifest.yml` 的 SHA-256。壁纸须为真正的超宽场景，宽高比至少 2.2，
并且不得含 PNG 文本/EXIF 块。运行：

~~~bash
sha256sum assets/wallpapers/*.png
./scripts/verify-assets.py
~~~

如果改变角色顺序，同时更新 `after-rain-workspace`、快捷键描述和文档。

## 本机覆盖

显示器与默认程序写在 `~/.config/hypr/after_rain_local.lua`，不要改公共模块。
该文件不会被 Git 跟踪，也不会在后续升级中覆盖。旧 provider 的 `local.conf`
只保留在回滚路径中。
