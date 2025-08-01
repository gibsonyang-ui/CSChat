# Chatwoot 替代部署方案
# 当Docker不可用时的本地部署选项

param(
    [switch]$CheckRequirements,
    [switch]$InstallDependencies,
    [switch]$StartLocal
)

Write-Host "=== Chatwoot 替代部署方案 ===" -ForegroundColor Green

if ($CheckRequirements) {
    Write-Host ""
    Write-Host "检查本地开发环境要求..." -ForegroundColor Yellow
    
    # 检查Ruby
    try {
        $rubyVersion = ruby --version 2>$null
        Write-Host "✓ Ruby: $rubyVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ Ruby 未安装" -ForegroundColor Red
    }
    
    # 检查Node.js
    try {
        $nodeVersion = node --version 2>$null
        Write-Host "✓ Node.js: $nodeVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ Node.js 未安装" -ForegroundColor Red
    }
    
    # 检查PostgreSQL
    try {
        $pgVersion = psql --version 2>$null
        Write-Host "✓ PostgreSQL: $pgVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ PostgreSQL 未安装" -ForegroundColor Red
    }
    
    # 检查Redis
    try {
        $redisVersion = redis-server --version 2>$null
        Write-Host "✓ Redis: $redisVersion" -ForegroundColor Green
    } catch {
        Write-Host "✗ Redis 未安装" -ForegroundColor Red
    }
    
    exit 0
}

# 主要的替代方案建议
Write-Host ""
Write-Host "当前Docker不可用，以下是替代方案:" -ForegroundColor Yellow
Write-Host ""

Write-Host "方案1: 安装Docker Desktop (推荐)" -ForegroundColor Cyan
Write-Host "1. 访问: https://www.docker.com/products/docker-desktop/" -ForegroundColor White
Write-Host "2. 下载并安装 Docker Desktop for Windows" -ForegroundColor White
Write-Host "3. 重启计算机" -ForegroundColor White
Write-Host "4. 启动 Docker Desktop" -ForegroundColor White
Write-Host "5. 运行: .\quick-deploy.ps1" -ForegroundColor White
Write-Host ""

Write-Host "方案2: 使用在线Chatwoot服务" -ForegroundColor Cyan
Write-Host "1. 访问: https://www.chatwoot.com/" -ForegroundColor White
Write-Host "2. 注册免费账号" -ForegroundColor White
Write-Host "3. 立即开始使用，无需本地安装" -ForegroundColor White
Write-Host ""

Write-Host "方案3: 本地开发环境 (高级用户)" -ForegroundColor Cyan
Write-Host "需要安装以下组件:" -ForegroundColor White
Write-Host "- Ruby 3.0+" -ForegroundColor White
Write-Host "- Node.js 16+" -ForegroundColor White
Write-Host "- PostgreSQL 12+" -ForegroundColor White
Write-Host "- Redis 6+" -ForegroundColor White
Write-Host "- Git" -ForegroundColor White
Write-Host ""

Write-Host "方案4: 使用WSL2 + Docker (Windows 10/11)" -ForegroundColor Cyan
Write-Host "1. 启用WSL2功能" -ForegroundColor White
Write-Host "2. 安装Ubuntu或其他Linux发行版" -ForegroundColor White
Write-Host "3. 在WSL2中安装Docker" -ForegroundColor White
Write-Host "4. 在WSL2中运行Chatwoot" -ForegroundColor White
Write-Host ""

Write-Host "方案5: 使用虚拟机" -ForegroundColor Cyan
Write-Host "1. 安装VirtualBox或VMware" -ForegroundColor White
Write-Host "2. 创建Ubuntu虚拟机" -ForegroundColor White
Write-Host "3. 在虚拟机中安装Docker" -ForegroundColor White
Write-Host "4. 在虚拟机中运行Chatwoot" -ForegroundColor White
Write-Host ""

# 诊断当前问题
Write-Host "=== 当前问题诊断 ===" -ForegroundColor Green
Write-Host ""

Write-Host "运行诊断脚本:" -ForegroundColor Yellow
Write-Host "  .\diagnose-connection.ps1" -ForegroundColor Cyan
Write-Host ""

Write-Host "常见问题和解决方案:" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Docker Desktop 未安装" -ForegroundColor Red
Write-Host "   解决: 下载并安装 Docker Desktop" -ForegroundColor Green
Write-Host ""

Write-Host "2. Docker Desktop 未启动" -ForegroundColor Red
Write-Host "   解决: 启动 Docker Desktop 应用程序" -ForegroundColor Green
Write-Host ""

Write-Host "3. Hyper-V 或 WSL2 未启用" -ForegroundColor Red
Write-Host "   解决: 在Windows功能中启用相应功能" -ForegroundColor Green
Write-Host ""

Write-Host "4. 端口3000被占用" -ForegroundColor Red
Write-Host "   解决: 关闭占用端口的程序或修改配置" -ForegroundColor Green
Write-Host ""

Write-Host "5. 防火墙阻止连接" -ForegroundColor Red
Write-Host "   解决: 在防火墙中允许端口3000" -ForegroundColor Green
Write-Host ""

Write-Host "6. 系统资源不足" -ForegroundColor Red
Write-Host "   解决: 确保至少有4GB可用内存" -ForegroundColor Green
Write-Host ""

# 快速修复建议
Write-Host "=== 快速修复步骤 ===" -ForegroundColor Green
Write-Host ""

Write-Host "步骤1: 检查Docker状态" -ForegroundColor Yellow
Write-Host "  Get-Process -Name 'Docker Desktop' -ErrorAction SilentlyContinue" -ForegroundColor Cyan
Write-Host ""

Write-Host "步骤2: 检查端口占用" -ForegroundColor Yellow
Write-Host "  netstat -an | Select-String ':3000'" -ForegroundColor Cyan
Write-Host ""

Write-Host "步骤3: 重启Docker Desktop" -ForegroundColor Yellow
Write-Host "  1. 右键点击系统托盘中的Docker图标" -ForegroundColor Cyan
Write-Host "  2. 选择 'Restart Docker Desktop'" -ForegroundColor Cyan
Write-Host ""

Write-Host "步骤4: 重新部署" -ForegroundColor Yellow
Write-Host "  .\quick-deploy.ps1 -Reset" -ForegroundColor Cyan
Write-Host ""

Write-Host "如果以上步骤都无法解决问题，建议使用方案1重新安装Docker Desktop。" -ForegroundColor Yellow
