# Chatwoot 快速部署脚本
# 前提: Docker Desktop 已安装并运行

param(
    [switch]$Reset,
    [switch]$Logs,
    [switch]$Stop
)

$ErrorActionPreference = "Stop"

Write-Host "=== Chatwoot 快速部署脚本 ===" -ForegroundColor Green

# 检查 Docker 是否可用
try {
    docker version | Out-Null
    Write-Host "✓ Docker 可用" -ForegroundColor Green
} catch {
    Write-Host "✗ Docker 不可用。请确保 Docker Desktop 已安装并运行。" -ForegroundColor Red
    Write-Host "下载地址: https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

# 设置工作目录
Set-Location $PSScriptRoot

if ($Stop) {
    Write-Host "停止 Chatwoot 服务..." -ForegroundColor Yellow
    docker-compose -f docker-compose.production.yaml down
    Write-Host "✓ 服务已停止" -ForegroundColor Green
    exit 0
}

if ($Logs) {
    Write-Host "显示服务日志..." -ForegroundColor Yellow
    docker-compose -f docker-compose.production.yaml logs -f
    exit 0
}

if ($Reset) {
    Write-Host "重置 Chatwoot 部署..." -ForegroundColor Yellow
    docker-compose -f docker-compose.production.yaml down -v
    docker-compose -f docker-compose.production.yaml down --rmi local
    Write-Host "✓ 重置完成" -ForegroundColor Green
}

# 检查 .env 文件
if (!(Test-Path ".env")) {
    Write-Host "✗ .env 文件不存在。请先运行部署准备脚本。" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 环境配置文件存在" -ForegroundColor Green

# 构建和启动服务
Write-Host "构建和启动 Chatwoot 服务..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yaml up -d --build

# 等待服务启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
$maxWait = 60
$waited = 0
do {
    Start-Sleep -Seconds 5
    $waited += 5
    Write-Host "等待中... ($waited/$maxWait 秒)" -ForegroundColor Yellow
    
    # 检查 Rails 服务是否响应
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Rails 服务已启动" -ForegroundColor Green
            break
        }
    } catch {
        # 继续等待
    }
} while ($waited -lt $maxWait)

if ($waited -ge $maxWait) {
    Write-Host "⚠ 服务启动超时，但可能仍在初始化中" -ForegroundColor Yellow
}

# 检查服务状态
Write-Host "检查服务状态..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yaml ps

# 初始化数据库
Write-Host "初始化数据库..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.production.yaml exec -T rails bundle exec rails db:create 2>$null
    docker-compose -f docker-compose.production.yaml exec -T rails bundle exec rails db:migrate
    docker-compose -f docker-compose.production.yaml exec -T rails bundle exec rails db:seed 2>$null
    Write-Host "✓ 数据库初始化完成" -ForegroundColor Green
} catch {
    Write-Host "⚠ 数据库初始化可能失败，请手动检查" -ForegroundColor Yellow
}

# 创建管理员账号
Write-Host "创建管理员账号..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.production.yaml exec -T rails bundle exec rails runner create_admin.rb
    Write-Host "✓ 管理员账号创建完成" -ForegroundColor Green
} catch {
    Write-Host "⚠ 管理员账号创建可能失败，请手动创建" -ForegroundColor Yellow
}

# 运行功能测试
Write-Host "运行功能测试..." -ForegroundColor Yellow
try {
    docker-compose -f docker-compose.production.yaml exec -T rails bundle exec rails runner test_chatwoot.rb
} catch {
    Write-Host "⚠ 功能测试可能失败，请手动检查" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host "Chatwoot 现在应该在以下地址运行:" -ForegroundColor Green
Write-Host "  主应用: http://localhost:3000" -ForegroundColor Cyan
Write-Host ""
Write-Host "管理员登录信息:" -ForegroundColor Green
Write-Host "  邮箱: gibson@localhost.com" -ForegroundColor Cyan
Write-Host "  密码: Gibson888555" -ForegroundColor Cyan
Write-Host ""
Write-Host "常用命令:" -ForegroundColor Yellow
Write-Host "  查看日志: .\quick-deploy.ps1 -Logs" -ForegroundColor Cyan
Write-Host "  停止服务: .\quick-deploy.ps1 -Stop" -ForegroundColor Cyan
Write-Host "  重置部署: .\quick-deploy.ps1 -Reset" -ForegroundColor Cyan
Write-Host "  用户管理: docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner manage_users.rb" -ForegroundColor Cyan
