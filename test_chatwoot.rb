# Chatwoot 功能测试脚本
# 使用方法: docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner test_chatwoot.rb

puts "=== Chatwoot 功能测试 ==="

# 测试数据库连接
begin
  ActiveRecord::Base.connection.execute("SELECT 1")
  puts "✓ 数据库连接正常"
rescue => e
  puts "✗ 数据库连接失败: #{e.message}"
  exit 1
end

# 测试 Redis 连接
begin
  Redis.current.ping
  puts "✓ Redis 连接正常"
rescue => e
  puts "✗ Redis 连接失败: #{e.message}"
end

# 检查管理员用户
admin_user = User.find_by(email: 'gibson@localhost.com')
if admin_user
  puts "✓ 管理员用户存在: #{admin_user.name} (#{admin_user.email})"
  
  # 检查用户账号
  account_users = admin_user.account_users
  if account_users.any?
    account_users.each do |au|
      puts "  - 关联账号: #{au.account.name} (角色: #{au.role})"
    end
  else
    puts "✗ 管理员用户未关联任何账号"
  end
else
  puts "✗ 管理员用户不存在"
end

# 检查账号
accounts = Account.all
puts "✓ 系统中共有 #{accounts.count} 个账号"
accounts.each do |account|
  puts "  - 账号: #{account.name} (ID: #{account.id})"
  
  # 检查收件箱
  inboxes = account.inboxes
  puts "    收件箱数量: #{inboxes.count}"
  inboxes.each do |inbox|
    puts "      - #{inbox.name} (类型: #{inbox.channel_type})"
  end
  
  # 检查用户
  users = account.users
  puts "    用户数量: #{users.count}"
  users.each do |user|
    role = account.account_users.find_by(user: user)&.role
    puts "      - #{user.name} (#{user.email}) - 角色: #{role}"
  end
end

# 测试基本模型创建
puts ""
puts "=== 测试基本功能 ==="

# 测试创建联系人
begin
  account = Account.first
  contact = account.contacts.create!(
    name: 'Test Contact',
    email: 'test@example.com'
  )
  puts "✓ 联系人创建测试通过"
  contact.destroy # 清理测试数据
rescue => e
  puts "✗ 联系人创建测试失败: #{e.message}"
end

# 测试创建对话
begin
  account = Account.first
  inbox = account.inboxes.first
  if inbox
    contact = account.contacts.create!(
      name: 'Test Contact for Conversation',
      email: 'testconv@example.com'
    )
    
    conversation = account.conversations.create!(
      inbox: inbox,
      contact: contact,
      status: 'open'
    )
    puts "✓ 对话创建测试通过"
    
    # 清理测试数据
    conversation.destroy
    contact.destroy
  else
    puts "✗ 没有可用的收件箱进行对话测试"
  end
rescue => e
  puts "✗ 对话创建测试失败: #{e.message}"
end

# 检查 Sidekiq 队列
begin
  require 'sidekiq/api'
  stats = Sidekiq::Stats.new
  puts "✓ Sidekiq 统计:"
  puts "  - 处理中的任务: #{stats.processed}"
  puts "  - 失败的任务: #{stats.failed}"
  puts "  - 队列中的任务: #{stats.enqueued}"
rescue => e
  puts "✗ Sidekiq 状态检查失败: #{e.message}"
end

# 检查存储配置
puts "✓ 存储配置: #{Rails.application.config.active_storage.service}"

# 检查邮件配置
puts "✓ 邮件配置:"
puts "  - SMTP 地址: #{ActionMailer::Base.smtp_settings[:address]}"
puts "  - SMTP 端口: #{ActionMailer::Base.smtp_settings[:port]}"
puts "  - 发件人: #{ENV['MAILER_SENDER_EMAIL']}"

puts ""
puts "=== 测试完成 ==="
puts "如果所有测试都通过，Chatwoot 应该可以正常使用了！"
puts "访问 http://localhost:3000 开始使用 Chatwoot"
