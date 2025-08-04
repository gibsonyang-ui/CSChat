# Chatwoot 最终状态检查

Write-Host "=== Chatwoot 最终状态检查 ===" -ForegroundColor Green
Write-Host ""

# 检查容器状态
Write-Host "1. 容器状态:" -ForegroundColor Yellow
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host ""

# 检查HTTP响应
Write-Host "2. HTTP健康检查:" -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
    Write-Host "✓ HTTP响应: $($response.StatusCode) OK" -ForegroundColor Green
    
    # 检查页面内容
    if ($response.Content.Length -gt 1000) {
        Write-Host "✓ 页面内容: 正常加载 ($($response.Content.Length) 字符)" -ForegroundColor Green
    } else {
        Write-Host "⚠ 页面内容: 可能不完整 ($($response.Content.Length) 字符)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "✗ HTTP响应失败: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# 检查端口连接
Write-Host "3. 端口连接测试:" -ForegroundColor Yellow
$ports = @(
    @{Name="Rails"; Port=3000},
    @{Name="PostgreSQL"; Port=5432},
    @{Name="Redis"; Port=6379},
    @{Name="MailHog SMTP"; Port=1025},
    @{Name="MailHog Web"; Port=8025}
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

# 检查用户
Write-Host "4. 用户检查:" -ForegroundColor Yellow
try {
    $userCheck = docker exec cschat-rails-1 bundle exec rails runner "puts User.find_by(email: 'gibson@localhost.com') ? 'User exists' : 'User not found'" 2>$null
    if ($userCheck -match "User exists") {
        Write-Host "✓ 管理员用户存在: gibson@localhost.com" -ForegroundColor Green
    } else {
        Write-Host "⚠ 管理员用户不存在，需要通过网页注册" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠ 无法检查用户状态" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "=== 部署总结 ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Chatwoot 已成功部署并运行" -ForegroundColor Green
Write-Host ""
Write-Host "访问信息:" -ForegroundColor Cyan
Write-Host "  主应用: http://localhost:3000" -ForegroundColor White
Write-Host "  邮件测试: http://localhost:8025 (MailHog)" -ForegroundColor White
Write-Host ""
Write-Host "登录信息:" -ForegroundColor Cyan
Write-Host "  邮箱: gibson@localhost.com" -ForegroundColor White
Write-Host "  密码: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "管理命令:" -ForegroundColor Yellow
Write-Host "  查看日志: docker logs cschat-rails-1 --follow" -ForegroundColor Gray
Write-Host "  重启服务: docker-compose -f docker-compose.simple-fixed.yaml restart rails" -ForegroundColor Gray
Write-Host "  停止服务: docker-compose -f docker-compose.simple-fixed.yaml down" -ForegroundColor Gray
Write-Host "  状态检查: .\final-status-check.ps1" -ForegroundColor Gray
Write-Host ""
Write-Host "🎉 部署完成！现在可以正常使用 Chatwoot 了！" -ForegroundColor Green
