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
   local.conf，公共配置保持可更新。

## 没有照搬的部分

Omarchy 当前围绕 Arch Linux、Lua/Quickshell 和自身更新链路组织。这里的目标
机器是 Ubuntu 与经典 Hyprlang 配置，因此保留现有稳定组件，借鉴设计系统而非
复制运行时。

## 参考

- [Omarchy Themes Manual](https://omarchy.org/manual/themes/)
- [Making Your Own Theme](https://github.com/omacom/omarchy/blob/quattro/manual/43-making-your-own-theme.md)
- [Omarchy Dotfiles Manual](https://omarchy.org/manual/dotfiles/)
- [Omarchy Design System](https://github.com/mrelph/omarchy-design-system)
- [Omarchy Theme Generator](https://github.com/maxberggren/omarchy-theme-generator)
