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
git status --short
~~~

美术资产采用独立的保留权利条款。若未来希望让第三方自由再分发，应先由资产
权利人选择并写明独立许可，而不是让根目录 MIT 自动覆盖图片。
