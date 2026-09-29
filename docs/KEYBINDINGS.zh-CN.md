# 快捷键

After Rain 支持 `standard`、`zh-pinyin`、`minimal` 和 `custom` 四种 Profile。完整的
设计原则、键位表和选择方法见 [快捷键 Profile 设计](KEYBINDING-PROFILES.zh-CN.md)。

默认 `standard` 的核心入口：

| 快捷键 | 动作 |
|---|---|
| Super+F1 | 打开可搜索快捷键帮助 |
| Super+Space | Rainlight 搜索面板 |
| Super+Enter | 终端 |
| Super+E | 文件管理器 |
| Super+B | 浏览器 |
| Super+K | After Rain 控制中心 |
| Super+Q | 关闭当前窗口 |
| Super+F | 切换全屏 |
| Ctrl+Space | 切换中英文输入 |
| Super+Ctrl+L | 锁屏 |
| Super+Ctrl+Shift+Esc | 打开电源菜单 |

锁屏、电源菜单和清空全部通知等高影响操作不会占用简单组合。电源快捷键只打开菜单，
不直接关机、重启或注销。

## 帮助界面与分区

每套 Profile 都定义自己的帮助区域及顺序，例如“常用应用、常用功能、窗口、工作区、
通知、会话、截图、硬件、帮助”。`minimal` 可以省略通知区，`custom` 可以自由增删、
命名和排序区域。

快捷键窗口直接读取 `hyprctl -j binds`。绑定的 description 同时携带区域次序，所以
运行态键位和界面分区来自同一个事实来源。区域内从简单组合排到复杂组合；方向键、
工作区、通知和媒体键等重复族在默认总览中只展示代表项，输入搜索词后会返回全部
精确匹配。

旧 Hyprlang provider 第一次切换前，GTK 窗口仍可读取 `70-bindings.conf` 作为兼容
fallback。
