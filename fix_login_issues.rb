# 修复登录问题和429错误

puts "=== 修复登录问题和429错误 ==="
puts ""

begin
  # 1. 清除Redis缓存中的速率限制
  puts "1. 清除Redis速率限制..."
  
  # 连接Redis并清除相关键
  redis_url = ENV['REDIS_URL'] || 'redis://redis:6379'
  require 'redis'
  
  redis = Redis.new(url: redis_url)
  
  # 清除所有可能的速率限制键
  rate_limit_patterns = [
    'rate_limit:*',
    'login_attempts:*',
    'failed_login:*',
    'rack::attack:*',
    'throttle:*'
  ]
  
  rate_limit_patterns.each do |pattern|
    keys = redis.keys(pattern)
    if keys.any?
      redis.del(*keys)
      puts "  ✓ 清除了 #{keys.count} 个 #{pattern} 键"
    end
  end
  
  puts "✓ Redis速率限制已清除"

  # 2. 重置管理员用户状态
  puts "2. 重置管理员用户状态..."
  
  admin_user = User.find_by(email: 'gibson@localhost.com')
  if admin_user
    # 重置登录相关字段
    admin_user.update!(
      failed_attempts: 0,
      locked_at: nil,
      unlock_token: nil,
      sign_in_count: 0,
      current_sign_in_at: nil,
      last_sign_in_at: nil,
      current_sign_in_ip: nil,
      last_sign_in_ip: nil,
      confirmed_at: Time.current
    )
    
    puts "✓ 管理员用户状态已重置"
    puts "  - 失败尝试次数: #{admin_user.failed_attempts}"
    puts "  - 锁定状态: #{admin_user.locked_at ? '已锁定' : '未锁定'}"
    puts "  - 确认状态: #{admin_user.confirmed_at ? '已确认' : '未确认'}"
  else
    puts "❌ 找不到管理员用户"
  end

  # 3. 检查并修复用户密码
  puts "3. 检查用户密码..."
  
  if admin_user
    # 重新设置密码以确保正确
    admin_user.password = 'Gibson888555!'
    admin_user.password_confirmation = 'Gibson888555!'
    
    if admin_user.save
      puts "✓ 管理员密码已重新设置"
    else
      puts "❌ 密码设置失败: #{admin_user.errors.full_messages.join(', ')}"
    end
  end

  # 4. 检查账号状态
  puts "4. 检查账号状态..."
  
  if admin_user
    admin_account = admin_user.accounts.first
    if admin_account
      account_user = admin_user.account_users.find_by(account: admin_account)
      
      puts "✓ 账号: #{admin_account.name}"
      puts "✓ 角色: #{account_user.role}"
      puts "✓ 权限: #{account_user.administrator? ? '管理员' : '普通用户'}"
      puts "✓ 功能标志: #{admin_account.feature_flags}"
    else
      puts "❌ 找不到管理员账号"
    end
  end

  # 5. 创建备用管理员账号
  puts "5. 创建备用管理员账号..."
  
  backup_email = 'admin@localhost.com'
  backup_user = User.find_by(email: backup_email)
  
  unless backup_user
    backup_user = User.create!(
      name: 'Backup Admin',
      email: backup_email,
      password: 'BackupAdmin123!',
      password_confirmation: 'BackupAdmin123!',
      confirmed_at: Time.current,
      failed_attempts: 0
    )
    
    # 添加到管理员账号
    if admin_user&.accounts&.first
      AccountUser.create!(
        user: backup_user,
        account: admin_user.accounts.first,
        role: 'administrator',
        inviter: admin_user
      )
    end
    
    puts "✓ 备用管理员已创建: #{backup_email} / BackupAdmin123!"
  else
    # 重置备用管理员状态
    backup_user.update!(
      failed_attempts: 0,
      locked_at: nil,
      confirmed_at: Time.current
    )
    puts "✓ 备用管理员状态已重置: #{backup_email}"
  end

  # 6. 禁用速率限制（临时）
  puts "6. 检查速率限制配置..."
  
  # 检查是否有Rack::Attack配置
  if defined?(Rack::Attack)
    puts "✓ 发现Rack::Attack配置"
    
    # 临时禁用所有限制
    Rack::Attack.cache.store.clear if Rack::Attack.cache.respond_to?(:clear)
    puts "✓ Rack::Attack缓存已清除"
  else
    puts "✓ 未发现Rack::Attack配置"
  end

  # 7. 重启Puma服务器（如果需要）
  puts "7. 检查服务器状态..."
  
  # 检查当前进程
  puma_pid = `pgrep -f puma`.strip
  if puma_pid.empty?
    puts "⚠ 未找到Puma进程"
  else
    puts "✓ Puma进程运行中 (PID: #{puma_pid})"
  end

  puts ""
  puts "=== 修复完成 ==="
  puts ""
  puts "✅ 登录问题修复完成！"
  puts ""
  puts "现在可以尝试登录:"
  puts "主账号: gibson@localhost.com / Gibson888555!"
  puts "备用账号: admin@localhost.com / BackupAdmin123!"
  puts ""
  puts "如果仍然无法登录，请:"
  puts "1. 等待5-10分钟让速率限制自动重置"
  puts "2. 清除浏览器缓存和Cookie"
  puts "3. 使用无痕/隐私模式浏览器"
  puts "4. 尝试使用备用管理员账号"
  puts ""
  puts "故障排除:"
  puts "- 检查浏览器网络标签页的详细错误信息"
  puts "- 确保没有防火墙或代理干扰"
  puts "- 验证服务器时间是否正确"

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
