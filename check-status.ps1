# Chatwoot 状态检查脚本

Write-Host "=== Chatwoot 状态检查 ===" -ForegroundColor Green
Write-Host ""

# 检查容器状态
Write-Host "1. 容器状态:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# 检查端口连接
Write-Host "2. 端口连接测试:" -ForegroundColor Yellow

$ports = @(
    @{Name="Rails"; Port=3000},
    @{Name="PostgreSQL"; Port=5432},
    @{Name="Redis"; Port=6379}
)

foreach ($portInfo in $ports) {
    $connection = Test-NetConnection -ComputerName localhost -Port $portInfo.Port -WarningAction SilentlyContinue
    if ($connection.TcpTestSucceeded) {
        Write-Host "✓ $($portInfo.Name) ($($portInfo.Port)): 连接成功" -ForegroundColor Green
    } else {
        Write-Host "✗ $($portInfo.Name) ($($portInfo.Port)): 连接失败" -ForegroundColor Red
    }
}

Write-Host ""

# HTTP健康检查
Write-Host "3. HTTP健康检查:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
    Write-Host "✓ HTTP响应: $($response.StatusCode) OK" -ForegroundColor Green
} catch {
    Write-Host "✗ HTTP响应失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 检查Rails进程
Write-Host "4. Rails进程:" -ForegroundColor Yellow
try {
    $railsProcess = docker exec cschat-rails-1 ps aux
    if ($railsProcess -match "puma|rails") {
        Write-Host "✓ Rails进程正在运行" -ForegroundColor Green
    } else {
        Write-Host "✗ Rails进程未找到" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ 无法检查Rails进程" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== 检查完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "如果服务有问题，可以运行:" -ForegroundColor Yellow
Write-Host "  重启Rails: docker-compose -f docker-compose.working.yaml restart rails" -ForegroundColor Cyan
Write-Host "  查看日志: docker logs cschat-rails-1 --tail=20" -ForegroundColor Cyan
Write-Host "  重置密码: docker exec cschat-rails-1 bundle exec rails runner /app/simple_password_reset.rb" -ForegroundColor Cyan
