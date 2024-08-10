name: Run_AdBlock_Rule_Generator_TXT.yml  # 工作流名称

on:
  schedule:
    - cron: '*/20 * * * *'  # 每20分钟运行一次
  workflow_dispatch:  # 允许手动触发工作流

jobs:
  build:
    runs-on: ubuntu-latest  # 使用最新的 Ubuntu 版本作为运行环境

    steps:
    - name: Checkout repository  # 检出代码仓库
      uses: actions/checkout@v3  # 使用官方的 checkout 操作来检出代码

    - name: Install PowerShell 7  # 安装 PowerShell 7
      run: |
        sudo apt-get update  # 更新包列表
        sudo apt-get install -y wget apt-transport-https software-properties-common  # 安装必要的包
        wget -q https://packages.microsoft.com/config/ubuntu/20.04/packages-microsoft-prod.deb  # 下载微软的包配置文件
        sudo dpkg -i packages-microsoft-prod.deb  # 安装包配置文件
        sudo apt-get update  # 更新包列表
        sudo apt-get install -y powershell  # 安装 PowerShell 7
        rm packages-microsoft-prod.deb  # 删除包配置文件

    - name: Check PowerShell Version  # 检查 PowerShell 版本
      run: pwsh -c '$PSVersionTable.PSVersion'  # 显示 PowerShell 版本

    - name: Run adblock_rule_generator_txt.ps1  # 运行 adblock_rule_generator_txt.ps1 脚本
      run: pwsh -File ./adblock_rule_generator_surge.ps1  # 使用 PowerShell 运行脚本

    - name: Force Add and Commit TXT file  # 强制添加并提交 TXT 文件
      run: |
        git config --global user.name 'github-actions'  # 配置提交用户名
        git config --global user.email 'github-actions@github.com'  # 配置提交邮箱
        git add -f adblock_reject_surge.txt  # 强制添加 adblock_reject_surge.txt 文件
        git commit -m 'Update adblock_reject_surge.txt' || git commit --allow-empty -m 'Empty commit to force push'  # 提交更改，若无更改则提交空更改

    - name: Retry Push TXT file  # 推送 TXT 文件，失败时重试
      env:
        TOKEN: ${{ secrets.GITHUB_TOKEN }}  # 使用 GitHub 密钥进行身份验证
      run: |
        for i in {1..5}; do  # 尝试最多5次
          git push --force origin HEAD && exit 0 || (echo "Push failed, retrying in 10 seconds..." && sleep 10)
        done
