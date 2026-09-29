# 故障排查

先运行：

~~~bash
after-rain-doctor
hyprctl configerrors
~~~

## Super+E 没反应

确认 `nautilus` 存在，并检查 `hyprctl binds | grep -A4 'key: E'`。默认关闭窗口
为 **Super+C**，同时保留 **Super+Q** 兼容别名。

## Super+Space 没有搜索框

执行 `rainlight` 查看终端错误。Rainlight 需要 Python 3、GTK4 和 PyGObject；
Ubuntu 对应包通常是 `python3-gi` 与 `gir1.2-gtk-4.0`。配置位于
`~/.config/rainlight/`。

## 中文模式按 i 出现扩展候选

LibPinyin 把 `i` 定义为中文数字/Lua 扩展 minor mode，这不是 Hyprland 的裸键
绑定。关闭 Lua 扩展：

~~~bash
gsettings set com.github.libpinyin.ibus-libpinyin.libpinyin lua-extension false
gsettings get com.github.libpinyin.ibus-libpinyin.libpinyin lua-extension
~~~

恢复本机修改前状态可把值设回 `true`。关闭后 `i` 仍可能出现中文数字候选，属于
LibPinyin 同一个内建 minor mode。若看到的是独立应用窗口，再在 Hyprland 会话中
检查 `hyprctl -j binds`、`hyprctl -j clients` 和 `hyprctl -j layers`。

## Lua 配置没有生效

确认 `~/.config/hypr/hyprland.lua` 已安装，然后退出并重新登录 Hyprland。
`hyprctl reload full-reset` 能切换 provider，但正常升级优先重新登录。验证：

~~~bash
hyprctl version
hyprctl configerrors
hyprctl -j binds | jq '.[] | select(.description != "")'
~~~

## 工作区没有换壁纸

检查：

~~~bash
pgrep -af '^python3 .*/after-rain-workspace watch$'
after-rain-workspace sync
hyprctl hyprpaper listactive
~~~

`after-rain-reload` 会只重启当前 Hyprland 会话的监听器和桌面组件，不会广泛
杀死其他会话。

## 图标显示为方框

运行 `fc-match FontAwesome`。Waybar 和 Rainlight 使用 FontAwesome 4 范围内的
图标，并以 Noto Sans CJK SC 回退中文。字体缺失时先安装对应发行版字体包。

## 新会话没有 IBus 输入法

配置会在每个 Hyprland 会话执行 `after-rain-ibus-wayland`。它会在没有总线时
运行 `ibus start --type=wayland`，若发现旧会话遗留的 IBus，则用
`ibus restart --type=wayland` 替换。这会让 IBus 绑定
Hyprland 的 `input-method-v2`，候选框成为输入法弹窗，而不是普通 GTK 顶层窗口；
同时保留 XIM，供 XWayland 应用使用。若仍异常，运行
`pgrep -af 'ibus-(daemon|ui-gtk3|x11)'` 并重新登录一次，不要在多个会话之间
复用旧守护进程。

系统级 **Ctrl+Space** 由 Hyprland 调用 `after-rain-input-toggle`，在
`xkb:us::eng` 与 `libpinyin` 之间切换；它不依赖应用是否正确转发 IBus trigger。
如果本次登录遗漏了 IBus 自启动，该脚本会调用同一个 Wayland 启动辅助程序
自愈，再切换到目标引擎。可用 `ibus engine` 查看当前引擎。

## 状态栏出现后应用仍要等一两分钟

用户级 systemd 和 D-Bus 可能跨越多次图形登录继续运行。若
`xdg-desktop-portal` 仍保存上一轮 Hyprland 的 Wayland socket 或
`HYPRLAND_INSTANCE_SIGNATURE`，GTK portal 激活会等满 120 秒，Ghostty、
SwayNC 和 Quickshell 等客户端也会一起表现为“没有反应”。

`after-rain-session-start` 会在每次 Hyprland 真正启动时先导入本会话环境，
停止旧 portal 主进程与后端、清除 start-limit，再按当前会话重启它们；随后才
异步启动桌面组件。检查当前状态：

~~~bash
systemctl --user --failed
systemctl --user show-environment | grep -E \
  '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE)='
tr '\0' '\n' </proc/$(pgrep -o xdg-desktop-portal)/environ | grep -E \
  '^(WAYLAND_DISPLAY|HYPRLAND_INSTANCE_SIGNATURE)='
~~~

最后两组值应一致。`hyprctl reload` 不会触发 `hyprland.start`；验证完整启动顺序
应退出并重新登录，或在当前 Hyprland 会话手动运行 `after-rain-session-start`。

## IBus 候选框没有跟随文字光标

不要只给普通 `ibus-daemon -drx` 设置 `GDK_BACKEND=wayland`：那只会改变 GTK
渲染后端，候选面板仍可能被当成普通大窗口。`ibus start --type=wayland` 会启动
带 `--enable-wayland-im` 的面板，让 Hyprland 通过输入法协议管理候选框。

会话会清空继承的 `GTK_IM_MODULE`、`QT_IM_MODULE`，让原生 GTK/Qt 应用默认
使用 Wayland 输入协议；Qt 同时保留 `QT_IM_MODULES=wayland;ibus` 的优先顺序。
不要再全局强制 `GTK_IM_MODULE=ibus`，否则 Rainlight 等 GTK4 应用也可能出现
普通候选窗口。Ghostty 的包装器和 ChatGPT 的 desktop 覆盖项继续明确选择
原生 Wayland。少数 X11-only 应用需要单独验证兼容路径。

当前用户的 `~/.config/uwsm/env` 同样应移除强制 IBus 模块设置（使用
`unset GTK_IM_MODULE QT_IM_MODULE`）。重载 Hyprland 影响后续由合成器启动的
进程，已有应用和已有桌面组件仍保留旧环境；退出并重新登录可完整统一。

检查进程与面板后端：

~~~bash
pgrep -af 'ibus-ui-gtk3.*enable-wayland-im'
hyprctl clients -j | jq -e '.[] | select(.class == "Ibus-ui-gtk3")' \
  && echo '异常：IBus 被暴露为普通窗口' || true
~~~

正常情况下 `ibus-ui-gtk3` 不应出现在 `hyprctl clients` 的普通客户端列表中。

## ChatGPT 输入中文时闪出新窗口

IBus 1.5.34-rc2 的 `CandidatePanel` 在处理非 Wayland 输入上下文时可能创建
普通 Wayland GTK 窗口；启用 XIM 并不保证 XWayland 应用的候选面板正常。
本机 Ghostty 原生 Wayland 输入已经通过人工验证；ChatGPT 的 XWayland 输入
仍出现闪窗，因此给 ChatGPT 单独使用原生 Wayland 启动参数：

~~~bash
./scripts/install-chatgpt-wayland.sh
~~~

脚本保存已有用户级 desktop 文件，并从系统 desktop 文件生成覆盖项，加入
`--ozone-platform=wayland --enable-wayland-ime`，仅对 ChatGPT 取消
`GTK_IM_MODULE` 并设置 `GDK_BACKEND=wayland`。完整退出 ChatGPT 后，从应用
启动器重新打开才会生效；已有进程不会因为打开新窗口而切换后端。
命令行测试同样参数可用：

~~~bash
env -u GTK_IM_MODULE GDK_BACKEND=wayland /usr/bin/chatgpt --ozone-platform=wayland --enable-wayland-ime
~~~

检查 `hyprctl clients -j` 中 ChatGPT 的 `xwayland` 为 `false`，再人工验证输入
上屏与候选框定位。原生 Wayland 隔离配置启动已验证，实际输入仍需人工验收。
回退时恢复脚本输出的备份中的 `chatgpt.desktop`；若备份包含
`previously-absent`，只需移走用户覆盖项让系统启动器重新生效。

## 完整恢复

使用安装器打印的精确备份目录运行 `scripts/restore.sh BACKUP_DIRECTORY`。恢复器
拒绝未列入白名单的清单路径，且会在覆盖前再做一份安全备份。
