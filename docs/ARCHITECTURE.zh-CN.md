# 架构说明

## 单一事实来源

`themes/after-rain/colors.toml` 定义语义颜色、几何与透明度。
`scripts/render-theme.py` 将它确定性地渲染到 Hyprland、Waybar、SwayNC、
SwayOSD、Wlogout、Rainlight、Hyprtoolkit、Ghostty、Kitty、GTK3/4 和 btop。
生成文件带有“不要直接编辑”标记，CI 会用 `--check` 拒绝漂移。Quickshell 的
`Generated/Theme.qml` 也是同一渲染链的输出。

~~~text
colors.toml
    └─ render-theme.py
       ├─ Hyprland / Hyprtoolkit
       ├─ Waybar / SwayNC / SwayOSD / Wlogout / Rainlight
       ├─ After Rain Shell QML tokens
       ├─ Ghostty / Kitty / btop
       └─ GTK3 / GTK4
~~~

## Hyprland 配置层级

Hyprland 0.56+ 的入口是 `hyprland.lua`，依次加载 `after_rain/` 中的环境、显示器、
输入、外观、窗口规则、快捷键与启动模块。机器本地覆盖保存在
`after_rain_local.lua`，不会被 Git 或安装器覆盖。旧 `hyprland.conf + conf.d` 暂留
一版作为回滚后端，但同一个 Hyprland 进程只会选择一种配置 provider。

## 快捷键发现

每个 Lua bind 都带类别化 `description`。`after-rain-keybinds` 从
`hyprctl -j binds` 读取实际注册状态，搜索、分组并显示全部绑定；不再维护容易漂移
的 19 项硬编码清单。旧 provider 第一次切换前，程序会解析 `70-bindings.conf`
作为兼容 fallback。

## After Rain Shell MVP

`config/quickshell/after-rain` 是命名 Quickshell 配置。当前 MVP 只接管快捷键
overlay 与统一状态/IPC 基座；Waybar、Rainlight、SwayNC、SwayOSD、Hyprlock 和
Polkit 仍是稳定后端。`after-rain-shell` 只暴露 ping、显示/隐藏/切换快捷键和刷新
数据，不允许调用方执行任意命令。overlay 打开时固定运行 `hyprctl -j binds`，关闭
后释放键盘焦点；IPC 或 Quickshell 不健康时 wrapper 立即打开 GTK4 fallback。

`after-rain-shell.service` 不 enable 到通用 `graphical-session.target`，只由
Hyprland Lua 的 `hyprland.start` 启动。这避免 GNOME 登录时同时拉起 layer-shell
组件。Quickshell bar、根菜单和系统面板仍属于后续阶段，当前不能下线 Waybar。

## 工作区与壁纸

`after-rain-workspace` 提供三种模式：数字参数负责切换；`sync` 对齐当前工作区；
`watch` 常驻监听 Hyprland IPC。工作区 1–4 映射四位角色，5–10 不强制换图。
`after-rain-wallpaper` 用 `flock` 串行化更新、原子替换 `current.png`，再通过
Hyprpaper IPC 重载。这样无论数字键、Waybar、手势还是外部 `hyprctl` 都一致。

## Rainlight

Rainlight 是独立 GTK4 程序，从 freedesktop desktop entry 数据库索引应用。
只有用户明确输入 `>` 才运行 Shell；计算器使用 AST 白名单，不调用 `eval`；
文件模式限制在主目录五层并跳过缓存、Git 与依赖目录。界面颜色由同一主题生成。

## 安装与恢复

安装器先生成权限收紧的逐项清单，再安装。错误陷阱调用恢复器回到安装前状态；
恢复前又会创建安全副本。集成测试在临时 XDG 根目录执行完整安装→恢复，验证
现存配置保留、原本不存在的目录和命令被准确移除。
