# After Rain Shell 运维说明

## 当前边界

本轮交付的是统一 Shell 的 MVP-0：常驻 Quickshell、生成式主题 token、typed IPC
和运行态快捷键 overlay。Waybar、Rainlight、SwayNC、SwayOSD、Wlogout、Hyprlock、
Hypridle、Hyprpaper 与 Polkit 继续保留。也就是说，统一运行时基座已经存在，但
bar、root/apps menu 与系统面板尚未迁完。

`Super+F1` 和 `Super+Shift+K` 调用 `after-rain-shell toggle-keybindings`。Shell
健康时显示 QML overlay；IPC、进程或二进制不可用时自动执行
`after-rain-keybinds`，不会让快捷键帮助变成单点故障。

## 固定源码构建

~~~bash
./scripts/build-quickshell.sh
~~~

构建脚本固定并核验：

- tag：`v0.3.1`
- commit：`1a4716cde794a59928d9d9fc15f2afc7a95de360`
- 源码：`~/src/quickshell-v0.3.1`
- 安装前缀：`~/.local`

Ubuntu 缺少的开发包会从当前 APT 源下载 `.deb`，只解包进源码目录的
`.after-rain-deps`，不会修改系统包数据库。构建关闭本阶段不使用的 PipeWire、
PAM、Polkit、Greetd、UPower、Bluetooth、Network、X11、i3 和 screencopy 模块；
保留 Wayland、LayerShell、Hyprland、IPC、tray、MPRIS 与 notifications 能力。

重建时可以覆盖：

~~~bash
AFTER_RAIN_BUILD_JOBS=8 ./scripts/build-quickshell.sh
AFTER_RAIN_QUICKSHELL_SOURCE="$HOME/src/quickshell-v0.3.1" \
  AFTER_RAIN_QUICKSHELL_PREFIX="$HOME/.local" \
  ./scripts/build-quickshell.sh
~~~

Quickshell 使用 Qt 私有 ABI。Qt 版本升级后必须重新运行构建脚本，不能继续假设旧
二进制安全。

## 会话启动与隔离

`after-rain-shell.service` 没有 `WantedBy=`，不会 enable 到所有图形会话。
Hyprland Lua 在 `hyprland.start` 时启动它。旧组件带有
`ConditionEnvironment=HYPRLAND_INSTANCE_SIGNATURE` drop-in；即使发行版把 Waybar 或
SwayNC 全局 enable，它们在 GNOME 中也会跳过，在 Hyprland 中才按需启动：

~~~bash
after-rain-session-isolate status
after-rain-session-isolate apply
~~~

若要恢复安装前那种“每个 graphical session 都尝试启动旧组件”的行为：

~~~bash
after-rain-session-isolate restore-legacy-autostart
~~~

这通常不推荐，因为 GNOME 不提供 Hyprland/wlroots 协议，旧组件会失败、崩溃或与
GNOME 通知服务争用 D-Bus 名称。

## 健康检查

~~~bash
after-rain-shell status
after-rain-shell ping
systemctl --user status after-rain-shell.service
qs -c after-rain ipc show
~~~

预期 `ping` 返回成功，IPC 只包含 `ping`、`version`、`toggleKeybindings`、
`showKeybindings`、`hideKeybindings` 和 `reloadBindings`。不存在通用 exec/eval。

当前在 GNOME 只能做配置加载和 IPC smoke；真实 LayerShell、Hyprland 运行态绑定、
焦点释放、多显示器、DPMS 和休眠恢复必须在下一次 Hyprland 登录后验收。

## 回滚

项目安装器的时间戳备份包含命名 QML 配置、user unit 和 wrapper。常规回滚使用
安装时打印的 `scripts/restore.sh BACKUP_DIRECTORY`。紧急情况下可只停 Shell：

~~~bash
systemctl --user stop after-rain-shell.service
after-rain-keybinds
~~~

Waybar 与旧通知/OSD 栈在 MVP-0 没有被删除，因此停止 Quickshell 不会让桌面失去
状态栏、通知、音量反馈或锁屏。
