# After Rain 与 Omarchy 4 差距及统一 Shell 方案

更新时间：2026-09-29。本文以 Omarchy `v4.0.4`、Hyprland `v0.56.2`、
Quickshell `v0.3.1` 为版本基线。

## 结论

After Rain 已经有统一的视觉主题，但还没有统一的桌面 Shell。当前 Waybar、
SwayNC、SwayOSD、Wlogout、Hyprlock 和 Rainlight 各自拥有窗口、状态和交互模型。
继续分别美化只能改善外观，不能解决状态重复、快捷键漂移、弹层焦点和多显示器
生命周期问题。

应定制 `after-rain-shell`：用一个常驻 Quickshell 进程承载栏、菜单、快捷键面板、
控制面板、通知和 OSD。Hyprland Lua 只负责合成器配置、窗口规则、事件与快捷键；
Quickshell 继续使用 QML/JavaScript 构建界面。Lua 不是 Quickshell 的 UI 语言。

## 版本与边界

- Hyprland 从 0.55 起将 `hyprland.conf` 标记为 deprecated，推荐入口是
  `~/.config/hypr/hyprland.lua`。0.56.2 是本机当前版本。
- Quickshell 0.3.1 是当前稳定版。它能识别 Hyprland 的 Lua provider，但界面仍
  使用 QML。
- Ubuntu 26.04 软件源当前没有 Quickshell 候选包，因此必须建立固定版本、校验、
  升级和回滚链，不能直接跟随 `master`。
- 本项目是 Ubuntu 桌面层，不复制 Omarchy 的 Arch 包管理、自有内核、ISO 或 AUR
  链路。如果未来要做发行版，应拆成独立项目。

## 差距矩阵

| 能力 | Omarchy 4 | After Rain 当前 | 处理方向 |
|---|---|---|---|
| Hyprland 配置 | Lua 模块、回调、动态规则 | 已开始迁移到模块化 Lua，旧 `.conf` 保留回滚 | 完成现场验证后移除双入口歧义 |
| 快捷键帮助 | 读取运行态绑定、搜索、执行 | 新 GTK4 浏览器已读取 `hyprctl -j binds` | MVP 后迁入 Quickshell overlay |
| 统一 Shell | 单 Quickshell 进程 | 多个独立 UI 进程 | 最大架构差距 |
| Bar | 可换边、拖动组件、原生面板 | 静态 Waybar 三段布局 | P1 迁移，Waybar 保留 fallback |
| Launcher/Menu | 统一 Apps 与系统动作 | Rainlight + 独立 dmenu 菜单 | 建 ActionRegistry，复用 Rainlight provider |
| Audio/网络/蓝牙/显示 | 原生 QML panel | wiremix/nmtui/bluetui | 逐项替换，不一次性下线 |
| 通知/OSD | Shell 内统一 | SwayNC + SwayOSD | P2 迁移 |
| 锁屏/Polkit | Shell 插件 | Hyprlock + agent | 最后迁移，安全优先 |
| 主题 | 多主题、Shell token、安装器 | 单主题、确定性 renderer 和 CI | 扩展生成 `theme.lua` 与 QML tokens |
| 插件/IPC | manifest、typed IPC、热重载 | 无 | MVP 只做第一方 typed IPC |
| 更新/回滚 | 迁移、通道、快照、系统更新 | 配置备份、失败恢复、CI | 增加 schema/migrations，不复制 pacman |

## 目标架构

~~~text
Hyprland 0.56 Lua
  ├─ after_rain.bindings      带 description/category 的唯一快捷键来源
  ├─ rules/events             窗口、层、工作区与启动生命周期
  └─ GlobalShortcut/typed IPC 只召唤固定 Shell 动作

after-rain-shell (Quickshell 0.3.1, QML)
  ├─ Theme / State / ActionRegistry
  ├─ Bar
  ├─ Root Menu + Apps
  ├─ Keybindings Overlay
  ├─ Audio / Network / Bluetooth / Display / Power Panels
  ├─ Notifications / OSD
  └─ Health IPC

现有后端
  ├─ wallpaper / workspace
  ├─ input method
  ├─ reload / doctor
  └─ install / backup / restore
~~~

### 数据和调用规则

1. 主题仍以 `themes/after-rain/colors.toml` 为事实源，同时生成 Lua 和 QML token。
2. 所有绑定都必须有 `description`，快捷键界面打开时读取 `hyprctl -j binds`；不再
   维护第二份硬编码清单。
3. Shell IPC 只暴露 `toggleLauncher`、`toggleKeybindings`、`togglePanel(id)` 等窄
   方法，不提供任意命令执行。
4. 常驻 bar 不抢键盘焦点；搜索弹层只在可见时抓取焦点，Esc 和点击外部均释放。
5. 锁屏必须使用 `WlSessionLock`，不能用普通 LayerShell 假装安全锁屏。
6. 第三方 QML 与 Shell 同进程、同用户权限，不是沙箱。首版只加载仓库内第一方
   模块，插件市场后置。

## 分阶段路线

### 当前实施状态（2026-09-29）

- P0 已完成并安装：Hyprland Lua、运行态 GTK4 快捷键浏览器、LibPinyin 排障与
  回滚链。
- P1 的 MVP-0 基座已完成：固定源码构建的 Quickshell 0.3.1、typed IPC、主题
  token、QML 快捷键 overlay、systemd health/fallback 和 Hyprland 会话隔离。
- P1 尚未完成的部分是 bar、root/apps menu 和 ActionRegistry。完成 Waybar 功能
  等价前，不关闭 Waybar；Rainlight 继续作为 launcher。
- P2/P3 未开始。SwayNC、SwayOSD、Hyprlock 与 Polkit 仍由旧稳定组件负责。

### P0：行为基础（当前变更）

- 关闭 ibus-libpinyin 的 `i` Lua 扩展入口，消除时间、日期、计算等候选弹层。
- 新增完整、可搜索的快捷键窗口；`Super+F1` 和 `Super+Shift+K` 都可打开。
- 迁移到 `hyprland.lua + after_rain/*.lua`，用 `hl.window_rule()` 定制 Rainlight、
  快捷键浏览器和工具窗口。
- 保留旧 `.conf` 一版用于回滚；Lua 入口只在 Hyprland 进程启动时选择，因此上线
  后需要重新登录 Hyprland 做运行态验收。

### P1：Quickshell MVP

- 固定并打包 Quickshell 0.3.1，提供校验和与升级策略。
- 先统一 bar、root/apps menu、keybindings overlay、Theme/State/IPC。
- Waybar 保留为可切换 fallback，至少跨两个发行版本。
- systemd user unit 使用 `Restart=on-failure`，提供 `ping` 健康检查。

### P2：系统面板

- 按 audio → network → bluetooth → display → power 的顺序迁移。
- 每验收一个 QML panel，再下线一个 TUI 入口。
- 随后迁移通知和 OSD；Hyprlock/Polkit 最后处理。

### P3：发行级维护

- 为 shell.json 与主题 token 建 schema 和版本化 migration。
- 增加 stable/dev 通道、升级前快照 hook、Ubuntu apt/fwupd 状态入口。
- 再评估 manifest 插件；默认禁用并在安装/更新前展示代码差异。

## 验收门槛

- `hyprctl configerrors` 为空，`hyprctl -j binds` 中没有无修饰字母绑定。
- 中文 LibPinyin 下输入 `i` 不再触发 Lua 扩展；输入、候选、切换均正常。
- 快捷键窗口显示运行态全部 description，搜索和 Esc 关闭可用，关闭后无 focus grab。
- 多显示器热插拔、全部输出短暂消失、熄屏、休眠恢复、Wi-Fi 开关通过。
- Shell crash 后自动恢复；fallback bar、通知和 OSD 可在无 Quickshell 时启动。
- reload 循环不泄漏进程、inotify、文件描述符或 GlobalShortcut 注册。

## 主要参考

- [Omarchy v4.0.4](https://github.com/omacom/omarchy/releases/tag/v4.0.4)
- [Omarchy Shell 架构](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md)
- [Omarchy Hotkeys](https://github.com/omacom/omarchy/blob/quattro/manual/07-hotkeys.md)
- [Omarchy Top Bar](https://github.com/omacom/omarchy/blob/quattro/manual/05-the-top-bar.md)
- [Omarchy Themes](https://omarchy.org/manual/themes/)
- [Omarchy Updates](https://omarchy.org/manual/updates/)
- [Hyprland Lua 配置](https://wiki.hypr.land/Configuring/Start/)
- [Hyprland Lua Window Rules](https://wiki.hypr.land/configuring/core/rules/window-rules/)
- [Quickshell 0.3.1](https://github.com/quickshell-mirror/quickshell/releases/tag/v0.3.1)
- [Quickshell changelog](https://quickshell.org/changelog/)
