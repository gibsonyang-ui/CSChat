# Chatwoot 服务监控脚本

param(
    [switch]$Continuous,
    [int]$Interval = 30
)

function Test-ChatwootHealth {
    Write-Host "=== Chatwoot 健康检查 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ===" -ForegroundColor Green
    
    # 检查容器状态
    Write-Host "1. 容器状态:" -ForegroundColor Yellow
    $containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host $containers
    
    # 检查端口连接
    Write-Host "`n2. 端口连接测试:" -ForegroundColor Yellow
    
    # 测试端口3000
    try {
        $railsTest = Test-NetConnection -ComputerName localhost -Port 3000 -WarningAction SilentlyContinue
        if ($railsTest.TcpTestSucceeded) {
            Write-Host "✓ Rails (3000): 连接成功" -ForegroundColor Green
        } else {
            Write-Host "✗ Rails (3000): 连接失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Rails (3000): 测试异常" -ForegroundColor Red
    }
    
    # 测试端口5432
    try {
        $pgTest = Test-NetConnection -ComputerName localhost -Port 5432 -WarningAction SilentlyContinue
        if ($pgTest.TcpTestSucceeded) {
            Write-Host "✓ PostgreSQL (5432): 连接成功" -ForegroundColor Green
        } else {
            Write-Host "✗ PostgreSQL (5432): 连接失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ PostgreSQL (5432): 测试异常" -ForegroundColor Red
    }
    
    # 测试端口6379
    try {
        $redisTest = Test-NetConnection -ComputerName localhost -Port 6379 -WarningAction SilentlyContinue
        if ($redisTest.TcpTestSucceeded) {
            Write-Host "✓ Redis (6379): 连接成功" -ForegroundColor Green
        } else {
            Write-Host "✗ Redis (6379): 连接失败" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Redis (6379): 测试异常" -ForegroundColor Red
    }
    
    # HTTP健康检查
    Write-Host "`n3. HTTP健康检查:" -ForegroundColor Yellow
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -ErrorAction Stop
        Write-Host "✓ HTTP响应: $($response.StatusCode) OK" -ForegroundColor Green
        
            # 检查响应内容
        if ($response.Content -like "*Chatwoot*" -or $response.Content -like "*login*") {
            Write-Host "✓ 页面内容: 正常" -ForegroundColor Green
        } else {
            Write-Host "⚠ 页面内容: 可能异常" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "✗ HTTP响应: 失败 - $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # 检查Rails进程
    Write-Host "`n4. Rails进程检查:" -ForegroundColor Yellow
    try {
        $railsProcess = docker exec cschat-rails-1 ps aux 2>$null
        if ($railsProcess -like "*puma*" -or $railsProcess -like "*rails*") {
            Write-Host "✓ Rails进程: 正在运行" -ForegroundColor Green
        } else {
            Write-Host "✗ Rails进程: 未找到" -ForegroundColor Red
        }
    } catch {
        Write-Host "✗ Rails进程: 检查失败" -ForegroundColor Red
    }
    
    # 资源使用情况
    Write-Host "`n5. 资源使用:" -ForegroundColor Yellow
    try {
        $stats = docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
        Write-Host $stats
    } catch {
        Write-Host "✗ 无法获取资源统计" -ForegroundColor Red
    }
    
    Write-Host "`n" + "="*60
}

function Restart-ChatwootServices {
    Write-Host "重启 Chatwoot 服务..." -ForegroundColor Yellow
    
    # 停止服务
    docker-compose -f docker-compose.working.yaml down
    
    # 等待一下
    Start-Sleep -Seconds 5
    
    # 启动服务
    docker-compose -f docker-compose.working.yaml up -d
    
    Write-Host "服务重启完成，等待启动..." -ForegroundColor Green
    Start-Sleep -Seconds 30
    
    # 运行健康检查
    Test-ChatwootHealth
}

# 主逻辑
if ($Continuous) {
    Write-Host "开始连续监控 Chatwoot 服务 (间隔: $Interval 秒)" -ForegroundColor Cyan
    Write-Host "按 Ctrl+C 停止监控" -ForegroundColor Gray
    
    while ($true) {
        Test-ChatwootHealth
        Start-Sleep -Seconds $Interval
    }
} else {
    Test-ChatwootHealth
}

Write-Host "`n常用命令:" -ForegroundColor Yellow
Write-Host "  连续监控: .\monitor-chatwoot.ps1 -Continuous" -ForegroundColor Gray
Write-Host "  重启服务: docker-compose -f docker-compose.working.yaml restart rails" -ForegroundColor Gray
Write-Host "  查看日志: docker logs cschat-rails-1 --follow" -ForegroundColor Gray
Write-Host "  重置密码: docker exec cschat-rails-1 bundle exec rails runner /app/simple_password_reset.rb" -ForegroundColor Gray
