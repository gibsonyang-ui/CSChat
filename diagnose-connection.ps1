# Chatwoot 连接问题诊断脚本

Write-Host "=== Chatwoot 连接问题诊断 ===" -ForegroundColor Green
Write-Host ""

# 1. 检查Docker Desktop是否安装
Write-Host "1. 检查Docker Desktop安装状态..." -ForegroundColor Yellow

$dockerPaths = @(
    "C:\Program Files\Docker\Docker\Docker Desktop.exe",
    "C:\Program Files (x86)\Docker\Docker\Docker Desktop.exe",
    "$env:LOCALAPPDATA\Programs\Docker\Docker\Docker Desktop.exe"
)

$dockerInstalled = $false
foreach ($path in $dockerPaths) {
    if (Test-Path $path) {
        Write-Host "✓ 找到Docker Desktop: $path" -ForegroundColor Green
        $dockerInstalled = $true
        break
    }
}

if (-not $dockerInstalled) {
    Write-Host "✗ Docker Desktop 未安装" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 访问 https://www.docker.com/products/docker-desktop/" -ForegroundColor Cyan
    Write-Host "2. 下载并安装 Docker Desktop for Windows" -ForegroundColor Cyan
    Write-Host "3. 安装完成后重启计算机" -ForegroundColor Cyan
    Write-Host "4. 启动 Docker Desktop" -ForegroundColor Cyan
    exit 1
}

# 2. 检查Docker Desktop是否运行
Write-Host ""
Write-Host "2. 检查Docker Desktop运行状态..." -ForegroundColor Yellow

$dockerProcess = Get-Process -Name "Docker Desktop" -ErrorAction SilentlyContinue
if ($dockerProcess) {
    Write-Host "✓ Docker Desktop 进程正在运行" -ForegroundColor Green
} else {
    Write-Host "✗ Docker Desktop 进程未运行" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 启动 Docker Desktop 应用程序" -ForegroundColor Cyan
    Write-Host "2. 等待 Docker Desktop 完全启动（状态栏图标变绿）" -ForegroundColor Cyan
    Write-Host "3. 重新运行此诊断脚本" -ForegroundColor Cyan
    
    # 尝试启动Docker Desktop
    Write-Host ""
    Write-Host "尝试自动启动 Docker Desktop..." -ForegroundColor Yellow
    foreach ($path in $dockerPaths) {
        if (Test-Path $path) {
            Start-Process $path
            Write-Host "✓ 已启动 Docker Desktop，请等待其完全启动" -ForegroundColor Green
            break
        }
    }
    exit 1
}

# 3. 检查Docker命令是否可用
Write-Host ""
Write-Host "3. 检查Docker命令..." -ForegroundColor Yellow

try {
    $dockerVersion = docker --version 2>$null
    if ($dockerVersion) {
        Write-Host "✓ Docker 命令可用: $dockerVersion" -ForegroundColor Green
    } else {
        throw "Docker命令不可用"
    }
} catch {
    Write-Host "✗ Docker 命令不可用" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 重启 PowerShell 窗口" -ForegroundColor Cyan
    Write-Host "2. 确保 Docker Desktop 完全启动" -ForegroundColor Cyan
    Write-Host "3. 检查系统环境变量 PATH 中是否包含 Docker 路径" -ForegroundColor Cyan
    exit 1
}

# 4. 检查Docker服务状态
Write-Host ""
Write-Host "4. 检查Docker服务状态..." -ForegroundColor Yellow

try {
    docker info | Out-Null
    Write-Host "✓ Docker 服务正常运行" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker 服务未正常运行" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 重启 Docker Desktop" -ForegroundColor Cyan
    Write-Host "2. 检查 Docker Desktop 设置中的资源分配" -ForegroundColor Cyan
    Write-Host "3. 确保 Windows 功能中的 Hyper-V 或 WSL2 已启用" -ForegroundColor Cyan
    exit 1
}

# 5. 检查Chatwoot容器状态
Write-Host ""
Write-Host "5. 检查Chatwoot容器状态..." -ForegroundColor Yellow

$containers = docker-compose -f docker-compose.production.yaml ps 2>$null
if ($containers) {
    Write-Host "当前容器状态:" -ForegroundColor Cyan
    docker-compose -f docker-compose.production.yaml ps
} else {
    Write-Host "✗ 没有运行的Chatwoot容器" -ForegroundColor Red
    Write-Host ""
    Write-Host "解决方案:" -ForegroundColor Yellow
    Write-Host "1. 启动 Chatwoot 服务:" -ForegroundColor Cyan
    Write-Host "   .\quick-deploy.ps1" -ForegroundColor White
    Write-Host "2. 或手动启动:" -ForegroundColor Cyan
    Write-Host "   docker-compose -f docker-compose.production.yaml up -d" -ForegroundColor White
    exit 1
}

# 6. 检查端口占用
Write-Host ""
Write-Host "6. 检查端口3000占用情况..." -ForegroundColor Yellow

$port3000 = netstat -an | Select-String ":3000"
if ($port3000) {
    Write-Host "✓ 端口3000有服务监听:" -ForegroundColor Green
    $port3000 | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
} else {
    Write-Host "✗ 端口3000没有服务监听" -ForegroundColor Red
    Write-Host ""
    Write-Host "可能的原因:" -ForegroundColor Yellow
    Write-Host "1. Chatwoot Rails 服务未启动" -ForegroundColor Cyan
    Write-Host "2. 服务启动失败" -ForegroundColor Cyan
    Write-Host "3. 端口配置错误" -ForegroundColor Cyan
}

# 7. 检查Chatwoot Rails服务日志
Write-Host ""
Write-Host "7. 检查Chatwoot Rails服务日志..." -ForegroundColor Yellow

try {
    $railsLogs = docker-compose -f docker-compose.production.yaml logs rails --tail=20 2>$null
    if ($railsLogs) {
        Write-Host "Rails 服务最近日志:" -ForegroundColor Cyan
        Write-Host $railsLogs -ForegroundColor White
    } else {
        Write-Host "✗ 无法获取Rails服务日志" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 无法获取Rails服务日志" -ForegroundColor Red
}

# 8. 提供解决建议
Write-Host ""
Write-Host "=== 解决建议 ===" -ForegroundColor Green

Write-Host ""
Write-Host "如果服务未启动，请运行:" -ForegroundColor Yellow
Write-Host "  .\quick-deploy.ps1" -ForegroundColor Cyan

Write-Host ""
Write-Host "如果需要查看详细日志:" -ForegroundColor Yellow
Write-Host "  docker-compose -f docker-compose.production.yaml logs -f" -ForegroundColor Cyan

Write-Host ""
Write-Host "如果需要重新部署:" -ForegroundColor Yellow
Write-Host "  .\quick-deploy.ps1 -Reset" -ForegroundColor Cyan

Write-Host ""
Write-Host "如果问题持续，请检查:" -ForegroundColor Yellow
Write-Host "1. 系统资源是否充足 (至少4GB RAM)" -ForegroundColor Cyan
Write-Host "2. 防火墙是否阻止了端口3000" -ForegroundColor Cyan
Write-Host "3. 其他程序是否占用了端口3000" -ForegroundColor Cyan
