# 中文能输入，候选框却到处跑：一次 Hyprland + IBus 的 Wayland 排障实录

日期：2026-09-29

环境：Ubuntu 26.04.1、Hyprland 0.56.2、IBus 1.5.34-rc2

关键词：Wayland、XWayland、IBus、Ghostty、Chromium、GTK4

一次中文输入问题，最后牵出了三条不同的输入路径：浏览器使用原生 Wayland，桌面 ChatGPT 使用 XWayland，终端则通过 GTK 模块直接连接 IBus。它们共享同一个拼音引擎，却没有共享同一套候选框定位机制。

这篇文章记录 After Rain 桌面上的实际排查过程。最终做法是让 IBus 注册为 Wayland 输入法，让主要应用采用原生 Wayland，并清除会话中强制指定 IBus 模块的环境变量。无需更换输入法框架，但也不能只靠一句“已经设置了 `GTK_IM_MODULE=ibus`”判断配置正确。

## 起点：三个窗口，三种表现

最初的现象很奇怪：

| 应用 | 用户观察到的现象 | 实际显示后端 |
| --- | --- | --- |
| Chrome 地址栏 | 无法输入中文 | 原生 Wayland |
| ChatGPT 桌面窗口 | 可以输入，候选框能跟随光标 | XWayland |
| Ghostty | 可以输入，但候选框先出现在左上角；打开 ChatGPT 后又跑到它的输入位置 | 原生 Wayland |

当时的软件版本还包括 Chrome 153.0.8010.36、Ghostty 1.3.1、GTK4 4.22.4 和 ibus-libpinyin 1.16.5。本文的 ChatGPT 指本机安装、带 Chromium/Electron 运行时的桌面程序，不是浏览器中的网页。

候选框复用另一个窗口的位置，提示问题可能出在输入上下文或光标坐标更新，而不是词库。这个线索很有用，但它本身不能证明是哪一个程序没有上报坐标：当时没有捕获到完整的跨应用坐标事件序列。

## 第一步：看应用实际用了什么

`XDG_SESSION_TYPE=wayland` 只能说明桌面会话类型，不能证明会话里的每个窗口都使用 Wayland。

在 Hyprland 中，可以直接检查窗口：

```bash
hyprctl clients -j | jq '.[] | {pid, class, title, xwayland}'
```

其中 `xwayland: true` 表示窗口通过 XWayland 运行。排查时，Chrome 和 Ghostty 为 `false`，ChatGPT 为 `true`。Chromium 子进程的 `--ozone-platform=wayland` 或 `--ozone-platform=x11` 参数也能交叉验证。

接着检查输入法进程：

```bash
ps -eo pid,ppid,args | rg 'ibus-(daemon|ui-gtk3|x11)'
ibus engine
```

当时引擎是 `libpinyin`，守护进程是传统的 `ibus-daemon -drx`，其 GTK 面板被设置为 X11 后端。这证明引擎在线，却不能证明原生 Wayland 应用与它之间的协议已经接通。

还要查看目标进程真正继承的环境，而不是只在另一个终端里执行 `echo`：

```bash
# 将 12345 替换为 hyprctl 输出的目标应用 PID。
pid=12345
tr '\0' '\n' < "/proc/$pid/environ" |
  rg '^(GDK_BACKEND|GTK_IM_MODULE|QT_IM_MODULE|QT_IM_MODULES|WAYLAND_DISPLAY|DISPLAY)='
```

只筛选需要的变量，避免将进程的完整环境输出到日志中。个别程序可能清理或重写环境，因此读不到某个变量也不能作为唯一证据。

## 两种 Wayland 设置，含义完全不同

这次最关键的区别，是“窗口使用 Wayland 绘制”与“程序注册为 Wayland 输入法”并不等价。

```text
原生应用 / GTK / Chromium
          │ text-input-v3
          ▼
       Hyprland
          │ input-method-v2
          ▼
   IBus Wayland 前端 → LibPinyin
```

这是本次采用的主要路径。应用把输入状态和光标矩形交给合成器，输入法通过另一侧协议接入，候选弹窗由对应的协议角色管理。

单纯执行下面的命令，只改变 GTK 显示后端：

```bash
GDK_BACKEND=wayland ibus-daemon -drx
```

它不能替代输入法前端的注册。在本机的排查中，普通 GTK 候选窗口曾被当作普通窗口管理，出现大框、平铺或闪窗。

本机 IBus 提供了专门的启动方式：

```bash
ibus start --type=wayland
```

该入口会启动带 `--enable-wayland-im` 的 `ibus-ui-gtk3`，由它启动带 `--xim --panel disable` 的守护进程。此处 `--panel disable` 禁用的是 daemon 另起默认面板，并不意味着没有候选界面；Wayland 前端已经负责面板。这一行为可核对 [IBus 1.5.34-rc2 的启动实现](https://github.com/ibus/ibus/blob/1.5.34-rc2/tools/main.vala)。

Chrome 的情况也值得注意：Chromium 在 2025 年已将 `WaylandTextInputV3` 改为默认启用。因此，对于本机 Chrome 153，排查重点不能停留在“再加一个启用 v3 的 flag”，还要检查合成器另一侧是否有输入法接入。[Chromium 对应变更](https://chromium.googlesource.com/chromium/src/+/e48954bdc391fcba2fd20a5a40a8a16332cf1638)

## 第一次迁移：Ghostty 好了，ChatGPT 开始闪窗

会话里已经存在旧 IBus 时，执行 `start` 只返回 `IBus is running.`，不会把运行模式自动换掉。真正完成本次切换的是：

```bash
env GDK_BACKEND=wayland,x11 ibus restart --type=wayland
```

重启会中断尚未上屏的预编辑文本，应先完成当前输入。没有运行中的 IBus 时则使用 `start`。

运行日志确认发现了 `zwp_input_method_manager_v2`，并报告以 Wayland input-method version 2 重启成功。随后新开的 Ghostty 采用：

```bash
env -u GTK_IM_MODULE GDK_BACKEND=wayland ghostty
```

用户确认 Ghostty 中文输入恢复正常。但重启后的 ChatGPT 在输入时又闪出新窗口。这说明保留 `--xim` 只能证明兼容入口仍在，不能证明整条候选框路径可用。

查看 IBus 对应版本的源代码可见，候选面板构造使用 GTK popup，而 `realize_window()` 在 `m_no_wayland_panel` 分支提前返回，跳过后续自定义 Wayland surface 的设置。这与本机非原生输入路径出现普通窗口的现象相符；由于没有完整的协议追踪，这里将它记作有源码支持的解释，而不是已经证明适用于所有环境的上游缺陷。[候选面板实现](https://github.com/ibus/ibus/blob/1.5.34-rc2/ui/gtk3/candidatepanel.vala)

处理办法是让 ChatGPT 同样采用原生 Wayland：

```bash
env -u GTK_IM_MODULE GDK_BACKEND=wayland \
  /usr/bin/chatgpt --ozone-platform=wayland --enable-wayland-ime
```

先使用独立临时配置目录验证启动，再生成用户级 desktop 覆盖项。用户完整退出原来的 ChatGPT 并重新打开后，确认 ChatGPT 与终端输入都正常。

注意“完整退出”：已有 Chromium/Electron 主进程可能接管后续启动请求，单纯再开一个窗口，不会让旧进程变成 Wayland。

## 最后一处：为什么启动器还需要修？

`Super+Space` 打开的 Rainlight 是 GTK4 应用。ChatGPT 和 Ghostty 正常后，Rainlight 输入中文仍会弹出新窗口，看起来像“每个程序都得适配一次”。

检查后发现，先前为兼容保留的全局设置仍然存在：

```bash
GTK_IM_MODULE=ibus
QT_IM_MODULE=ibus
```

这些变量会影响工具包选择输入法模块。我们为两个应用做了局部调整，却让其他原生应用继续继承旧配置。

最终把会话默认值统一下来。在本仓库使用的 Hyprland Lua 配置中：

```lua
hl.env("GDK_BACKEND", "wayland,x11")
hl.env("GTK_IM_MODULE", "")
hl.env("QT_IM_MODULE", "")
hl.env("QT_IM_MODULES", "wayland;ibus")
hl.env("XMODIFIERS", "@im=ibus")
```

空值用来覆盖从上层会话继承的强制模块设置；本机 GNOME 的 `gtk-im-module` 设置也为空。支持多模块选择的 Qt 环境保留 `wayland;ibus` 的优先顺序，X11 侧保留 XIM 声明。这不是承诺所有 Qt 版本、所有旧 X11 应用都不需要检查。

传统 Hyprlang 配置对应为：

```ini
env = GDK_BACKEND,wayland,x11
env = GTK_IM_MODULE,
env = QT_IM_MODULE,
env = QT_IM_MODULES,wayland;ibus
env = XMODIFIERS,@im=ibus
```

本机 `~/.config/uwsm/env` 中旧的 `export GTK_IM_MODULE=ibus` 也改为：

```bash
unset GTK_IM_MODULE QT_IM_MODULE
```

当前会话还同步更新了 D-Bus/systemd 的激活环境：

```bash
env GTK_IM_MODULE= QT_IM_MODULE= \
  dbus-update-activation-environment --systemd GTK_IM_MODULE QT_IM_MODULE
```

随后重载 Hyprland、重新启动 Rainlight，确认新进程中的两个模块变量为空。这样大多数支持原生 Wayland 输入的应用可以共享正确的默认配置。个别选择了 X11 的程序仍可能需要显示后端参数或兼容性处理。

## 几个容易误判的地方

**当前终端的环境不等于应用环境。** 一次测试 Ghostty 意外以 XWayland 启动，检查进程发现它继承的是 `GDK_BACKEND=x11`。这足以解释结果，不能据此认定 GTK 在 `wayland,x11` 设置下存在自动回退缺陷。

**进程存在不等于输入正常。** `ibus engine` 返回 `libpinyin`、面板未出现在普通窗口列表，都只是中间检查。必须在输入法实际展开候选词时观察，并验证选词上屏。

**搬动候选窗口不能补齐协议。** 排查中曾尝试监听 `SetCursorLocation` 再移动 X11 候选窗。它依赖收到正确的坐标，也不能为 Chrome 建立缺失的输入链路。最终方案不再启动这个辅助程序，原文件保留以免破坏此前工作。

**重载配置不会修改已有进程的环境。** Hyprland reload 也不会重新执行 `exec-once`。已经打开的启动器、状态栏和应用仍可能持有旧环境。一次注销并重新登录，比反复给应用追加变量更容易验证最终会话是否一致。

**旧故障的修复可能成为新配置的约束。** 更早一次 ChatGPT 启动崩溃与 X11 后端配合 GTK Wayland 输入模块有关；当时使用 IBus 模块解决了启动问题。本次选择应用原生 Wayland 后，应该重新评估那个全局设置，而不是无限期保留它。

## 验收：哪些已经证实，哪些还没有

| 项目 | 本次记录中的结果 |
| --- | --- |
| IBus Wayland 前端 | 进程参数与协议发现日志确认启用 |
| Ghostty | 原生 Wayland、环境核对通过，用户确认中文输入正常 |
| ChatGPT | 原生 Wayland 启动验证通过；完整重开后用户确认中文输入正常 |
| Rainlight | 全局环境修正、新进程环境检查及行为测试通过；用户随后回复“ok”，未单独描述候选框验收细节 |
| Chrome 地址栏 | 确认原生 Wayland 启动；本次对话未获得单独的最终输入验收反馈 |
| 所有 Qt / X11 应用 | 未做全量兼容性验证 |

复测时，在每个目标输入框中输入拼音、展开候选词、选择上屏，再移动光标、换行和切换应用，观察候选框是否跟随，是否出现普通窗口。最后注销登录复测，才能覆盖自启动与环境继承。

仓库的配置解析、输入法恢复测试、Rainlight 行为测试和安装/恢复测试用于检查配置与脚本；它们不能代替桌面上的输入法交互验收。

## 在仓库中复用与回退

相关实现如下：

- [IBus Wayland 启动脚本](../../bin/after-rain-ibus-wayland)：根据当前总线状态选择 start 或 restart。
- [会话环境](../../config/hypr/after_rain/environment.lua)：统一原生输入默认值。
- [Ghostty 包装器](../../bin/after-rain-terminal)：显式选择 Wayland，并清除继承的 GTK 模块覆盖。
- [ChatGPT 启动器安装脚本](../../scripts/install-chatgpt-wayland.sh)：生成并备份用户级 desktop 覆盖项，需要单独执行。
- [故障处理手册](../TROUBLESHOOTING.zh-CN.md)：日常检查入口。

部署前阅读这些文件，再按仓库安装说明操作。主安装器会输出备份目录和恢复命令；ChatGPT 覆盖项由它自己的安装脚本单独备份，`uwsm/env` 的修改也需要单独留存。配置备份恢复不会自动把运行中的 IBus 切回旧模式。

如果要回到先前的传统 X11 面板路径，在恢复对应配置后，可执行：

```bash
# 会中断当前输入状态；此路径会重新带回原生应用的兼容限制。
ibus exit
env GDK_BACKEND=x11 /usr/bin/ibus-daemon -drx
```

这次排查最值得复用的习惯，是同时检查应用后端、输入协议、候选面板角色和进程环境。只有把它们放在一起看，才能解释为什么同一个拼音引擎，在不同窗口里会表现得完全不同。
