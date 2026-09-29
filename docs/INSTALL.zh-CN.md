# 安装与恢复

## 适用范围

本仓库以 Ubuntu 26.04、Hyprland 0.56 为实机基线。它不负责安装 Hyprland
本体，安装前应已有可登录的 Hyprland 会话。

核心程序：Hyprland、Waybar、Hyprpaper、Hyprlock、Hypridle、SwayNC、
SwayOSD、GTK4/PyGObject、Ghostty、Nautilus。Hyprlauncher 仅作为轻量后备与
dmenu 提供者。可选功能使用 Kitty、Wiremix、nmtui、
bluetui、wlogout、hyprshot、playerctl 和 wpctl。

## 安装

~~~bash
./scripts/validate.sh
./scripts/install.sh
after-rain-doctor
~~~

脚本会以 0700 权限备份受管理的配置和所有 `after-rain-*`/`rainlight` 命令，
随后事务式安装文件并热重载桌面。任一步失败都会按清单自动恢复安装前的“存在”
或“不存在”状态。Hyprland 只在进程启动时选择 Lua 或旧 Hyprlang provider；从旧
配置升级后必须退出并重新登录 Hyprland，`hyprctl reload` 不能完成 provider 切换。

## 显示器

公共配置使用可移植的自动模式。当前 3440×1440 显示器可在
`~/.config/hypr/after_rain_local.lua` 中启用：

~~~lua
return {
    monitors = {
        { output = "HDMI-A-1", mode = "3440x1440@100", position = "0x0", scale = 1 },
    },
}
~~~

该显示器实测会公布 100 Hz；如果链路不稳定，删掉本行回到 `preferred`。机器专属
文件不进入 Git。

## 自定义 XDG 目录与无运行时安装

安装器尊重 `XDG_CONFIG_HOME`、`XDG_STATE_HOME` 和 `AFTER_RAIN_BIN_ROOT`，
并会改写 Hyprland 内部配置引用。打包或测试环境可以使用：

~~~bash
AFTER_RAIN_SKIP_RUNTIME=1 ./scripts/install.sh
~~~

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

不要提交 .env、local.conf、after_rain_local.lua、令牌、内网地址或原游戏仓库的内部文件。
