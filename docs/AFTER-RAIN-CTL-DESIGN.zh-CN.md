# `after-rain-ctl` 设计

状态：设计提案；尚未实现。本文定义首版命令接口、readiness、状态所有权、运行态验证
和迁移约束。

## 目标

`after-rain-ctl` 是 After Rain 的稳定命令行控制面。首版解决快捷键 Profile，并提供
同一套检查驱动的系统 readiness 诊断：

```bash
after-rain-ctl profile list
after-rain-ctl profile current
after-rain-ctl profile set zh-pinyin
after-rain-ctl profile reset
after-rain-ctl doctor --profile zh-pinyin
```

它不是现有脚本的聚合菜单，也不提供任意命令、任意 Lua 模块或任意 systemd unit
执行入口。首版成功后，完整桌面 `reload`、主题、输入法和会话控制可以逐项迁入，但
每项都必须先形成自己的稳定数据模型。

设计目标：

1. 高频操作一条命令完成，适合人和脚本共同调用。
2. 不解析、不执行、不改写任意 `after_rain_local.lua`。
3. 明确区分磁盘上的 `configured` 与当前 Hyprland 会话的 `active`。
4. 每个变更先用新鲜证据检查当前系统是否具备所需能力。
5. 变更采用原子写入、应用验证和补偿回滚。
6. 每个失败都说明观察值、预期值、影响、修复方法和复验命令。
7. stdout 只输出数据；诊断、警告和错误只输出到 stderr。
8. 不引入新的 Python 包、Lua parser、Bats 或 CLI 框架依赖。

## 已知约束

### 本机 Lua 不能安全重写

`~/.config/hypr/after_rain_local.lua` 是用户拥有的可执行 Lua。它可能包含条件、函数、
重复字段、动态表或副作用。`sed`、正则替换或局部 AST 猜测都不能保证语义正确。

因此控制工具只拥有自己的纯数据文件，永远不格式化或修改本机 Lua。

### 配置状态不等于运行状态

Hyprland 可能尚未 reload、当前会话可能仍使用旧安装文件，reload 也可能返回后留下
`configerrors`。因此 `profile current` 必须分别报告：

- `configured`：持久配置希望选择什么；
- `active`：当前会话实际注册了什么；
- `synced`：两者是否已知且一致；
- `pending_reload`：已配置但尚未在当前会话证明生效。

查询到漂移是有效数据，不是查询失败；`profile current` 仍返回 0。

### Profile 变更不需要完整桌面重载

现有 `after-rain-reload` 还会重启 Waybar、Hyprpaper、Hypridle、通知、OSD、Portal 和
After Rain Shell。切换快捷键只应执行窄范围的 `hyprctl reload`，避免无关副作用。

### “存在”不等于“就绪”

`command -v Hyprland` 成功只能证明路径存在，不能证明动态库 ABI 匹配；配置文件存在
也不能证明当前 binary 能解析；进程存在不能证明 IPC、provider、输入引擎或快捷键已经
可用。readiness 必须逐层验证 capability，而不是罗列包名后输出一排 OK。

真实检查至少区分：

- executable discovery；
- executable 能否实际启动及其版本/ABI 自检；
- 已安装公共文件是否属于同一 control protocol；
- 实际 binary 对实际安装配置的 `--verify-config`；
- 当前 session 是否可连接、是否使用 Lua provider、是否有 config errors；
- live bindings 是否带有一致的 active Profile marker；
- 选中 Profile 依赖的 helpers、程序、输入法和桌面服务是否可用。

## 稳定命令接口

### 命令树

```text
after-rain-ctl [GLOBAL OPTIONS] doctor [--profile NAME] [--strict]
after-rain-ctl [GLOBAL OPTIONS] profile list [--fields FIELD,...]
after-rain-ctl [GLOBAL OPTIONS] profile current [--fields FIELD,...]
after-rain-ctl [GLOBAL OPTIONS] profile set NAME [--dry-run] [--no-reload] [--strict]
after-rain-ctl [GLOBAL OPTIONS] profile reset [--dry-run] [--no-reload] [--strict]
```

`reset` 删除控制工具拥有的选择，重新把控制权交还给旧本机 Lua 或默认值。它不能自动
删除 Lua 中的 `binding_profile`。

不用以下缩写：

```text
after-rain-ctl profile zh-pinyin
after-rain-ctl set profile zh-pinyin
```

`profile set NAME` 的 noun-verb 结构更可发现，也不会让 Profile 名称和未来子命令产生
歧义。

### 全局选项

```text
-h, --help
--version
--json
--plain
--no-color
-q, --quiet
-v, --verbose
-d, --debug
```

规则：

- `--json` 与 `--plain` 互斥；
- `--json` 隐含非交互、无颜色；
- `--quiet` 允许成功时不输出，供只检查退出码的脚本使用；
- 首版 Profile 操作不需要 prompt，因此不需要 `--yes`；
- `--dry-run` 只计算计划，不写文件、不 reload；
- `--no-reload` 只持久化，把运行态标为 deferred/pending；
- `--strict` 把所选 Profile 的 feature warning 提升为 blocker；
- `doctor` 汇总所有适用检查，不因第一个失败而停止；
- 测试 seam 不暴露为 `--config-root`、`--hyprctl-path` 等生产参数。

## Readiness 与针对性诊断

### 明确的支持矩阵

首版不承诺“任意 Linux + 任意 Hyprland”。它只对下面的组合给出可操作保证：

| 层 | v1 支持范围 | 判定 |
|---|---|---|
| 发行版 | Ubuntu 26.04.x | 读取 `/etc/os-release` 的 `ID`、`VERSION_ID` |
| compositor | Hyprland 0.56.x | 实际执行 `Hyprland --version`，不能只看文件名 |
| 配置 provider | Lua | live session 读取 `hyprctl systeminfo`；离线校验实际 Lua 入口 |
| 安装来源 | After Rain 安装器生成的 protocol v1 manifest | 校验协议、路径、文件类型和 SHA-256 |
| Python | Ubuntu 26.04 随系统提供的 Python 3 标准库 | 实际 import 首版使用的模块 |

Ubuntu 24.04、Arch、NixOS、Hyprland 0.55 或未来 0.57 都先报告
`PLATFORM_UNSUPPORTED` 或 `HYPRLAND_VERSION_UNSUPPORTED`，而不是套用 Ubuntu 26.04
包名继续执行 mutation。新增支持范围必须同时增加 fixture、预期探测输出、安装路径和
修复建议测试，不能只放宽版本比较。

Hyprland 是 deb 包、PPA 包还是源码安装不是硬编码条件。`dpkg-query` 查不到 owner 只作为
诊断证据；只要实际 binary、动态链接、版本、Lua 配置验证和 live IPC 全部通过，就可以
就绪。这样针对的是能力，不会把“源码安装”误判为故障。

### 一个 readiness 引擎，两种用途

`doctor` 和 mutation preflight 必须调用同一个 deep module：

```python
report = Readiness(files, probes).assess(intent)
```

`intent` 是封闭枚举，不接受任意 check 名称：

```text
Doctor(profile=<configured-or-explicit>)
ProfileRead
ProfileStage(name)     # --no-reload
ProfileApply(name)     # 默认 set/reset
```

这允许检查保持针对性：`ProfileStage` 不要求有 live session；`ProfileApply` 必须证明当前
session 可控制；`zh-pinyin` 会检查 IBus/libpinyin；Profile 中没有使用的完整桌面组件不会
阻止切换。每次 mutation 都重新探测，不复用上一次 `doctor` 的缓存结论。

### 状态语义

每个 check 只有四种结果：

| 状态 | 含义 |
|---|---|
| `PASS` | 已用当前证据证明所需 capability |
| `WARN` | 操作仍可完成，但明确的 Profile feature 会降级 |
| `BLOCK` | 无法安全持久化或无法诚实证明应用成功 |
| `SKIP` | 当前 intent 不适用，并必须说明原因 |

聚合状态：

| 聚合状态 | 含义 |
|---|---|
| `ready` | 所有适用检查通过 |
| `degraded` | 只有 warning；默认可继续，`--strict` 下阻止 mutation |
| `blocked` | 至少一个 blocker |
| `offline` | 静态条件可用，但要求 live session 的 intent 无法连接 |

`doctor` 永远跑完所有不依赖失败前置条件的检查。例如找不到 Hyprland binary 后跳过
`verify-config`，但仍继续检查安装 manifest 和 managed state；被跳过项要写明
`blocked_by=["hyprland.executable"]`，不能假装通过。

### 固定检查集

check ID、探测方法和严重级别是 v1 合约的一部分：

| Check ID | 精确探测 | `ProfileApply` 结果 |
|---|---|---|
| `platform.os` | 解析 `/etc/os-release`，精确匹配 Ubuntu 26.04.x | 不支持则 BLOCK |
| `identity.user` | `geteuid()!=0`，XDG 根目录 owner 与写权限符合当前用户 | 不符则 BLOCK |
| `state.target` | state/lock 父目录与目标逐段 `lstat`，拒绝 symlink/非普通文件 | 不符则 BLOCK |
| `install.protocol` | 固定位置读取 protocol token `after-rain-control-v1` | 缺失/版本错则 BLOCK |
| `install.manifest` | 校验 manifest schema、目标路径和关键文件 SHA-256 | 漂移/缺文件则 BLOCK |
| `hyprland.executable` | 解析唯一 binary，执行 `Hyprland --version` | 不能执行则 BLOCK |
| `hyprland.version` | 精确接受 0.56.x | 超出矩阵则 BLOCK |
| `hyprland.linkage` | 捕获 loader 的 missing library/undefined symbol；`ldd` 仅作补充证据 | ABI/库错误则 BLOCK |
| `config.verify` | 实际 binary 对实际安装的 `hyprland.lua --verify-config` | 非 0 或输出错误则 BLOCK |
| `session.identity` | signature、runtime dir 与 socket 同属当前用户且相互一致 | 无会话为 OFFLINE |
| `session.ipc` | 带短 timeout 的 `hyprctl version` 和 `hyprctl -j binds` | 不可连接则 OFFLINE |
| `session.provider` | `hyprctl systeminfo` 明确报告 Lua provider | 非 Lua 则 BLOCK |
| `session.configerrors` | mutation 前 `hyprctl configerrors` 为空 | 非空则 BLOCK |
| `profile.marker` | live bind marker 协议为 v1 且所有 marker 唯一 | 缺失/混合则 BLOCK |
| `profile.helpers` | 从固定 Profile capability 表检查实际绑定引用的 helper | 缺核心 helper 为 BLOCK |
| `profile.features` | 检查所选 Profile 的可选程序/服务 | 缺失为 WARN |
| `input.ibus` | `ibus engine` 可通信，engine catalog 精确包含 `libpinyin` | `zh-pinyin` 下 WARN |

`command -v` 只能用于定位候选路径，不能单独产生 PASS。`pgrep` 只能提供 evidence，不能
证明 IPC 或 feature 健康。所有 subprocess 使用固定 argv、`shell=False`、清理过的环境和
每项 1–3 秒的 timeout；检查不访问网络、不安装包、不启动/重启服务、不调用 sudo。

### 安装 protocol 与 manifest

安装器必须生成：

```text
${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland/install-manifest.json
```

manifest 至少包含：

```json
{
  "schema_version": 1,
  "control_protocol": "after-rain-control-v1",
  "hyprland_compat": "0.56.x",
  "files": {
    "hyprland.lua": {"path": "/home/user/.config/hypr/hyprland.lua", "sha256": "..."},
    "bindings.lua": {"path": "/home/user/.config/hypr/after_rain/bindings.lua", "sha256": "..."},
    "profile_lib": {"path": "/home/user/.config/hypr/after_rain/binding_profiles/lib.lua", "sha256": "..."}
  }
}
```

只把公共、安装器拥有的关键文件纳入 hash；绝不 hash 或覆盖
`after_rain_local.lua`、managed profile 和 custom bindings。CLI 不依赖仓库 checkout，
而是用这份安装时证据发现“入口是新版、profile 模块仍是旧版”之类的部分升级。

### Profile capability 表

依赖由 CLI 内置的封闭表定义，并与 Lua Profile 做 contract test，不从 Lua 文本动态猜测：

| 能力 | standard | zh-pinyin | minimal | 缺失影响 |
|---|:---:|:---:|:---:|---|
| `after-rain-shell`、`rainlight`、终端、文件管理器 | ✓ | ✓ | ✓ | 对应快捷键 WARN；控制协议本身不阻断 |
| `after-rain-input-toggle` | ✓ | ✓ | ✓ | BLOCK，三套 Profile 都声明输入切换 |
| IBus IPC + `libpinyin` engine | — | ✓ | — | WARN；`--strict` 时 BLOCK |
| `hyprshot` | ✓ | ✓ | ✓ | 截图快捷键 WARN |
| `swayosd-client` | ✓ | ✓ | ✓ | 媒体键 WARN |
| `swaync-client`、`wlogout` | ✓ | ✓ | — | 对应通知/电源快捷键 WARN |
| `after-rain-wallpaper` | ✓ | ✓ | — | 下一张壁纸快捷键 WARN |

这个表故意不把 Waybar、Hyprpaper、Portal、字体或整个 Shell 服务的健康状态变成 Profile
切换 blocker；它们属于完整桌面 doctor 的未来 scope。v1 的每条结论都应能回答“这会让
哪一个即将启用的快捷键失效”。

`custom` 是唯一无法从固定表得出 feature 依赖的 Profile。v1 对它只证明文件安全、Lua
配置可加载和 marker 可激活，并固定产生 `profile.custom_dependencies= WARN`，说明 CLI
无法预判 custom binding 调用的外部程序；`--strict` 因而拒绝 custom。以后若确有需求，
应设计一个纯数据、白名单字段的 custom capability sidecar，不能通过执行或正则解析用户
Lua 来恢复“灵活性”。

### 当前主机上的必要反例

2026-09-30 的只读探测给出了一个必须进入回归测试的假健康场景：Ubuntu 26.04、
Hyprland 0.56.2、实际安装配置的 `--verify-config` 和旧 `after-rain-doctor` 都返回成功，
但安装目录中的 `after_rain/bindings.lua` 已与仓库漂移，四个
`binding_profiles/*.lua` 文件缺失，live bindings 的 v1 marker 数为 0。

因此新 doctor 必须把它报告为 `install.manifest=BLOCK` 和
`profile.marker=BLOCK`。单独通过 binary、配置语法、服务进程和旧 doctor，不能覆盖这个
结论。这也是 install manifest 被列为 v1 前置协议、而不是以后再加的原因。

### 启发性修复建议

每项结果使用固定 schema：

```json
{
  "id": "config.verify",
  "status": "BLOCK",
  "summary": "已安装的 Hyprland 无法加载已安装的 Lua 配置",
  "observed": "undefined symbol: ...",
  "expected": "Hyprland 0.56.x returns 0 from --verify-config",
  "impact": "profile 文件即使写入，也不能安全 reload",
  "evidence": ["binary=/usr/bin/Hyprland", "config=/home/user/.config/hypr/hyprland.lua"],
  "fixes": [{
    "description": "先修复 Hyprland 与 libhypr* 的 ABI 一致性，再复验",
    "verify": "Hyprland --config ~/.config/hypr/hyprland.lua --verify-config",
    "privilege": "may-require-admin"
  }]
}
```

建议优先给项目内、可逆、无需提权的精确动作，例如重新运行 `scripts/install.sh` 修复
manifest 漂移。只有 `apt-cache policy PACKAGE` 已确认 Ubuntu 26.04 当前源存在候选版本时，
才显示精确 `apt install` 建议；否则只说明缺少的 capability 和查证方法。CLI 绝不自动执行
建议，也不把未经验证的发行版包名复制到其他系统。

## 持久化模型

### 控制工具拥有的文件

```text
${XDG_CONFIG_HOME:-$HOME/.config}/hypr/after_rain_control/profile
```

内容严格为一个 ASCII token 加换行：

```text
zh-pinyin
```

允许值：

```text
standard
zh-pinyin
minimal
custom
```

单值状态无需 JSON、TOML 或另一份可执行 Lua。单行 token 可以由 Python 和 Lua 严格
解析、完整覆盖并原子恢复。

文件必须满足：

- 是当前用户拥有的普通文件；
- 不是 symlink；
- 只含一个允许值和一个 LF；
- 非法内容 hard fail，不静默回退；
- 安装器和升级流程永不覆盖。

### 选择优先级

```text
after_rain_control/profile
    > after_rain_local.lua 中的 legacy binding_profile
    > standard
```

控制文件不存在时，现有行为完全不变。控制文件存在时，legacy `binding_profile` 被
shadow，但 `programs`、`monitors` 等其他本机设置继续生效。

### Catalog

首版 Profile catalog 是静态白名单。Lua loader 和 Python CLI 各自保留一个小型映射，
并由 contract test 强制一致。不要动态扫描并加载任意模块，也不要把用户输入拼进
`require()`。

`custom` 始终只对应固定文件：

```text
~/.config/hypr/after_rain_bindings.lua
```

文件不存在时，`profile list` 显示 `available=false`；`profile set custom` 返回配置错误。

## 运行态身份

### 不用按键指纹猜测

不同 Profile 当前恰好拥有不同按键，不代表这种差异是稳定接口。不能通过查找
`Super+G`、`Super+Q` 等组合猜测 active Profile。

### Binding marker

Profile loader 在调用共享 `keys.bind` 前设置当前 Profile。每一条由共享库注册的绑定在
现有可见描述后加入机器标记：

```text
[010|常用应用] [arp:v1:zh-pinyin] 打开 Rainlight
```

GTK 和 Quickshell 帮助界面解析并隐藏 `[arp:v1:...]`；`after-rain-ctl` 从
`hyprctl -j binds` 读取它。

判断规则：

- 所有标记一致：active Profile 已证明；
- 没有标记：旧安装或不可识别运行态，`active=null`；
- 出现多个不同标记：运行态不一致，返回结构化错误；
- custom 也必须通过共享 binding 库注册，从而得到 `custom` 标记。

marker 比 last-apply 缓存更可靠，因为它直接来自当前 Hyprland 已注册的绑定。缓存只能
证明工具过去做过什么，不能证明用户之后没有手工修改或 reload。

## 状态模型

`profile current` 返回：

```json
{
  "ok": true,
  "schema_version": 1,
  "data": {
    "configured": {
      "name": "zh-pinyin",
      "source": "managed",
      "path": "/home/user/.config/hypr/after_rain_control/profile"
    },
    "active": {
      "name": "standard",
      "source": "hyprctl-binds-v1"
    },
    "synced": false,
    "pending_reload": true
  }
}
```

状态来源：

| `configured.source` | 含义 |
|---|---|
| `managed` | 控制文件存在，值精确可知 |
| `default` | 控制文件和本机 Lua 都不存在，值为 `standard` |
| `legacy-unmanaged` | 控制文件不存在且存在任意本机 Lua，CLI 不猜其结果 |

运行态：

| 状态 | 含义 |
|---|---|
| `synced` | configured 与 active 已知且相同 |
| `pending_reload` | configured 已知，但 active 不同或不可证明 |
| `offline` | 没有可访问的 Hyprland 会话，active 为 null |
| `inconsistent` | live bindings 中出现不同 marker |

没有 ctl 文件但存在 arbitrary local Lua 时，`configured.name=null`。即使 live marker 能
说明当前 active，也不能证明磁盘 Lua 在上次 reload 后没有改变。

## `profile set` 事务

默认 `set` 的顺序固定：

1. 解析参数并一次性决定输出模式。
2. 验证 NAME、catalog、custom 前置条件和受管文件格式。
3. 依据 intent 执行完整 readiness；收集所有 blocker 和 warning。
4. 默认操作若没有健康的 live session，在任何写入前以 75 退出，并建议显式使用
   `--no-reload` 暂存；不能擅自把“立即应用”降级为 deferred。
5. 读取当前 active 状态并计算完整 plan。
6. 若为 `--dry-run`，返回计划；若 readiness blocked，仍以对应非零码退出。
7. 获取独占锁，并重新读取 managed state 及所有会受竞态影响的 readiness 检查。
8. 保存旧文件的精确字节、权限和“原先不存在”状态。
9. 在目标目录创建临时文件，写入、flush、`fsync`、`os.replace`，再 `fsync` 父目录。
10. `--no-reload` 返回成功，activation 为 `deferred`。
11. 用固定 argv、`shell=False` 执行 `hyprctl reload`。
12. 即使 reload 返回 0，也读取 `hyprctl configerrors`。
13. 轮询 `hyprctl -j binds`，直到目标 marker 生效或达到短超时。
14. 失败时原子恢复旧文件，再 reload 并尽量确认旧 marker。
15. 返回结构化结果，明确 persisted 与 active 各自是否恢复。

这不是跨文件系统和 Hyprland 的数据库事务，而是：

```text
原子持久化 + 运行态验证 + 补偿回滚
```

进程若在文件替换后、reload 前退出，磁盘文件仍完整有效；下一次 `profile current` 会把
它报告为 pending，而不是误报 synced。

### 幂等行为

- configured 与 active 都已是目标：成功 no-op，不写文件、不 reload；
- configured 已是目标但 active 不同：默认重新 reload 以 reconcile；
- `--no-reload`：执行静态 readiness，只保证 configured，并明确返回 deferred；
- `reset` 在控制文件不存在时：成功 no-op；
- 默认命令没有 Hyprland 会话：写入前失败；只有显式 `--no-reload` 才允许暂存。

### 锁

写操作使用：

```text
${XDG_STATE_HOME:-$HOME/.local/state}/after-rain-hyprland/ctl.lock
```

锁覆盖写入、reload、验证和回滚。锁竞争发生在 mutation 前，可安全重试。

## 输出合约

### Stream

- stdout：请求的 primary data；
- stderr：警告、进度、诊断和错误；
- handler 不打印、不调用 `exit()`；
- 只有 CLI adapter 格式化、写 stream 和设置退出码。

### Human

```text
Profile switched: standard -> zh-pinyin
Configured: zh-pinyin
Active:     zh-pinyin
Status:     synced
```

Human 输出可在小版本中改进。

`doctor` 的 human 输出先给结论，再给可执行建议，并保留稳定 check ID：

```text
After Rain readiness: BLOCKED (profile: zh-pinyin)
PASS  hyprland.version     Hyprland 0.56.2 is supported
BLOCK install.manifest    4 profile files are missing from the installed config
WARN  input.ibus           libpinyin is not available in the current IBus catalog

Impact: reload cannot prove which profile was activated.
Fix:    run /path/to/after-rain-hyprland/scripts/install.sh
Verify: after-rain-ctl doctor --profile zh-pinyin
```

这不是“所有依赖都 OK/MISS”的清单；默认只显示 summary、非 PASS 项及其建议，`-v` 再显示
全部 PASS/evidence，`--debug` 才显示探测 argv、timeout 和截断后的原始输出。

### Plain

`--plain` 是稳定 TSV/逐行接口。配合 `--fields name` 时只输出所选字段：

```bash
after-rain-ctl --plain profile list --fields name
```

```text
standard
zh-pinyin
minimal
custom
```

`profile current --plain` 默认输出：

```text
configured	zh-pinyin	managed
active	standard	hyprctl-binds-v1
synced	false
pending_reload	true
```

### JSON

成功时 stdout 只含一个版本化 envelope：

```json
{"ok":true,"schema_version":1,"data":{"name":"zh-pinyin","activation":"reloaded"}}
```

任何非零退出时 stdout 为空，stderr 最后一个非空行是 error envelope：

```json
{"ok":false,"schema_version":1,"error":{"code":"RELOAD_FAILED","message":"Hyprland did not activate profile zh-pinyin","fix":"Run `after-rain-ctl profile current` and `hyprctl configerrors`.","transient":false}}
```

JSON field、plain column、flag 和退出码一旦发布就是接口合约；后续只做 additive change。

`doctor --json` 的 `data` 固定包含 `intent`、`overall`、`target_profile` 和 `checks[]`。
`doctor --plain` 每项固定输出 `status<TAB>id<TAB>summary`，便于 shell 按 check ID 过滤。
诊断中的路径、版本和命令来自实际探测；不在 renderer 内临时拼凑猜测。

## 退出码与错误

| Code | 含义 | 示例 |
|---:|---|---|
| `0` | 成功，包括 no-op、允许的 dry-run/deferred、查询到漂移；doctor 为 ready/degraded | — |
| `1` | Domain mutation、应用或补偿回滚失败 | `RELOAD_FAILED` |
| `2` | 参数或用法错误 | `UNKNOWN_PROFILE` |
| `78` | 配置、安装或受管状态错误 | `PROFILE_STATE_INVALID` |
| `75` | mutation 前的暂时性、明确可安全重试失败 | `STATE_LOCK_BUSY`、`HYPRLAND_SESSION_UNAVAILABLE` |
| `130` | SIGINT | — |

`doctor` 的 `degraded` 默认返回 0，配合 `--strict` 返回 1；`blocked` 和当前 intent 要求
live session 时的 `offline` 返回 1。`doctor` 即使发现安装/配置问题也要先输出完整 checks，
不因某项通常映射到 78 就提前终止。

主要错误码：

```text
UNKNOWN_PROFILE
ARGUMENT_CONFLICT
CUSTOM_PROFILE_MISSING
PROFILE_STATE_INVALID
PROFILE_CATALOG_MISMATCH
PLATFORM_UNSUPPORTED
RUN_AS_ROOT
INSTALL_PROTOCOL_MISSING
INSTALL_MANIFEST_MISMATCH
HYPRLAND_NOT_FOUND
HYPRLAND_VERSION_UNSUPPORTED
HYPRLAND_RUNTIME_LINKAGE
CONFIG_VERIFY_FAILED
HYPRLAND_SESSION_UNAVAILABLE
CONFIG_PROVIDER_UNSUPPORTED
PROFILE_DEPENDENCY_MISSING
IBUS_ENGINE_MISSING
ACTIVE_PROFILE_INCONSISTENT
STATE_LOCK_BUSY
STATE_WRITE_FAILED
PREEXISTING_CONFIG_ERROR
RELOAD_FAILED
ACTIVE_PROFILE_UNCONFIRMED
ROLLBACK_FAILED
```

一旦新文件已经 replace 或 reload 已 dispatch，即使故障原因看起来是暂时性的，也不能
返回 75 或建议盲目重试。

## 模块与 seam

### 外部 seam

控制逻辑是一个 deep module：

```python
readiness = Readiness(files, probes).assess(intent)
result = ProfileControl(files, hyprland, readiness).execute(request)
```

`request` 是封闭的 `doctor | list | current | set | reset` 联合类型。`execute()` 返回结构化
结果或结构化错误，不打印也不退出。

它隐藏：

- 支持矩阵、固定 check graph、timeout 与严重级别；
- protocol/manifest、binary/ABI、离线配置和 live session capability；
- check evidence、影响、修复和复验建议；
- Profile catalog 与 availability；
- managed/legacy/default precedence；
- XDG 路径解析；
- 文件安全检查、锁、原子 replace 和 fsync；
- configured/active/synced 状态合并；
- dry-run plan；
- reload、configerrors、marker 验证和回滚；
- error 到退出码的映射。

删除这个模块后，上述复杂度会重新散落到每个调用者，符合 deep module 的 deletion
test。

### 内部 seam

只有实际存在多个 adapter 的依赖才建立内部 seam。

#### Filesystem

- 生产：真实 POSIX 文件、`fcntl.flock`、`os.replace` 和 `fsync`；
- 测试：相同实现运行在临时 XDG 根目录；需要故障注入时使用窄 fake。

#### Hyprland runtime

```text
session_identity()
config_provider()
config_errors()
reload_config()
active_profile()
```

- 生产 adapter：固定 `hyprctl` argv；
- 测试 adapter：scripted fake，模拟成功、timeout、旧 marker、混合 marker和回滚失败。

#### Targeted probes

readiness 内部允许一个窄 `SystemProbes` adapter，只暴露设计中已经命名的探测：

```text
os_release()
executable_version()
verify_installed_config()
loader_diagnostics()
installed_manifest()
ibus_engines()
profile_feature(NAME)
```

生产实现的 argv 和解析器逐项固定；测试 fake 返回已分类的 observation。它不接受调用者
传入 shell 字符串、任意 argv、任意包名或任意 systemd unit，避免 readiness 演变成第二个
shell。

不提供接受任意 argv 的公共 `CommandRunner`。未来 systemd 真正有第二个生产/测试
adapter 时再加入，不提前制造 hypothetical seam。

### 实现形态

首版使用单个 Python 标准库可执行文件：

```text
bin/after-rain-ctl
```

内部可以有 dataclass 和私有类，但暂不为了架构图引入安装期 Python package。仓库当前
已经使用 Python CLI 和临时目录/fake command 测试，这种形态与现有发布方式一致。

## 安装与兼容迁移

### 新安装

1. 安装 `after-rain-ctl`。
2. 安装器在所有公共文件落盘并校验后，最后原子生成 control protocol manifest。
3. 新版 `after_rain_local.lua.example` 不再包含 `binding_profile`。
4. 只有确认是全新安装时，创建 managed profile，默认 `standard`。
5. 安装器、备份器和恢复器记录 managed profile 与 manifest，但以后升级不覆盖 profile。

### 升级

1. 更新 Lua loader，使 managed 文件存在时优先读取；不存在时保持原有逻辑。
2. 已存在 `after_rain_local.lua` 且没有 managed profile 时，不自动创建 `standard`，避免
   覆盖用户原有选择。
3. 首次 `profile set NAME` 创建 managed profile，并在 stderr 告知 legacy
   `binding_profile` 现在被 shadow。
4. `profile reset` 删除 managed 文件，立即恢复 legacy/default precedence。
5. 升级只有在所有关键文件安装成功后才替换 manifest；失败恢复旧文件和旧 manifest。
6. 旧的手工编辑方式在兼容期继续有效；新文档推荐使用 CLI。

### 旧命令迁移

首版不重写现有 `after-rain-reload`，但会把与 Profile 控制相关的旧 doctor 检查迁入
结构化 readiness。旧 `after-rain-doctor` 在兼容期成为调用 `after-rain-ctl doctor` 的
薄 wrapper，不能继续维护另一份 required command 列表。

未来顺序：

1. 实现针对 Profile 的结构化 readiness records；
2. 让旧 `after-rain-doctor` 成为兼容 wrapper；
3. 把完整桌面 reload 逻辑迁入结构化 handler；
4. 让旧 `after-rain-reload` 成为兼容 wrapper；
5. 再逐项考虑 theme、input、session 的独立 scope。

不要让新 CLI 执行旧脚本并解析其 human stdout；那会把不稳定文本误当内部协议。

## 测试契约

测试以 `Readiness`、`ProfileControl` interface 和 CLI subprocess 为主要表面：

### Readiness

- Ubuntu 26.04.x + Hyprland 0.56.x fixture 才进入 supported；
- 只放宽版本判断、却没有对应 fixture 时 contract test 失败；
- binary 路径存在但执行报 missing library/undefined symbol 时 BLOCK；
- `ldd` 看似完整但 `--version` 或 `--verify-config` 失败时仍 BLOCK；
- 实际安装配置验证失败时报告 binary、config、影响和复验命令；
- manifest 缺失、hash 漂移、部分升级、未知 schema 分别产生稳定 check ID；
- 旧式 `command -v` 检查全部通过但 Profile 模块未安装时仍 BLOCK；
- root、错误 owner、symlink、不可写 XDG 目录在 mutation 前被拒绝；
- 无 session 时 `ProfileStage` 跳过 live checks，`ProfileApply` 为 offline；
- signature、socket owner 或 runtime dir 不一致时不连接可疑 IPC；
- IPC timeout、非 Lua provider、已有 configerrors、旧 marker、混合 marker 分别诊断；
- `zh-pinyin` 缺少 libpinyin 为 WARN，`--strict` 时阻止 mutation；
- 缺少与目标 Profile 无关的桌面组件不阻止 Profile mutation；
- 每个 BLOCK/WARN 都有 impact，至少一个 fix 或明确的人工查证动作，以及 verify；
- 所有检查 bounded timeout、无网络、无 sudo、无写入和无服务重启。

### ProfileControl

- list 返回固定 catalog 与 custom availability；
- 未知 Profile 在任何写入前失败；
- 任意 Lua 从不被改写；
- managed state 非法时 fail closed；
- dry-run 无文件和 runtime 副作用；
- dry-run 在 readiness blocked 时仍非零，并输出本来会执行的 plan；
- 同状态幂等；
- configured 相同但 active 不同会 reload；
- 默认命令无会话时在写盘前返回 75；显式 `--no-reload` 才写盘并返回 deferred；
- mutation 获取锁后重跑竞态敏感 readiness；
- 变更前已有 `configerrors` 时不写盘；
- reload 返回 0 但 `configerrors` 非空仍失败；
- marker 未变化时恢复旧文件；
- 回滚成功与回滚失败分别报告；
- reset 恢复 legacy/default precedence；
- symlink、非普通文件和非当前用户 owner 被拒绝；
- 并发 mutation 只允许一个持锁者。

### CLI contract

- human、plain、JSON 的 stdout/stderr 分离；
- JSON success 可直接由 `jq` 解析；
- JSON failure 的 stdout 为空，stderr 最后一行可解析；
- piped/plain 输出无 ANSI；
- flags 冲突返回 2；
- `NO_COLOR`、`TERM=dumb` 与 `--no-color` 生效；
- `--help` 包含真实示例、allowed values 和退出码。
- doctor 聚合多个失败而不是 fail-fast；
- doctor 默认/strict 的 degraded 退出码分别为 0/1；
- doctor JSON 每个 check schema 稳定，plain 列顺序稳定；
- unsupported 平台不输出未经确认的 apt 包安装命令。

### Lua/运行态 contract

- managed 文件优先级正确；
- managed 文件不存在时旧配置不变；
- 非法 token 使配置验证失败；
- Profile 名只通过固定白名单映射；
- 每套 Profile 的 live description 带一致 marker；
- GTK 与 Quickshell 隐藏 marker；
- `Hyprland --verify-config` 对每个内置 Profile 和 custom example 通过。

## 明确拒绝的方案

1. 用 `sed` 或正则编辑 `after_rain_local.lua`。
2. 为了读配置而执行用户 Lua。
3. 再创建一份通用、可执行的 managed Lua。
4. 暴露 `config set KEY VALUE` 这类 stringly-typed 万能入口。
5. 动态扫描插件或允许任意 `require()` 路径。
6. Profile 切换时调用完整 `after-rain-reload`。
7. 通过某几个按键组合猜 active Profile。
8. 只依赖 last-apply receipt 声称当前已生效。
9. 用 `command -v`、`pgrep` 或包已安装直接宣告 capability ready。
10. 为“支持所有 Linux”输出未经目标发行版验证的包名和修复命令。
11. 新 CLI 执行旧 doctor 并解析它的 human stdout。
12. 首版一次性重写 reload、完整桌面 doctor、input 和 session 控制。
13. 为首个 Python CLI 引入新的外部包或另一套 Bats 测试体系。

## 实施阶段

### Phase 1：支持矩阵与 readiness 契约

- 固定 Ubuntu 26.04.x / Hyprland 0.56.x 支持矩阵；
- 实现 targeted probes、check graph、状态聚合和 advice schema；
- 安装器原子生成 protocol manifest，备份/恢复一并覆盖；
- 用当前主机的“命令都存在但安装文件部分漂移”建立回归 fixture。

### Phase 2：状态和运行态契约

- 加入 managed profile reader；
- 保留 legacy fallback；
- 给 live bindings 加 marker；
- 更新 GTK/Quickshell parser 和 contract tests。

### Phase 3：CLI deep module

- 实现 `doctor` 与 `profile list/current/set/reset`；
- 实现 human/plain/JSON output；
- 实现原子写入、锁、reload 验证和补偿回滚；
- 增加 interface 与 subprocess 测试。

### Phase 4：安装、恢复和文档

- 安装 `after-rain-ctl`；
- 处理新安装与升级差异；
- 把 managed profile 与 install manifest 纳入备份/恢复；
- 让 `after-rain-doctor` 成为兼容 wrapper；
- 更新 README、安装、架构、故障排查和 changelog。

### Phase 5：后续控制面

在 Profile Interface 稳定后，再分别设计完整桌面 `reload` 与额外 doctor scope。只有当
对应旧脚本的逻辑已经返回结构化结果时，才让旧命令成为新 CLI 的兼容 wrapper。
