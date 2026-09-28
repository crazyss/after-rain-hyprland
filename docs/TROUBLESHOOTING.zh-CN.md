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

配置会在每个 Hyprland 会话直接执行 `/usr/bin/ibus-daemon -drx`，不再通过
`pgrep` 猜测其他会话的旧进程。若仍异常，运行 `pgrep -af ibus-daemon` 并重新
登录一次，不要在多个会话之间复用旧守护进程。

系统级 **Ctrl+Space** 由 Hyprland 调用 `after-rain-input-toggle`，在
`xkb:us::eng` 与 `libpinyin` 之间切换；它不依赖应用是否正确转发 IBus trigger。
可用 `ibus engine` 查看当前引擎。

## 完整恢复

使用安装器打印的精确备份目录运行 `scripts/restore.sh BACKUP_DIRECTORY`。恢复器
拒绝未列入白名单的清单路径，且会在覆盖前再做一份安全备份。
