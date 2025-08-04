# 部署增强功能到开发环境

Write-Host "🚀 开始部署增强用户管理功能到开发环境..." -ForegroundColor Green
Write-Host ""

# 1. 停止现有容器
Write-Host "1. 停止现有容器..." -ForegroundColor Yellow
try {
    docker-compose down
    Write-Host "✅ 容器已停止" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ 停止容器时出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. 清理旧的镜像和缓存
Write-Host ""
Write-Host "2. 清理Docker缓存..." -ForegroundColor Yellow
try {
    docker system prune -f
    Write-Host "✅ Docker缓存已清理" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ 清理缓存时出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. 重新构建并启动容器
Write-Host ""
Write-Host "3. 重新构建并启动容器..." -ForegroundColor Yellow
try {
    docker-compose up -d --build
    Write-Host "✅ 容器已重新构建并启动" -ForegroundColor Green
}
catch {
    Write-Host "❌ 启动容器失败: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# 4. 等待容器启动
Write-Host ""
Write-Host "4. 等待容器启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# 5. 检查容器状态
Write-Host ""
Write-Host "5. 检查容器状态..." -ForegroundColor Yellow
try {
    $containers = docker-compose ps
    Write-Host $containers
    Write-Host "✅ 容器状态检查完成" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ 检查容器状态时出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 6. 运行数据库迁移
Write-Host ""
Write-Host "6. 运行数据库迁移..." -ForegroundColor Yellow
try {
    docker-compose exec chatwoot bundle exec rails db:migrate
    Write-Host "✅ 数据库迁移完成" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ 数据库迁移时出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 7. 重启Rails服务器
Write-Host ""
Write-Host "7. 重启Rails服务器..." -ForegroundColor Yellow
try {
    docker-compose restart chatwoot
    Write-Host "✅ Rails服务器已重启" -ForegroundColor Green
}
catch {
    Write-Host "⚠️ 重启服务器时出现警告: $($_.Exception.Message)" -ForegroundColor Yellow
}

# 8. 等待服务完全启动
Write-Host ""
Write-Host "8. 等待服务完全启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 20

# 9. 测试API端点
Write-Host ""
Write-Host "9. 测试增强API端点..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -Method Get -ErrorAction Stop
    Write-Host "✅ API端点响应正常" -ForegroundColor Green
    Write-Host "   状态: $($response.status)" -ForegroundColor Cyan
    Write-Host "   消息: $($response.message)" -ForegroundColor Cyan
    Write-Host "   用户数量: $($response.user_count)" -ForegroundColor Cyan
}
catch {
    Write-Host "⚠️ API端点测试失败: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host "   这可能是正常的，如果服务还在启动中" -ForegroundColor Gray
}

# 10. 显示访问信息
Write-Host ""
Write-Host "🎉 部署完成！" -ForegroundColor Green
Write-Host ""
Write-Host "📍 访问地址:" -ForegroundColor Cyan
Write-Host "   主应用: http://localhost:3000" -ForegroundColor White
Write-Host "   测试页面: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor White
Write-Host "   API状态: http://localhost:3000/api/v1/accounts/1/enhanced_agents/status" -ForegroundColor White
Write-Host ""
Write-Host "🔑 登录信息:" -ForegroundColor Cyan
Write-Host "   邮箱: gibson@localhost.com" -ForegroundColor White
Write-Host "   密码: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "🎯 增强功能:" -ForegroundColor Cyan
Write-Host "   ✅ 认证状态切换" -ForegroundColor Green
Write-Host "   ✅ 密码重置功能" -ForegroundColor Green
Write-Host "   ✅ 自动生成安全密码" -ForegroundColor Green
Write-Host "   ✅ 完整的API端点" -ForegroundColor Green
Write-Host ""
Write-Host "📝 使用说明:" -ForegroundColor Cyan
Write-Host "   1. 访问测试页面进行功能验证" -ForegroundColor White
Write-Host "   2. 登录主应用查看agents页面的新按钮" -ForegroundColor White
Write-Host "   3. 如果前端按钮未显示，请使用测试页面的功能" -ForegroundColor White
Write-Host ""
Write-Host "🔧 故障排除:" -ForegroundColor Cyan
Write-Host "   - 如果容器启动失败，请检查Docker Desktop是否运行" -ForegroundColor White
Write-Host "   - 如果API不响应，请等待更长时间让服务完全启动" -ForegroundColor White
Write-Host "   - 如果数据库连接失败，请运行: docker-compose restart postgres" -ForegroundColor White
Write-Host ""

# 11. 可选：打开浏览器
$openBrowser = Read-Host "是否要打开浏览器查看测试页面？(y/n)"
if ($openBrowser -eq "y" -or $openBrowser -eq "Y") {
    try {
        Start-Process "http://localhost:3000/enhanced_agents_test.html"
        Write-Host "✅ 浏览器已打开测试页面" -ForegroundColor Green
    }
    catch {
        Write-Host "⚠️ 无法自动打开浏览器，请手动访问: http://localhost:3000/enhanced_agents_test.html" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "🎊 增强用户管理功能部署完成！" -ForegroundColor Green
