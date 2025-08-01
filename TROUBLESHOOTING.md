# Chatwoot 连接问题故障排除指南

## 🚨 问题: "localhost 拒绝连线"

这个错误表示 Chatwoot 服务没有在端口 3000 上运行。以下是详细的故障排除步骤：

## 🔍 第一步：运行诊断脚本

```powershell
.\diagnose-connection.ps1
```

这个脚本会自动检查所有可能的问题并提供解决方案。

## 🛠 常见解决方案

### 解决方案 1: 安装 Docker Desktop (最推荐)

如果您还没有安装 Docker Desktop：

1. **下载 Docker Desktop**
   - 访问: https://www.docker.com/products/docker-desktop/
   - 下载 "Docker Desktop for Windows"

2. **安装步骤**
   ```
   1. 运行下载的安装程序
   2. 按照安装向导完成安装
   3. 重启计算机
   4. 启动 Docker Desktop
   5. 等待 Docker Desktop 完全启动（系统托盘图标变绿）
   ```

3. **验证安装**
   ```powershell
   docker --version
   docker-compose --version
   ```

4. **部署 Chatwoot**
   ```powershell
   .\quick-deploy.ps1
   ```

### 解决方案 2: 启动已安装的 Docker Desktop

如果 Docker Desktop 已安装但未运行：

1. **启动 Docker Desktop**
   - 在开始菜单中搜索 "Docker Desktop"
   - 点击启动
   - 等待完全启动（可能需要几分钟）

2. **验证 Docker 运行状态**
   ```powershell
   docker info
   ```

3. **启动 Chatwoot 服务**
   ```powershell
   .\quick-deploy.ps1
   ```

### 解决方案 3: 重置 Docker 和 Chatwoot

如果 Docker 运行但 Chatwoot 无法启动：

1. **完全重置**
   ```powershell
   .\quick-deploy.ps1 -Reset
   ```

2. **或手动重置**
   ```powershell
   # 停止所有容器
   docker-compose -f docker-compose.production.yaml down -v
   
   # 删除镜像
   docker-compose -f docker-compose.production.yaml down --rmi all
   
   # 重新构建和启动
   docker-compose -f docker-compose.production.yaml up -d --build
   ```

### 解决方案 4: 检查系统要求

确保您的系统满足以下要求：

- **操作系统**: Windows 10 64位 专业版、企业版或教育版 (Build 15063 或更高版本)
- **内存**: 至少 4GB RAM
- **虚拟化**: 启用 Hyper-V 或 WSL2
- **磁盘空间**: 至少 10GB 可用空间

### 解决方案 5: 启用 Windows 功能

1. **启用 Hyper-V** (Windows 10 专业版/企业版)
   ```
   1. 打开"控制面板" > "程序" > "启用或关闭Windows功能"
   2. 勾选"Hyper-V"
   3. 重启计算机
   ```

2. **或启用 WSL2** (Windows 10 家庭版也支持)
   ```powershell
   # 以管理员身份运行 PowerShell
   dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
   dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
   
   # 重启计算机后设置 WSL2 为默认版本
   wsl --set-default-version 2
   ```

## 🔄 替代部署方案

如果 Docker 无法正常工作，您可以考虑以下替代方案：

### 方案 A: 使用 Chatwoot 云服务 (最简单)

1. 访问 https://www.chatwoot.com/
2. 注册免费账号
3. 立即开始使用，无需本地安装

### 方案 B: 使用虚拟机

1. 安装 VirtualBox 或 VMware
2. 创建 Ubuntu 20.04 虚拟机
3. 在虚拟机中安装 Docker
4. 在虚拟机中部署 Chatwoot

### 方案 C: 使用 WSL2

1. 安装 WSL2 和 Ubuntu
2. 在 WSL2 中安装 Docker
3. 在 WSL2 中运行 Chatwoot

## 📞 获取帮助

### 检查服务状态
```powershell
# 查看所有容器状态
docker ps -a

# 查看 Chatwoot 服务日志
docker-compose -f docker-compose.production.yaml logs

# 查看特定服务日志
docker-compose -f docker-compose.production.yaml logs rails
```

### 常用诊断命令
```powershell
# 检查 Docker 版本
docker --version

# 检查 Docker 信息
docker info

# 检查端口占用
netstat -an | findstr ":3000"

# 检查 Docker Desktop 进程
Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
```

## ✅ 成功标志

当部署成功时，您应该看到：

1. **Docker 容器运行**
   ```
   docker ps 显示多个运行中的容器
   ```

2. **端口监听**
   ```
   netstat -an | findstr ":3000" 显示监听状态
   ```

3. **网页可访问**
   ```
   http://localhost:3000 显示 Chatwoot 登录页面
   ```

4. **管理员登录成功**
   ```
   邮箱: gibson@localhost.com
   密码: Gibson888555
   ```

## 🆘 紧急联系

如果所有解决方案都无法解决问题：

1. 运行完整诊断：`.\diagnose-connection.ps1`
2. 查看详细日志：`.\quick-deploy.ps1 -Logs`
3. 尝试替代方案：`.\alternative-deploy.ps1`

记住：最简单的解决方案通常是重新安装 Docker Desktop 并重启计算机。
