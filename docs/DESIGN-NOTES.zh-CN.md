# Omarchy 主题研究与取舍

## 吸收的做法

1. **主题是数据，不是散落的 CSS。** 颜色先定义为 background、surface、
   foreground、muted、accent、urgent 等语义角色，再映射到 Hyprland、Waybar、
   通知、锁屏和终端。
2. **整套桌面一起变化。** 主题不仅是一张壁纸；窗口边框、栏、启动器、通知、
   锁屏和终端必须共享色温与层级。
3. **多张背景可轮换。** 同一角色世界观下允许多个场景，但默认背景应留出
   窗口可读区域。
4. **远程主题按不可信输入处理。** 公共仓库只分发声明式配置与资源；安装脚本
   不执行素材包中的代码。
5. **升级与私人覆盖分离。** 机器专属显示器设置留在被 Git 忽略的
   `after_rain_local.lua`，公共配置保持可更新。
6. **切换动作需要状态一致。** 工作区专属壁纸不能只写在数字快捷键里；
   Waybar、手势或命令行切换也必须由 Hyprland IPC 监听器同步。
7. **启动器是桌面语言的一部分。** Rainlight 不只换 CSS，而是将应用、文件、
   网页、命令、计算器、工作区和壁纸统一成可搜索的动作模型。

## 没有照搬的部分

Omarchy 4 当前围绕 Arch Linux、Hyprland Lua、Quickshell 和自身更新链路组织。
这里的目标机器仍是 Ubuntu，但 Hyprland 已迁到 Lua；Quickshell 采用阶段式替换，
Waybar/SwayNC/SwayOSD 在统一 Shell 验收前保留 fallback。

## 参考

- [Omarchy Themes Manual](https://omarchy.org/manual/themes/)
- [Making Your Own Theme](https://github.com/omacom/omarchy/blob/quattro/manual/43-making-your-own-theme.md)
- [Omarchy Dotfiles Manual](https://omarchy.org/manual/dotfiles/)
- [Omarchy Design System](https://github.com/mrelph/omarchy-design-system)
- [Omarchy Theme Generator](https://github.com/maxberggren/omarchy-theme-generator)
- [Omarchy Theming Reference](https://github.com/omacom/omarchy/blob/quattro/docs/theming.md)
- [Coppernight Theme](https://github.com/hembramnishant50-glitch/omarchy-coppernight-theme)
