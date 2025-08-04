# Chatwoot 管理员密码重置脚本

puts "=== Chatwoot 管理员密码重置 ==="
puts ""

# 检查当前用户
puts "当前用户列表:"
User.all.each do |user|
  puts "  - #{user.name} (#{user.email})"
  puts "    确认状态: #{user.confirmed_at ? '已确认' : '未确认'}"
  puts "    账号关联: #{user.account_users.count} 个"
end
puts ""

# 查找或创建Gibson用户
email = 'gibson@localhost.com'
password = 'Gibson888555!'

puts "查找用户: #{email}"
user = User.find_by(email: email)

if user
  puts "✓ 找到现有用户: #{user.name}"
  
  # 重置密码
  user.password = password
  user.password_confirmation = password
  user.confirmed_at = Time.current
  
  if user.save
    puts "✓ 密码重置成功"
  else
    puts "✗ 密码重置失败: #{user.errors.full_messages.join(', ')}"
  end
else
  puts "用户不存在，创建新用户..."
  
  user = User.new(
    name: 'Gibson',
    email: email,
    password: password,
    password_confirmation: password,
    confirmed_at: Time.current
  )
  
  if user.save
    puts "✓ 用户创建成功"
  else
    puts "✗ 用户创建失败: #{user.errors.full_messages.join(', ')}"
    exit 1
  end
end

# 查找或创建账号
account_name = 'Gibson Admin Account'
puts ""
puts "查找账号: #{account_name}"

account = Account.find_by(name: account_name)
if account
  puts "✓ 找到现有账号: #{account.name}"
else
  puts "账号不存在，创建新账号..."
  account = Account.create!(name: account_name)
  puts "✓ 账号创建成功: #{account.name}"
end

# 创建或更新用户账号关联
puts ""
puts "设置用户权限..."

account_user = AccountUser.find_by(user: user, account: account)
if account_user
  puts "✓ 找到现有关联，更新角色为管理员"
  account_user.role = 'administrator'
  account_user.save!
else
  puts "创建新的用户账号关联..."
  AccountUser.create!(
    user: user,
    account: account,
    role: 'administrator'
  )
  puts "✓ 用户账号关联创建成功"
end

# 创建默认收件箱（如果不存在）
puts ""
puts "检查默认收件箱..."

inbox = account.inboxes.first
if inbox
  puts "✓ 找到现有收件箱: #{inbox.name}"
else
  puts "创建默认收件箱..."
  begin
    # 创建网站频道
    channel = Channel::WebWidget.create!(
      account: account,
      website_url: 'http://localhost:3000'
    )
    
    # 创建收件箱
    inbox = account.inboxes.create!(
      name: 'Default Website Inbox',
      channel: channel
    )
    
    # 将管理员添加到收件箱
    inbox.inbox_members.create!(user: user)
    
    puts "✓ 默认收件箱创建成功"
  rescue => e
    puts "⚠ 收件箱创建失败: #{e.message}"
  end
end

puts ""
puts "=== 设置完成 ==="
puts "管理员登录信息:"
puts "  邮箱: #{email}"
puts "  密码: #{password}"
puts "  访问地址: http://localhost:3000"
puts ""
puts "账号信息:"
puts "  账号名称: #{account.name}"
puts "  用户角色: 管理员"
puts ""
