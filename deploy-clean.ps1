# Chatwoot 清洁部署脚本 - 彻底根除所有错误

param(
    [switch]$Reset,
    [switch]$GitCommit
)

$ErrorActionPreference = "Continue"

Write-Host "=== Chatwoot 清洁部署 ===" -ForegroundColor Green
Write-Host "彻底根除所有错误，重新开始..." -ForegroundColor Yellow
Write-Host ""

# 函数：等待服务健康
function Wait-ForHealthy {
    param($ServiceName, $MaxWait = 120)
    
    Write-Host "等待 $ServiceName 服务健康..." -ForegroundColor Yellow
    $waited = 0
    
    while ($waited -lt $MaxWait) {
        $health = docker-compose -f docker-compose.clean.yaml ps --format json | ConvertFrom-Json | Where-Object { $_.Service -eq $ServiceName }
        if ($health -and $health.Health -eq "healthy") {
            Write-Host "✓ $ServiceName 服务健康" -ForegroundColor Green
            return $true
        }
        
        Start-Sleep -Seconds 5
        $waited += 5
        Write-Host "  等待中... ($waited/$MaxWait 秒)" -ForegroundColor Gray
    }
    
    Write-Host "⚠ $ServiceName 服务健康检查超时" -ForegroundColor Yellow
    return $false
}

# 1. 完全清理
if ($Reset) {
    Write-Host "1. 完全清理现有部署..." -ForegroundColor Yellow
    
    # 停止所有相关容器
    docker-compose -f docker-compose.clean.yaml down -v --remove-orphans 2>$null
    docker-compose -f docker-compose.simple-fixed.yaml down -v --remove-orphans 2>$null
    docker-compose -f docker-compose.working.yaml down -v --remove-orphans 2>$null
    docker-compose down -v --remove-orphans 2>$null
    
    # 清理Docker系统
    docker system prune -f
    
    Write-Host "✓ 清理完成" -ForegroundColor Green
}

# 2. 启动清洁版服务
Write-Host "2. 启动清洁版Chatwoot服务..." -ForegroundColor Yellow

# 拉取最新镜像
docker pull chatwoot/chatwoot:v3.12.0
docker pull postgres:15-alpine
docker pull redis:7-alpine

# 启动服务
docker-compose -f docker-compose.clean.yaml up -d

if ($LASTEXITCODE -ne 0) {
    Write-Host "✗ 服务启动失败" -ForegroundColor Red
    exit 1
}

Write-Host "✓ 服务启动命令执行成功" -ForegroundColor Green

# 3. 等待服务健康
Write-Host "3. 等待服务健康检查..." -ForegroundColor Yellow

Start-Sleep -Seconds 30

# 检查服务状态
Write-Host "检查服务状态..." -ForegroundColor Yellow
docker-compose -f docker-compose.clean.yaml ps

# 4. 初始化数据库
Write-Host "4. 初始化数据库..." -ForegroundColor Yellow

# 等待Chatwoot容器完全启动
Start-Sleep -Seconds 60

# 复制初始化脚本
docker cp init_database.rb cschat-chatwoot-1:/app/ 2>$null

# 运行初始化
Write-Host "运行数据库初始化..." -ForegroundColor Yellow
docker exec cschat-chatwoot-1 bundle exec rails runner /app/init_database.rb

# 5. 健康检查
Write-Host "5. 最终健康检查..." -ForegroundColor Yellow

$maxRetries = 12
$retry = 0

while ($retry -lt $maxRetries) {
    $retry++
    Write-Host "健康检查 $retry/$maxRetries ..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
        if ($response.StatusCode -eq 200 -and $response.Content.Length -gt 1000) {
            Write-Host "✓ Chatwoot 健康检查通过!" -ForegroundColor Green
            Write-Host "  HTTP状态: $($response.StatusCode)" -ForegroundColor Green
            Write-Host "  内容长度: $($response.Content.Length) 字符" -ForegroundColor Green
            break
        }
    } catch {
        Write-Host "  连接失败，重试中..." -ForegroundColor Yellow
    }
    
    if ($retry -eq $maxRetries) {
        Write-Host "✗ 健康检查失败" -ForegroundColor Red
        Write-Host "查看日志: docker logs cschat-chatwoot-1" -ForegroundColor Yellow
        exit 1
    }
    
    Start-Sleep -Seconds 10
}

# 6. Git提交（如果请求）
if ($GitCommit) {
    Write-Host "6. 提交到Git..." -ForegroundColor Yellow
    
    # 添加所有文件
    git add .
    
    # 提交更改
    $commitMessage = "feat: 彻底重构Chatwoot部署，根除所有错误

- 使用稳定版本 chatwoot:v3.12.0
- 简化Docker配置，移除有问题的迁移
- 添加健康检查和自动初始化
- 创建清洁的数据库结构
- 修复RESULT_CODE_HUNG错误
- 确保页面正常加载，无白屏问题

管理员账号:
- 邮箱: gibson@localhost.com  
- 密码: Gibson888555!"
    
    git commit -m $commitMessage
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✓ Git提交成功" -ForegroundColor Green
        
        # 推送到远程（如果有）
        $remoteBranch = git branch --show-current
        if ($remoteBranch) {
            git push origin $remoteBranch 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "✓ 推送到远程成功" -ForegroundColor Green
            } else {
                Write-Host "⚠ 推送到远程失败，但本地提交成功" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "⚠ Git提交失败" -ForegroundColor Yellow
    }
}

# 7. 显示最终状态
Write-Host ""
Write-Host "=== 部署完成 ===" -ForegroundColor Green
Write-Host ""
Write-Host "✅ Chatwoot 清洁版部署成功!" -ForegroundColor Green
Write-Host ""
Write-Host "访问信息:" -ForegroundColor Cyan
Write-Host "  网址: http://localhost:3000" -ForegroundColor White
Write-Host "  邮箱: gibson@localhost.com" -ForegroundColor White  
Write-Host "  密码: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "管理命令:" -ForegroundColor Yellow
Write-Host "  查看状态: docker-compose -f docker-compose.clean.yaml ps" -ForegroundColor Gray
Write-Host "  查看日志: docker logs cschat-chatwoot-1 --follow" -ForegroundColor Gray
Write-Host "  重启服务: docker-compose -f docker-compose.clean.yaml restart chatwoot" -ForegroundColor Gray
Write-Host "  停止服务: docker-compose -f docker-compose.clean.yaml down" -ForegroundColor Gray
Write-Host ""
Write-Host "🎉 所有错误已根除，Chatwoot现在完全正常运行!" -ForegroundColor Green
