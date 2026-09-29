# 快捷键 Profile 设计

状态：profile 机制已在仓库实现，`zh-pinyin` 键位仍属于待确认设计；尚未安装到当前
桌面。运行态由 `config/hypr/after_rain/bindings.lua` 按本机选择加载。

## 设计原则

1. 通用物理语义优先：Space、Enter、F1、数字、方向键、Print 和媒体键不强行
   拼音化。
2. 其他动作采用稳定、无歧义的中文拼音首字母，面向中文区用户降低记忆成本。
3. `Super` 表示高频启动或直接操作；`Shift` 表示移动或次级动作；`Ctrl` 表示
   管理、调整或会话控制；`Ctrl+Shift` 表示批量或潜在危险动作。
4. 操作影响越大，组合越复杂。锁屏、电源、清空等动作不能占用简单组合。
5. 一个动作只有一个正式快捷键；低频设置通过控制中心或 Rainlight 访问，不为
   每项功能消耗全局键位。
6. 不绑定无修饰字母；不让应用内常用的 Ctrl 组合被桌面截获。

## 候选 profile：`zh-pinyin`

### 帮助与核心入口

| 快捷键 | 动作 | 语义 |
|---|---|---|
| Super+F1 | 打开快捷键帮助 | 通用帮助键 |
| Super+Space | 打开 Rainlight | 全局入口 |
| Super+Enter | 打开终端 | 通用终端约定 |
| Super+W | 打开文件管理器 | 文件 Wénjiàn |
| Super+L | 打开浏览器 | 浏览 Liúlǎn |
| Super+K | 打开控制中心 | 控制 Kòngzhì |

不采用 `Super+?` 作为唯一帮助键：问号实际依赖 `Shift+/` 和键盘布局，适合作为
辅助提示，不适合作为基础绑定。

### 窗口

| 快捷键 | 动作 | 语义 |
|---|---|---|
| Super+G | 关闭当前窗口 | 关闭 Guānbì |
| Super+Q | 切换全屏 | 全屏 Quánpíng |
| Super+F | 切换浮动 | 浮动 Fúdòng |
| Super+P | 切换伪平铺 | 平铺 Píngpū |
| Super+Ctrl+F | 切换分割方向 | 布局管理进入 Ctrl 层 |
| Super+方向键 | 移动焦点 | 空间导航 |
| Super+Shift+方向键 | 移动窗口 | Shift 表示移动对象 |
| Super+Ctrl+方向键 | 调整窗口大小 | Ctrl 表示调整 |
| Super+鼠标左键 | 拖动窗口 | 直接操纵 |
| Super+鼠标右键 | 调整窗口大小 | 直接操纵 |

### 工作区与暂存区

| 快捷键 | 动作 |
|---|---|
| Super+1…0 | 切换工作区 1–10 |
| Super+Shift+1…0 | 移动窗口到工作区 1–10 |
| Super+Z | 显示或隐藏暂存区 |
| Super+Shift+Z | 移动窗口到暂存区 |

`Z` 来自暂存 Zàncún。

### 通知

| 快捷键 | 动作 |
|---|---|
| Super+T | 打开或关闭通知中心 |
| Super+Shift+T | 关闭最近一条通知 |
| Super+Ctrl+T | 切换勿扰模式 |
| Super+Ctrl+Shift+T | 清空全部通知 |

整组使用通知 Tōngzhī；操作影响越大，修饰键越多。

### 桌面、会话与输入

| 快捷键 | 动作 | 风险处理 |
|---|---|---|
| Super+B | 下一张壁纸 | 壁纸 Bìzhǐ；安全、可逆 |
| Super+Ctrl+S | 锁屏 | 会话中断动作进入 Ctrl 层 |
| Super+Ctrl+Shift+D | 打开电源菜单 | 潜在危险动作使用复杂组合 |
| Ctrl+Space | 切换中英文输入 | 中文输入法通用约定 |

关机、重启和注销不提供直接全局快捷键。电源组合只打开菜单；菜单默认焦点不得落在
关机按钮上，实际动作必须再次明确确认，Esc 或点击外部应取消。

### 截图与硬件

| 快捷键 | 动作 |
|---|---|
| Print | 区域截图并复制 |
| Alt+Print | 当前窗口截图并复制 |
| Shift+Print | 当前显示器截图并复制 |
| 音量键 | 调整音量或静音 |
| 媒体键 | 播放、暂停、上一首、下一首 |

音频混音器、网络、蓝牙和状态栏等低频管理动作不占用全局键位，统一从控制中心或
Rainlight 进入。

## 每个 Profile 自己定义界面分区

Profile 不只是一个“按键映射表”，同时拥有帮助界面的信息架构。每个方案用
`keys.section(顺序, "名称")` 声明自己的区域，再把绑定放入对应区域：

~~~lua
local section = {
    common_apps = keys.section(10, "常用应用"),
    common_functions = keys.section(20, "常用功能"),
    window = keys.section(30, "窗口"),
    workspace = keys.section(40, "工作区"),
    session = keys.section(60, "会话"),
}

keys.bind("SUPER + Space", section.common_apps, "打开 Rainlight", ...)
~~~

因此 `standard` 和 `zh-pinyin` 可以有“常用应用、常用功能、窗口、工作区、通知、
会话、截图、硬件、帮助”九区；`minimal` 不提供通知区，只展示八区。`custom` 可以
重命名、增删和重排这些区域。顺序号只负责区域顺序；每个区域内部仍按按键组合从
简单到复杂排列。

## 帮助界面

帮助界面按 Profile 声明的功能区显示，而不是擅自根据按键猜测区域；同一功能族中
大量重复的绑定会在默认视图压缩为代表项：

| 基础键 | Super | Super+Shift | Super+Ctrl | Super+Ctrl+Shift |
|---|---|---|---|---|
| T | 通知中心 | 关闭最近通知 | 勿扰模式 | 清空全部通知 |
| Z | 暂存区 | 移入暂存区 | — | — |
| 方向键 | 移动焦点 | 移动窗口 | 调整尺寸 | — |
| 数字 | 切换工作区 | 移动到工作区 | — | — |

应用入口、会话操作、截图和硬件键使用独立区域。界面始终读取 `hyprctl -j binds`，
区域顺序也编码在运行态 description 中，不维护一份可能漂移的界面副本。

## 可用 Profile

| 名称 | 用途 |
|---|---|
| `standard` | 跨平台常见语义，默认方案 |
| `zh-pinyin` | 本文保存的中文拼音语义方案 |
| `minimal` | 只保留核心入口、窗口、工作区、输入和硬件键 |
| `custom` | 加载用户自己的固定本地模块 |

在不会被升级覆盖的 `~/.config/hypr/after_rain_local.lua` 中选择：

~~~lua
return {
    binding_profile = "zh-pinyin",
    programs = { ... },
    monitors = { ... },
}
~~~

保存后运行 `hyprctl reload`。Quickshell 和 GTK 帮助界面读取运行态结果，因此会自动
显示当前 profile，不需要额外同步清单。

## Profile 架构

~~~text
config/hypr/after_rain/
  bindings.lua                 白名单加载器
  binding_profiles/
    lib.lua                    section/bind helper、重复检测与共享绑定
    zh_pinyin.lua              中文拼音方案
    standard.lua               跨平台常见约定方案
    minimal.lua                核心入口、窗口和工作区

~/.config/hypr/after_rain_local.lua
  return {
      binding_profile = "zh-pinyin",
      programs = { ... },
      monitors = { ... },
  }
~~~

加载器使用固定白名单映射，不会把本地字符串直接拼进 `require()`：

~~~lua
local profiles = {
    ["zh-pinyin"] = "after_rain.binding_profiles.zh_pinyin",
    ["standard"] = "after_rain.binding_profiles.standard",
    ["minimal"] = "after_rain.binding_profiles.minimal",
}
~~~

`custom` 也不接收任意路径：加载器只查找固定模块
`~/.config/hypr/after_rain_bindings.lua`。复制随仓库安装的
`after_rain_bindings.lua.example` 后即可完全定制，包括绑定、区域名称和区域顺序。
共享库在注册时拒绝重复组合，测试还会检查区域定义、无修饰字母、危险动作复杂度、
帮助入口和 description 完整性。

切换 profile 只通过 `hyprctl reload` 重新加载整体配置，不做运行中的逐条
bind/unbind，也不引入任意命令 IPC。

旧 `70-bindings.conf` 只承担紧急回退，不参与多 profile。否则 Lua profile 与旧配置会
形成两套事实来源。正式实现前需决定旧 provider 的保留周期。

## 尚待确认

1. 是否接受中文窗口语义：`G=关闭`、`Q=全屏`、`F=浮动`。
2. 是否保留直接壁纸快捷键，还是也移入控制中心。
3. 首次发布提供 `zh-pinyin + standard + minimal` 三套，还是先只发布一套经过完整
   验证的 `zh-pinyin`。
