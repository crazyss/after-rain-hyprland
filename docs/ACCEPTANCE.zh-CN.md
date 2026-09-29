# 发布验收

2026-09-29 在 Ubuntu 26.04.1、Hyprland 0.56.2、Hyprpaper 0.8.4、
SwayNC 0.12.4、3440×1440 Wayland 会话完成以下验收。

| 要求 | 权威证据 | 结果 |
|---|---|---|
| Hyprland 配置可解析 | `Hyprland --verify-config` | 通过 |
| 主题生成物无漂移 | `render-theme.py --check` | 通过 |
| 壁纸/预览哈希与隐私元数据 | `verify-assets.py` | 通过 |
| Rainlight 模式与计算器白名单 | `test-rainlight.py` | 通过 |
| 数字切换与真实 IPC 工作区事件 | `test-workspace.py` + 实机会话 | 通过 |
| IBus 离线自愈与中英文双向切换 | `test-input-method.py` + 实机会话 | 通过 |
| 工作区 1/2 实际活动壁纸 | `hyprctl hyprpaper listactive` | 林晚/高森葵均通过 |
| Super+E 文件管理器 | Hyprland 启动并映射新 Nautilus 窗口 | 通过 |
| Rainlight 冷/热启动 | 实测窗口出现约 338 ms / 108 ms | 通过 |
| GTK4 搜索面板真实渲染 | `assets/rainlight-preview.png` | 通过 |
| 安装后精确恢复 | 临时 XDG 根目录安装→恢复 | 通过 |
| Shell 静态分析 | ShellCheck 0.11.0 | 通过 |
| 工作树和 Git 历史密钥扫描 | `scan-secrets.sh` | 通过 |
| 运行组件与用户服务 | `after-rain-doctor` | 全部通过 |

## 一键重跑

~~~bash
./scripts/validate.sh
python3 scripts/test-rainlight.py
python3 scripts/test-workspace.py
python3 scripts/test-input-method.py
./scripts/test-install-restore.sh
after-rain-doctor
~~~

公开 GitHub URL 与远端 CI 状态必须在创建远程仓库后另行确认；本地通过不等于
GitHub Actions 已经执行。
