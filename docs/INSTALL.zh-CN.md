# 安装与恢复

## 适用范围

本仓库以 Ubuntu 26.04、Hyprland 0.56 为实机基线。它不负责安装 Hyprland
本体，安装前应已有可登录的 Hyprland 会话。

核心程序：Hyprland、Waybar、Hyprpaper、Hyprlock、Hypridle、SwayNC、
SwayOSD、GTK4/PyGObject、Ghostty、Nautilus。Hyprlauncher 仅作为轻量后备与
dmenu 提供者。可选功能使用 Kitty、Wiremix、nmtui、
bluetui、wlogout、hyprshot、playerctl 和 wpctl。

统一 Shell 基座使用从上游固定 tag 编译的 Quickshell 0.3.1。源码、构建目录和
缺失开发包的用户级解包缓存都位于 `~/src/quickshell-v0.3.1`；最终程序安装到
`~/.local`，不写 `/usr/local`，也不增加长期第三方 APT 源。

## 安装

~~~bash
./scripts/build-quickshell.sh
./scripts/validate.sh
./scripts/install.sh
after-rain-doctor
~~~

脚本会以 0700 权限备份受管理的配置和所有 `after-rain-*`/`rainlight` 命令，
随后事务式安装文件并热重载桌面。任一步失败都会按清单自动恢复安装前的“存在”
或“不存在”状态。Hyprland 只在进程启动时选择 Lua 或旧 Hyprlang provider；从旧
配置升级后必须退出并重新登录 Hyprland，`hyprctl reload` 不能完成 provider 切换。
安装器会用 systemd 条件 drop-in 把 Waybar、SwayNC、SwayOSD、Hypridle、
Hyprpaper 与 Hyprpolkitagent 隔离到存在 `HYPRLAND_INSTANCE_SIGNATURE` 的会话；
它们仍由 Hyprland Lua 按需启动，不会再在 GNOME 会话里崩溃重启或争夺通知服务。

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

## 快捷键 Profile

内置 `standard`、`zh-pinyin` 和 `minimal`。在不会被安装器覆盖的
`~/.config/hypr/after_rain_local.lua` 中选择：

~~~lua
return {
    binding_profile = "zh-pinyin",
}
~~~

保存后运行 `hyprctl reload`。完全自定义时将 profile 设为 `custom`，再复制并编辑：

~~~bash
cp ~/.config/hypr/after_rain_bindings.lua.example \
  ~/.config/hypr/after_rain_bindings.lua
hyprctl reload
~~~

完整键位与安全规则见[快捷键 Profile 设计](KEYBINDING-PROFILES.zh-CN.md)。

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
