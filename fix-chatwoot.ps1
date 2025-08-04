# Chatwoot 修复脚本 - 解决ERR_EMPTY_RESPONSE问题

Write-Host "=== Chatwoot 修复脚本 ===" -ForegroundColor Green
Write-Host "正在解决 ERR_EMPTY_RESPONSE 错误..." -ForegroundColor Yellow

# 停止所有服务
Write-Host "停止现有服务..." -ForegroundColor Yellow
docker-compose -f docker-compose.simple.yaml down -v

# 创建一个最小化的docker-compose配置
Write-Host "创建最小化配置..." -ForegroundColor Yellow

$minimalCompose = @"
services:
  postgres:
    image: postgres:13
    restart: always
    ports:
      - '5432:5432'
    volumes:
      - postgres_data:/var/lib/postgresql/data
    environment:
      - POSTGRES_DB=chatwoot
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=chatwoot_password
      - POSTGRES_HOST_AUTH_METHOD=trust

  redis:
    image: redis:alpine
    restart: always
    ports:
      - '6379:6379'
    volumes:
      - redis_data:/data

  rails:
    image: chatwoot/chatwoot:latest
    restart: always
    depends_on:
      - postgres
      - redis
    ports:
      - '3000:3000'
    environment:
      - NODE_ENV=production
      - RAILS_ENV=production
      - INSTALLATION_ENV=docker
      - SECRET_KEY_BASE=0D5BFDBCF455A014C7FDB1EF4AC48E0EEED7D47BC95E1491B26D37AE26597A04983A96AD9792CCB40C7BBD5E16468F2B7ADE12160D3D489F04E5310B76CE7384
      - FRONTEND_URL=http://localhost:3000
      - POSTGRES_HOST=postgres
      - POSTGRES_USERNAME=postgres
      - POSTGRES_PASSWORD=chatwoot_password
      - POSTGRES_DATABASE=chatwoot
      - REDIS_URL=redis://redis:6379
      - ENABLE_ACCOUNT_SIGNUP=false
      - MAILER_SENDER_EMAIL=Chatwoot <noreply@localhost>
    command: ['sh', '-c', 'bundle exec rails db:create && bundle exec rails db:migrate && bundle exec rails s -p 3000 -b 0.0.0.0']
    volumes:
      - storage_data:/app/storage

volumes:
  postgres_data:
  redis_data:
  storage_data:
"@

$minimalCompose | Out-File -FilePath "docker-compose.minimal.yaml" -Encoding UTF8

# 启动最小化服务
Write-Host "启动最小化服务..." -ForegroundColor Yellow
docker-compose -f docker-compose.minimal.yaml up -d

# 等待服务启动
Write-Host "等待服务启动..." -ForegroundColor Yellow
Start-Sleep -Seconds 60

# 检查状态
Write-Host "检查服务状态..." -ForegroundColor Yellow
docker ps

# 测试连接
Write-Host "测试连接..." -ForegroundColor Yellow
$maxRetries = 10
$retry = 0

while ($retry -lt $maxRetries) {
    $retry++
    Write-Host "尝试 $retry/$maxRetries ..." -ForegroundColor Gray
    
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ Chatwoot 成功启动!" -ForegroundColor Green
            Write-Host "访问地址: http://localhost:3000" -ForegroundColor Cyan
            break
        }
    } catch {
        Write-Host "连接失败，重试中..." -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}

if ($retry -ge $maxRetries) {
    Write-Host "✗ 连接测试失败" -ForegroundColor Red
    Write-Host "查看日志: docker logs cschat-rails-1" -ForegroundColor Yellow
} else {
    # 创建管理员账号
    Write-Host "创建管理员账号..." -ForegroundColor Yellow
    docker exec cschat-rails-1 bundle exec rails runner "
    begin
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
    rescue => e
      puts '管理员账号创建失败: ' + e.message
    end
    "
    
    Write-Host ""
    Write-Host "=== 部署完成 ===" -ForegroundColor Green
    Write-Host "访问地址: http://localhost:3000" -ForegroundColor Cyan
    Write-Host "管理员邮箱: gibson@localhost.com" -ForegroundColor Cyan
    Write-Host "管理员密码: Gibson888555" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "常用命令:" -ForegroundColor Yellow
Write-Host "  查看日志: docker logs cschat-rails-1 --follow" -ForegroundColor Gray
Write-Host "  重启服务: docker-compose -f docker-compose.minimal.yaml restart rails" -ForegroundColor Gray
Write-Host "  停止服务: docker-compose -f docker-compose.minimal.yaml down" -ForegroundColor Gray
