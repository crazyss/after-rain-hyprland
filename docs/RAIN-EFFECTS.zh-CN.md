# 玻璃水珠效果

2026-09-30：按用户最终选择，当前只启用玻璃水珠；雨丝粒子暂不用。
独立 `RainStreaks.qml` 保留实现，但没有被当前渲染链加载或实例化。
原始方案比较保留在 [调研文档](RAIN-OVERLAY-DESIGN.zh-CN.md)。

## 使用

```bash
after-rain-shell rain normal
after-rain-shell rain light
after-rain-shell rain heavy
after-rain-shell rain off
after-rain-shell rain toggle
after-rain-shell rain status | jq .
```

命令返回 `{"ok":true,"data":{...}}`，错误写 stderr 并退出非零。
退出码：0 成功，1 运行态或持久化错误，2 参数错误。
持久化失败时档位可能已在内存中改变，以 `rain status` 核对。
`toggle` 在关闭和上次非关闭档位之间切换。默认 normal，不新增全局快捷键。

## 行为与边界

- 水珠从小到大凝结、停留，随后拉长、缓慢起步再加速下滑；小水珠停留更久。
- 使用一个 33 ms 时钟更新小数量水珠，目标约 30 fps；恢复会话时限制时间步长，避免瞬间跳跃。
- 当前水滴效果不需要 QtQuick.Particles；状态中 `rainStreaks` 为 false。
- 部分水珠带邻近小珠汇入的动画；这是视觉近似，不是流体物理模拟。
- 细水痕跟随滑落并淡出。水珠用透明轮廓和高光表现体积，不读取其他应用的画面，
  因此没有窗口文字的真实折射、背景放大或模糊。
- 每屏一个 `after-rain-weather` layer-shell surface，透明、空输入区域、无键盘焦点。
- Top 层，忽略保留区域，不挤占桌面布局，不启用 blur 或 above_lock。
- 当前屏幕 active workspace 全屏时卸载 renderer，退出全屏自动恢复；关闭也卸载动画。
- 屏幕由 `Quickshell.screens` 驱动。多屏与混合 DPI 需额外实机验证。
- 锁屏不会设置 above_lock，但尚未接入锁屏信号，不能声称锁屏期间动画计算归零。

## 代码

| 文件 | 职责 |
|---|---|
| `Core/RainController.qml` | 请求档位、原子持久化、状态查询、逐屏额度 |
| `Core/RainPolicy.js` | 枚举、状态校验、整数限额分配 |
| `Core/RainIpc.qml` | 独立 rain endpoint：setMode / toggle / status |
| `Effects/RainSlot.qml` | 每屏全屏状态与惰性加载、错误隔离 |
| `Effects/RainSurface.qml` | 透明输入穿透表面，纹理可用时才创建水珠动画 |
| `Effects/RainStreaks.qml` | 保留的雨丝实现；当前不加载 |
| `Effects/GlassDroplets.qml` | 有数量上限的水珠及水痕动画 |
| `Assets/glass-drop.svg` | 原创几何水珠，MIT 许可 |
| `Assets/rain-streak.svg` | 原创雨丝纹理，MIT 许可 |

档位按逻辑面积计算，超出总限额时按原始配额比例缩减，并用最大余数法分配整数额度。
下表为主水珠数上限（normal 当前约 20 颗）。
少量伴随小珠是同一主水珠的子图像，不创建独立物理对象。

| 档位 | 每逻辑 MP | 单屏下限 / 上限 | 全局上限 | 3440×1440 |
|---|---:|---:|---:|---:|
| light | 2 | 3 / 12 | 24 | 10 |
| normal | 4 | 6 / 24 | 48 | 20 |
| heavy | 7 | 9 / 42 | 84 | 35 |

状态文件由 `Quickshell.statePath("rain.json")` 定位，可从 status 的 statePath 获取。
使用 FileView 原子写入并手动校验 JSON；坏文件保持原样，回退 normal 并报告错误。
关闭、全屏和 kill switch 不会自动改写用户选择。

## 熔断

临时停用：`after-rain-shell rain off`。

如果 renderer 加载异常，可在 user service 的环境中设置 `AFTER_RAIN_EFFECT=off` 后重启。
该变量优先于状态文件，阻止 renderer 加载，不改写保存的档位。

## 验证

```bash
./scripts/validate.sh --portable
python3 scripts/test-rain-overlay.py
QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner \
  -input scripts/fixtures/tst_rainpolicy.qml
# 仅在本地 Wayland 会话运行：临时显示测试雨层。
python3 scripts/test-rain-runtime.py
```

自动化覆盖：档位、非法参数、30 屏额度硬上限、100 次切换、状态跨进程重启恢复、
kill switch 不改保存值、坏 JSON 保留、缺失 renderer import 和缺失纹理时 Shell 仍健康。
真实会话探针已验证鼠标移动/点击到达底层窗口、全屏抑制和退出后恢复。

当前 Shell 使用 AMD `renderD128`，NVIDIA 功耗不是此效果的渲染开销。
初步短采样（不是正式验收）：33 ms 更新版本的 Shell CPU 在 off 时接近 0，
normal 时平均约为单核的 1.6%；AMD `gpu_busy_percent` 却仍频繁接近 100%。
采样时桌面有其他应用运行，这不是独占基准，也不能直接换算成功耗或最高频率下的负载。
按水珠拆分小 layer surface 的试验未稳定改善 GPU 指标且增加 CPU 开销，未采用。
因此该版本属于可用的视觉预览，GPU 性能门槛尚未完成，低功耗使用可通过 `rain off` 关闭。
已部署到当前 user service，原配置备份位于
`/home/huitian/.local/state/after-rain-water-backup.u0aEPE`。
完整的帧时间、AMD GPU 功耗、多屏热插拔、锁屏和 suspend/resume 验收仍待专门测试；
不要把原始设计中的目标数字当作已经通过。
