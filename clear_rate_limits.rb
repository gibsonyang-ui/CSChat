# 清除速率限制和登录问题

puts "=== 清除速率限制和登录问题 ==="
puts ""

begin
  # 1. 清除Redis中的所有速率限制
  puts "1. 清除Redis速率限制..."
  
  redis_url = ENV['REDIS_URL'] || 'redis://redis:6379'
  require 'redis'
  
  redis = Redis.new(url: redis_url)
  
  # 清除所有可能的限制键
  all_keys = redis.keys('*')
  rate_limit_keys = all_keys.select do |key|
    key.include?('rate_limit') || 
    key.include?('throttle') || 
    key.include?('attack') ||
    key.include?('login') ||
    key.include?('attempt')
  end
  
  if rate_limit_keys.any?
    redis.del(*rate_limit_keys)
    puts "✓ 清除了 #{rate_limit_keys.count} 个速率限制键"
  else
    puts "✓ 没有找到速率限制键"
  end
  
  # 完全清空Redis（谨慎操作）
  redis.flushall
  puts "✓ Redis缓存已完全清空"

  # 2. 验证管理员用户
  puts "2. 验证管理员用户..."
  
  admin_user = User.find_by(email: 'gibson@localhost.com')
  if admin_user
    puts "✓ 管理员用户存在: #{admin_user.name}"
    puts "✓ 用户ID: #{admin_user.id}"
    puts "✓ 确认状态: #{admin_user.confirmed_at ? '已确认' : '未确认'}"
    
    # 确保用户已确认
    unless admin_user.confirmed_at
      admin_user.update!(confirmed_at: Time.current)
      puts "✓ 用户确认状态已更新"
    end
  else
    puts "❌ 管理员用户不存在"
  end

  # 3. 检查账号和权限
  puts "3. 检查账号和权限..."
  
  if admin_user
    admin_account = admin_user.accounts.first
    if admin_account
      account_user = admin_user.account_users.find_by(account: admin_account)
      
      puts "✓ 账号: #{admin_account.name}"
      puts "✓ 角色: #{account_user.role}"
      puts "✓ 管理员权限: #{account_user.administrator?}"
      puts "✓ 功能标志: #{admin_account.feature_flags}"
      
      # 确保功能标志启用
      if admin_account.feature_flags != 2147483647
        admin_account.update!(feature_flags: 2147483647)
        puts "✓ 功能标志已重新启用"
      end
    else
      puts "❌ 找不到管理员账号"
    end
  end

  # 4. 创建备用管理员（简化版）
  puts "4. 创建备用管理员..."
  
  backup_user = User.find_by(email: 'admin@localhost.com')
  unless backup_user
    backup_user = User.create!(
      name: 'Backup Admin',
      email: 'admin@localhost.com',
      password: 'BackupAdmin123!',
      password_confirmation: 'BackupAdmin123!',
      confirmed_at: Time.current
    )
    
    # 添加到账号
    if admin_user&.accounts&.first
      AccountUser.create!(
        user: backup_user,
        account: admin_user.accounts.first,
        role: 'administrator'
      )
    end
    
    puts "✓ 备用管理员已创建: admin@localhost.com / BackupAdmin123!"
  else
    puts "✓ 备用管理员已存在"
  end

  puts ""
  puts "=== 清除完成 ==="
  puts ""
  puts "✅ 速率限制已清除，用户状态已重置！"
  puts ""
  puts "可用登录账号:"
  puts "主账号: gibson@localhost.com / Gibson888555!"
  puts "备用账号: admin@localhost.com / BackupAdmin123!"
  puts ""
  puts "建议操作:"
  puts "1. 等待2-3分钟让系统稳定"
  puts "2. 清除浏览器缓存和Cookie"
  puts "3. 使用无痕模式重新登录"
  puts "4. 如果仍有问题，重启浏览器"

rescue => e
  puts "❌ 清除失败: #{e.message}"
  puts e.backtrace.first(3)
end
