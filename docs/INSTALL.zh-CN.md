# 安装与恢复

## 适用范围

本仓库以 Ubuntu 26.04、Hyprland 0.56 为实机基线。它不负责安装 Hyprland
本体，安装前应已有可登录的 Hyprland 会话。

核心程序：Hyprland、Waybar、Hyprpaper、Hyprlock、Hypridle、SwayNC、
Hyprlauncher、Ghostty、Nautilus。可选功能使用 Kitty、Wiremix、nmtui、
bluetui、wlogout、hyprshot、playerctl 和 wpctl。

## 安装

~~~bash
./scripts/validate.sh
./scripts/install.sh
after-rain-doctor
~~~

脚本会先备份 ~/.config/{hypr,waybar,swaync,ghostty,kitty}，随后安装文件并
热重载桌面。退出再登录一次，令输入法与 Wayland 环境变量完整生效。

## 显示器

公共配置使用可移植的自动模式。当前 3440×1440 显示器可在
~/.config/hypr/local.conf 中启用：

~~~ini
monitor = HDMI-A-1, 3440x1440@60, 0x0, 1
~~~

机器专属文件不进入 Git。

## 恢复

安装结束时会输出类似下面的命令：

~~~bash
./scripts/restore.sh ~/.local/state/after-rain-hyprland/backups/TIMESTAMP
~~~

恢复脚本在覆盖前还会再创建一份 pre-restore 安全副本。

## 发布前

~~~bash
./scripts/validate.sh
git status --short
~~~

不要提交 .env、local.conf、令牌、内网地址或原游戏仓库的内部文件。
