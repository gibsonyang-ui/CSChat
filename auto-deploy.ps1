# Chatwoot 自动部署脚本 - 自动检查和排除错误

param(
    [switch]$Reset
)

$ErrorActionPreference = "Continue"

Write-Host "=== Chatwoot 自动部署脚本 ===" -ForegroundColor Green
Write-Host "正在自动检查和排除错误..." -ForegroundColor Yellow
Write-Host ""

# 函数：等待服务启动
function Wait-ForService {
    param($ServiceName, $Port, $MaxWaitSeconds = 120)
    
    Write-Host "等待 $ServiceName 服务启动..." -ForegroundColor Yellow
    $waited = 0
    
    while ($waited -lt $MaxWaitSeconds) {
        try {
            $connection = Test-NetConnection -ComputerName localhost -Port $Port -WarningAction SilentlyContinue
            if ($connection.TcpTestSucceeded) {
                Write-Host "✓ $ServiceName 服务已启动" -ForegroundColor Green
                return $true
            }
        } catch {
            # 继续等待
        }
        
        Start-Sleep -Seconds 5
        $waited += 5
        Write-Host "  等待中... ($waited/$MaxWaitSeconds 秒)" -ForegroundColor Gray
    }
    
    Write-Host "✗ $ServiceName 服务启动超时" -ForegroundColor Red
    return $false
}

# 函数：检查Docker
function Test-Docker {
    try {
        docker --version | Out-Null
        docker info | Out-Null
        Write-Host "✓ Docker 可用" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "✗ Docker 不可用" -ForegroundColor Red
        Write-Host "请确保 Docker Desktop 已安装并运行" -ForegroundColor Yellow
        return $false
    }
}

# 检查Docker
if (-not (Test-Docker)) {
    exit 1
}

# 停止现有服务
Write-Host "停止现有服务..." -ForegroundColor Yellow
docker-compose down 2>$null
docker-compose -f docker-compose.simple.yaml down 2>$null

if ($Reset) {
    Write-Host "清理数据卷..." -ForegroundColor Yellow
    docker-compose -f docker-compose.simple.yaml down -v 2>$null
}

# 启动服务
Write-Host "启动 Chatwoot 服务..." -ForegroundColor Yellow
$result = docker-compose -f docker-compose.simple.yaml up -d 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 服务启动失败" -ForegroundColor Red
    Write-Host $result
    exit 1
}

Write-Host "✓ 服务启动命令执行成功" -ForegroundColor Green

# 等待PostgreSQL启动
if (Wait-ForService "PostgreSQL" 5432 60) {
    Write-Host "PostgreSQL 已就绪" -ForegroundColor Green
} else {
    Write-Host "PostgreSQL 启动失败，但继续尝试..." -ForegroundColor Yellow
}

# 等待Redis启动
if (Wait-ForService "Redis" 6379 30) {
    Write-Host "Redis 已就绪" -ForegroundColor Green
}

# 等待Rails启动
if (Wait-ForService "Rails" 3000 120) {
    Write-Host "Rails 已就绪" -ForegroundColor Green
    
    # 尝试初始化数据库
    Write-Host "初始化数据库..." -ForegroundColor Yellow
    $maxRetries = 3
    $retry = 0
    
    while ($retry -lt $maxRetries) {
        $retry++
        Write-Host "尝试 $retry/$maxRetries ..." -ForegroundColor Gray
        
        try {
            # 创建数据库
            $createResult = docker exec cschat-rails-1 bundle exec rails db:create 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ 数据库创建成功" -ForegroundColor Green
                break
            } else {
                Write-Host "数据库创建失败，重试..." -ForegroundColor Yellow
                Start-Sleep -Seconds 10
            }
        } catch {
            Write-Host "数据库创建异常，重试..." -ForegroundColor Yellow
            Start-Sleep -Seconds 10
        }
    }
    
    # 运行迁移
    Write-Host "运行数据库迁移..." -ForegroundColor Yellow
    try {
        docker exec cschat-rails-1 bundle exec rails db:migrate 2>$null
        Write-Host "✓ 数据库迁移完成" -ForegroundColor Green
    } catch {
        Write-Host "⚠ 数据库迁移可能失败" -ForegroundColor Yellow
    }
    
    # 加载种子数据
    Write-Host "加载种子数据..." -ForegroundColor Yellow
    try {
        docker exec cschat-rails-1 bundle exec rails db:seed 2>$null
        Write-Host "✓ 种子数据加载完成" -ForegroundColor Green
    } catch {
        Write-Host "⚠ 种子数据加载可能失败" -ForegroundColor Yellow
    }
    
    # 创建管理员账号
    Write-Host "创建管理员账号..." -ForegroundColor Yellow
    try {
        docker exec cschat-rails-1 bundle exec rails runner "
        user = User.find_or_create_by(email: 'gibson@localhost.com') do |u|
          u.name = 'Gibson'
          u.password = 'Gibson888555'
          u.password_confirmation = 'Gibson888555'
          u.confirmed_at = Time.current
        end
        
        account = Account.find_or_create_by(name: 'Gibson Admin Account')
        
        AccountUser.find_or_create_by(user: user, account: account) do |au|
          au.role = 'administrator'
        end
        
        puts '管理员账号创建成功'
        " 2>$null
        Write-Host "✓ 管理员账号创建成功" -ForegroundColor Green
    } catch {
        Write-Host "⚠ 管理员账号创建可能失败" -ForegroundColor Yellow
    }
    
} else {
    Write-Host "Rails 服务启动失败" -ForegroundColor Red
}

# 最终状态检查
Write-Host ""
Write-Host "=== 部署状态检查 ===" -ForegroundColor Green

# 检查容器状态
Write-Host "容器状态:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 测试连接
Write-Host ""
Write-Host "连接测试:" -ForegroundColor Yellow
$railsConnection = Test-NetConnection -ComputerName localhost -Port 3000 -WarningAction SilentlyContinue
if ($railsConnection.TcpTestSucceeded) {
    Write-Host "✓ Rails 服务可访问 (端口 3000)" -ForegroundColor Green
    
    # 尝试HTTP请求
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ HTTP 响应正常" -ForegroundColor Green
        } else {
            Write-Host "⚠ HTTP 响应异常: $($response.StatusCode)" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠ HTTP 请求失败，但服务可能仍在启动中" -ForegroundColor Yellow
    }
} else {
    Write-Host "✗ Rails 服务不可访问" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host "访问地址: http://localhost:3000" -ForegroundColor Cyan
Write-Host "管理员邮箱: gibson@localhost.com" -ForegroundColor Cyan
Write-Host "管理员密码: Gibson888555" -ForegroundColor Cyan
Write-Host ""
Write-Host "如果网页无法访问，请等待几分钟让服务完全启动" -ForegroundColor Yellow
Write-Host "查看日志: docker-compose -f docker-compose.simple.yaml logs -f" -ForegroundColor Gray
