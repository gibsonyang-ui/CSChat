# Chatwoot 管理员账号创建脚本
# 使用方法: docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner create_admin.rb

puts "=== 创建 Chatwoot 管理员账号 ==="

# 检查用户是否已存在
existing_user = User.find_by(email: 'gibson@localhost.com')
if existing_user
  puts "用户 gibson@localhost.com 已存在，跳过创建"
  user = existing_user
else
  # 创建管理员用户
  user = User.create!(
    name: 'Gibson',
    email: 'gibson@localhost.com',
    password: 'Gibson888555',
    password_confirmation: 'Gibson888555',
    confirmed_at: Time.current
  )
  puts "✓ 管理员用户创建成功: #{user.email}"
end

# 检查账号是否已存在
existing_account = Account.find_by(name: 'Gibson Admin Account')
if existing_account
  puts "账号 'Gibson Admin Account' 已存在，跳过创建"
  account = existing_account
else
  # 创建账号
  account = Account.create!(name: 'Gibson Admin Account')
  puts "✓ 账号创建成功: #{account.name}"
end

# 检查用户是否已关联到账号
existing_account_user = AccountUser.find_by(account: account, user: user)
if existing_account_user
  puts "用户已关联到账号，更新角色为管理员"
  existing_account_user.update!(role: 'administrator')
else
  # 创建账号用户关联
  AccountUser.create!(
    account: account,
    user: user,
    role: 'administrator'
  )
  puts "✓ 用户关联到账号成功，角色: 管理员"
end

# 创建默认收件箱
inbox = account.inboxes.find_by(name: 'Default Website Inbox')
unless inbox
  channel = Channel::WebWidget.create!(
    account: account,
    website_url: 'http://localhost:3000'
  )
  
  inbox = account.inboxes.create!(
    name: 'Default Website Inbox',
    channel: channel
  )
  puts "✓ 默认网站收件箱创建成功"
end

# 将管理员添加到收件箱
unless inbox.inbox_members.find_by(user: user)
  inbox.inbox_members.create!(user: user)
  puts "✓ 管理员已添加到默认收件箱"
end

puts ""
puts "=== 部署完成 ==="
puts "管理员登录信息:"
puts "  邮箱: gibson@localhost.com"
puts "  密码: Gibson888555"
puts "  访问地址: http://localhost:3000"
puts ""
puts "账号信息:"
puts "  账号名称: #{account.name}"
puts "  账号ID: #{account.id}"
puts "  用户角色: 管理员"
puts ""
