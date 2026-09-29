# 发布

仓库名称建议保留为 **after-rain-hyprland**，避免让人误以为这是 Omarchy 官方项目。

安装并登录 GitHub CLI 后，在仓库根目录执行：

~~~bash
gh auth login
gh repo create after-rain-hyprland --public --source . --remote origin --push
~~~

发布前必须再次运行：

~~~bash
./scripts/validate.sh
python3 scripts/test-rainlight.py
python3 scripts/test-workspace.py
python3 scripts/test-input-method.py
./scripts/test-install-restore.sh
git status --short
~~~

本机没有 GitHub CLI 时，可以先生成可验证的离线仓库包：

~~~bash
git bundle create ../after-rain-hyprland.bundle --all
sha256sum ../after-rain-hyprland.bundle
~~~

也可以在 GitHub 网页创建空的公开仓库，再按页面给出的 SSH/HTTPS 地址设置
`origin` 并推送。不要把访问令牌写进 remote URL、命令历史或配置文件。

推荐发布 `v0.2.0` 标签，并在 Release 中附上 bundle 的 SHA-256、兼容版本和
`docs/ACCEPTANCE.zh-CN.md` 的验收结果。

美术资产采用独立的保留权利条款。若未来希望让第三方自由再分发，应先由资产
权利人选择并写明独立许可，而不是让根目录 MIT 自动覆盖图片。
