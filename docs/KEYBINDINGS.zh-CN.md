# 快捷键

| 快捷键 | 动作 |
|---|---|
| Super+Return | Ghostty 终端 |
| Super+Space | Rainlight 搜索面板 |
| Super+K | 雨幕控制中心 |
| Super+Shift+K | 可搜索快捷键帮助 |
| Super+F1 | 可搜索快捷键帮助（易发现别名） |
| Super+E | Nautilus 文件管理器 |
| Super+C / Super+Q | 关闭当前窗口 |
| Super+F | 全屏 |
| Super+V | 浮动/平铺 |
| Super+Ctrl+L | 锁屏 |
| Super+Escape | 电源菜单 |
| Super+N | 通知中心 |
| Super+Shift+Space | 显示/隐藏 Waybar |
| Super+Ctrl+Space | 下一张角色壁纸 |
| Super+Ctrl+A/W/B | 音频 / 网络 / 蓝牙 TUI |
| Ctrl+Space | 在 English 与 LibPinyin 中文之间切换 |
| Super+方向键 | 移动焦点 |
| Super+Shift+方向键 | 移动窗口 |
| Super+Ctrl+方向键 | 调整窗口大小 |
| Super+1 | 工作区 1 · 林晚壁纸 |
| Super+2 | 工作区 2 · 高森葵壁纸 |
| Super+3 | 工作区 3 · 徐知安壁纸 |
| Super+4 | 工作区 4 · Clara 壁纸 |
| Super+5..0 | 切换工作区 5..10，并保留当前壁纸 |
| Super+Shift+1..0 | 移动窗口到工作区 |
| Print | 区域截图到剪贴板 |
| Alt+Print | 窗口截图到剪贴板 |
| Shift+Print | 显示器截图到剪贴板 |

鼠标配合 Super：左键移动窗口，右键调整大小。

Waybar 右侧的 `EN` / `中` 显示当前 IBus 引擎；点击它与 Ctrl+Space 等价。
如果本次 Hyprland 登录遗漏了 IBus 自启动，Ctrl+Space 会先启动守护进程，再完成
English/LibPinyin 切换。

快捷键窗口直接读取 `hyprctl -j binds`，所以 Lua 配置中新增且带 description 的绑定
会自动出现。旧 Hyprlang provider 第一次切换前，窗口会读取 `70-bindings.conf` 作为
兼容 fallback。
