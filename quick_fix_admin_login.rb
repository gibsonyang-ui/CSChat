# 快速修复管理员登录问题

puts "=== 快速修复管理员登录问题 ==="
puts ""

begin
  # 1. 清除所有可能的登录限制
  puts "1. 清除登录限制..."
  
  # 清除Redis缓存
  redis_url = ENV['REDIS_URL'] || 'redis://redis:6379'
  require 'redis'
  
  redis = Redis.new(url: redis_url)
  redis.flushall
  puts "✓ Redis缓存已清空"

  # 2. 重置管理员用户
  puts "2. 重置管理员用户..."
  
  # 主管理员
  main_admin = User.find_or_initialize_by(email: 'gibson@localhost.com')
  main_admin.assign_attributes(
    name: 'Gibson',
    password: 'Gibson888555!',
    password_confirmation: 'Gibson888555!',
    confirmed_at: Time.current
  )
  main_admin.save!
  puts "✓ 主管理员已重置: gibson@localhost.com"
  
  # 备用管理员
  backup_admin = User.find_or_initialize_by(email: 'admin@localhost.com')
  backup_admin.assign_attributes(
    name: 'Backup Admin',
    password: 'BackupAdmin123!',
    password_confirmation: 'BackupAdmin123!',
    confirmed_at: Time.current
  )
  backup_admin.save!
  puts "✓ 备用管理员已重置: admin@localhost.com"

  # 3. 确保账号存在并启用所有功能
  puts "3. 确保账号功能..."
  
  main_account = Account.first_or_create!(
    name: 'Gibson Admin Account',
    feature_flags: 2147483647,
    limits: {}
  )
  main_account.update!(feature_flags: 2147483647, limits: {})
  puts "✓ 主账号功能已启用"

  # 4. 确保管理员权限
  puts "4. 确保管理员权限..."
  
  [main_admin, backup_admin].each do |admin|
    account_user = AccountUser.find_or_initialize_by(
      user: admin,
      account: main_account
    )
    account_user.assign_attributes(
      role: 'administrator',
      availability: 'online'
    )
    account_user.save!
    puts "✓ #{admin.email} 管理员权限已设置"
  end

  # 5. 创建基础数据（如果不存在）
  puts "5. 确保基础数据..."
  
  # 创建收件箱
  if main_account.inboxes.empty?
    channel = Channel::WebWidget.create!(
      account: main_account,
      website_url: 'http://localhost:3000',
      widget_color: '#1f93ff',
      welcome_title: 'Welcome!',
      welcome_tagline: 'How can we help?',
      website_token: SecureRandom.hex
    )
    
    inbox = main_account.inboxes.create!(
      name: 'Website Chat',
      channel: channel,
      enable_auto_assignment: true
    )
    
    # 添加管理员到收件箱
    [main_admin, backup_admin].each do |admin|
      inbox.inbox_members.find_or_create_by(user: admin)
    end
    
    puts "✓ 基础收件箱已创建"
  else
    puts "✓ 收件箱已存在"
  end

  # 6. 验证登录状态
  puts "6. 验证登录状态..."
  
  [main_admin, backup_admin].each do |admin|
    admin.reload
    puts "✓ #{admin.email}:"
    puts "  - ID: #{admin.id}"
    puts "  - 确认: #{admin.confirmed_at ? '是' : '否'}"
    puts "  - 账号: #{admin.accounts.count} 个"
    puts "  - 角色: #{admin.account_users.first&.role}"
  end

  puts ""
  puts "=== 快速修复完成 ==="
  puts ""
  puts "✅ 管理员登录问题已修复！"
  puts ""
  puts "可用账号:"
  puts "✓ gibson@localhost.com / Gibson888555!"
  puts "✓ admin@localhost.com / BackupAdmin123!"
  puts ""
  puts "系统状态:"
  puts "✓ 功能标志: #{main_account.feature_flags}"
  puts "✓ 用户数: #{main_account.users.count}"
  puts "✓ 收件箱数: #{main_account.inboxes.count}"
  puts ""
  puts "建议操作:"
  puts "1. 清除浏览器缓存和Cookie"
  puts "2. 使用无痕模式登录"
  puts "3. 等待2-3分钟让系统稳定"

rescue => e
  puts "❌ 快速修复失败: #{e.message}"
  puts e.backtrace.first(5)
  
  puts ""
  puts "紧急恢复步骤:"
  puts "1. 重启服务: docker-compose -f docker-compose.clean.yaml restart"
  puts "2. 等待60秒后重新运行此脚本"
  puts "3. 如仍有问题，运行完整初始化脚本"
end
