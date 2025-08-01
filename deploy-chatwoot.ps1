# Chatwoot 部署脚本 for Windows
# 此脚本将安装必要的依赖项并部署Chatwoot

Write-Host "=== Chatwoot 部署脚本 ===" -ForegroundColor Green

# 检查是否以管理员身份运行
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "请以管理员身份运行此脚本" -ForegroundColor Red
    exit 1
}

# 1. 安装 Chocolatey (如果未安装)
Write-Host "检查 Chocolatey..." -ForegroundColor Yellow
if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "安装 Chocolatey..." -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

# 2. 安装 Docker Desktop
Write-Host "检查 Docker Desktop..." -ForegroundColor Yellow
if (!(Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Host "安装 Docker Desktop..." -ForegroundColor Yellow
    choco install docker-desktop -y
    Write-Host "Docker Desktop 已安装。请重启计算机并启动 Docker Desktop，然后重新运行此脚本。" -ForegroundColor Red
    exit 1
}

# 3. 检查 Docker 是否运行
Write-Host "检查 Docker 服务..." -ForegroundColor Yellow
try {
    docker version | Out-Null
    Write-Host "Docker 正在运行" -ForegroundColor Green
} catch {
    Write-Host "Docker 未运行。请启动 Docker Desktop 并重新运行此脚本。" -ForegroundColor Red
    exit 1
}

# 4. 安装 Docker Compose (如果需要)
Write-Host "检查 Docker Compose..." -ForegroundColor Yellow
try {
    docker-compose --version | Out-Null
    Write-Host "Docker Compose 可用" -ForegroundColor Green
} catch {
    Write-Host "安装 Docker Compose..." -ForegroundColor Yellow
    choco install docker-compose -y
}

# 5. 构建和启动 Chatwoot
Write-Host "构建和启动 Chatwoot 服务..." -ForegroundColor Yellow
Set-Location $PSScriptRoot

# 使用生产环境配置
Write-Host "使用生产环境配置启动服务..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yaml up -d --build

# 等待服务启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 6. 初始化数据库
Write-Host "初始化数据库..." -ForegroundColor Yellow
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:create
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:seed

Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host "Chatwoot 现在应该在 http://localhost:3000 上运行" -ForegroundColor Green
Write-Host "请使用以下命令创建管理员账号:" -ForegroundColor Yellow
Write-Host "docker-compose -f docker-compose.production.yaml exec rails bundle exec rails console" -ForegroundColor Cyan
Write-Host "然后在控制台中运行:" -ForegroundColor Yellow
Write-Host "User.create!(name: 'Gibson', email: 'gibson@localhost.com', password: 'Gibson888555', password_confirmation: 'Gibson888555', confirmed_at: Time.current)" -ForegroundColor Cyan
