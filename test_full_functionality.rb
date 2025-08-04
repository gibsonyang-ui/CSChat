# Chatwoot 完整功能测试脚本

puts "=== Chatwoot 完整功能测试 ==="
puts ""

# 1. 测试用户管理功能
puts "1. 用户管理功能测试:"

begin
  # 获取当前管理员用户
  admin_user = User.find_by(email: 'gibson@localhost.com')
  admin_account = admin_user.accounts.first
  
  puts "✓ 管理员用户: #{admin_user.name} (#{admin_user.email})"
  puts "✓ 管理员账号: #{admin_account.name}"
  
  # 测试创建新用户
  test_user = User.find_or_create_by(email: 'test@example.com') do |user|
    user.name = 'Test User'
    user.password = 'TestPassword123!'
    user.password_confirmation = 'TestPassword123!'
    user.confirmed_at = Time.current
  end
  
  if test_user.persisted?
    puts "✓ 测试用户创建成功: #{test_user.email}"
    
    # 将测试用户添加到账号
    account_user = AccountUser.find_or_create_by(
      user: test_user,
      account: admin_account
    ) do |au|
      au.role = 'agent'
    end
    
    puts "✓ 测试用户已添加到账号，角色: #{account_user.role}"
  else
    puts "✗ 测试用户创建失败: #{test_user.errors.full_messages.join(', ')}"
  end
  
rescue => e
  puts "✗ 用户管理测试失败: #{e.message}"
end

puts ""

# 2. 测试收件箱功能
puts "2. 收件箱功能测试:"

begin
  # 创建网站收件箱
  if admin_account.inboxes.empty?
    channel = Channel::WebWidget.create!(
      account: admin_account,
      website_url: 'http://localhost:3000',
      widget_color: '#1f93ff',
      welcome_title: 'Hi there!',
      welcome_tagline: 'We are here to help you.',
      website_token: SecureRandom.hex
    )
    
    inbox = admin_account.inboxes.create!(
      name: 'Website Chat',
      channel: channel
    )
    
    # 将管理员添加到收件箱
    inbox.inbox_members.create!(user: admin_user)
    
    puts "✓ 网站收件箱创建成功: #{inbox.name}"
  else
    puts "✓ 收件箱已存在: #{admin_account.inboxes.first.name}"
  end
  
rescue => e
  puts "✗ 收件箱创建失败: #{e.message}"
end

puts ""

# 3. 测试联系人功能
puts "3. 联系人功能测试:"

begin
  # 创建测试联系人
  contact = admin_account.contacts.find_or_create_by(email: 'customer@example.com') do |c|
    c.name = 'Test Customer'
    c.phone_number = '+1234567890'
  end
  
  puts "✓ 测试联系人: #{contact.name} (#{contact.email})"
  
rescue => e
  puts "✗ 联系人创建失败: #{e.message}"
end

puts ""

# 4. 测试团队功能
puts "4. 团队功能测试:"

begin
  # 创建测试团队
  team = admin_account.teams.find_or_create_by(name: 'Support Team') do |t|
    t.description = 'Customer Support Team'
  end
  
  puts "✓ 测试团队: #{team.name}"
  
  # 将用户添加到团队
  if admin_user && team
    team_member = team.team_members.find_or_create_by(user: admin_user)
    puts "✓ 管理员已添加到团队"
  end
  
rescue => e
  puts "✗ 团队功能测试失败: #{e.message}"
end

puts ""

# 5. 测试自定义属性功能
puts "5. 自定义属性功能测试:"

begin
  # 创建自定义属性定义
  custom_attr = admin_account.custom_attribute_definitions.find_or_create_by(
    attribute_display_name: 'Customer Type',
    attribute_key: 'customer_type'
  ) do |attr|
    attr.attribute_display_type = 'list'
    attr.attribute_values = ['Premium', 'Standard', 'Basic']
    attr.attribute_model = 'contact_attribute'
  end
  
  puts "✓ 自定义属性: #{custom_attr.attribute_display_name}"
  
rescue => e
  puts "✗ 自定义属性测试失败: #{e.message}"
end

puts ""

# 6. 测试标签功能
puts "6. 标签功能测试:"

begin
  # 创建标签
  label = admin_account.labels.find_or_create_by(title: 'VIP Customer') do |l|
    l.description = 'Very Important Customer'
    l.color = '#FF6B6B'
  end
  
  puts "✓ 标签: #{label.title}"
  
rescue => e
  puts "✗ 标签功能测试失败: #{e.message}"
end

puts ""

# 7. 测试自动化规则功能
puts "7. 自动化规则功能测试:"

begin
  # 创建简单的自动化规则
  automation_rule = admin_account.automation_rules.find_or_create_by(name: 'Welcome Message') do |rule|
    rule.description = 'Send welcome message to new conversations'
    rule.event_name = 'conversation_created'
    rule.conditions = [
      {
        attribute_key: 'status',
        filter_operator: 'equal_to',
        values: ['open']
      }
    ]
    rule.actions = [
      {
        action_name: 'send_message',
        action_params: ['Welcome! How can we help you today?']
      }
    ]
  end
  
  puts "✓ 自动化规则: #{automation_rule.name}"
  
rescue => e
  puts "✗ 自动化规则测试失败: #{e.message}"
end

puts ""

# 8. 检查权限和角色
puts "8. 权限和角色检查:"

begin
  # 检查管理员权限
  admin_account_user = AccountUser.find_by(user: admin_user, account: admin_account)
  puts "✓ 管理员角色: #{admin_account_user.role}"
  puts "✓ 管理员权限: #{admin_account_user.administrator? ? '完整权限' : '受限权限'}"
  
  # 列出所有可用角色
  roles = AccountUser.roles.keys
  puts "✓ 可用角色: #{roles.join(', ')}"
  
rescue => e
  puts "✗ 权限检查失败: #{e.message}"
end

puts ""

# 9. 功能完整性总结
puts "9. 功能完整性总结:"

features = {
  '用户管理' => User.count > 1,
  '账号管理' => Account.count >= 1,
  '收件箱管理' => admin_account.inboxes.count > 0,
  '联系人管理' => admin_account.contacts.count > 0,
  '团队管理' => admin_account.teams.count > 0,
  '标签管理' => admin_account.labels.count > 0,
  '自定义属性' => admin_account.custom_attribute_definitions.count > 0,
  '自动化规则' => admin_account.automation_rules.count > 0
}

features.each do |feature, available|
  status = available ? '✓' : '✗'
  puts "#{status} #{feature}: #{available ? '可用' : '不可用'}"
end

puts ""
puts "=== 功能测试完成 ==="

# 10. 提供管理员完整权限
puts ""
puts "10. 确保管理员完整权限:"

begin
  admin_account_user = AccountUser.find_by(user: admin_user, account: admin_account)
  if admin_account_user
    admin_account_user.update!(role: 'administrator')
    puts "✓ 管理员权限已确认"
  end
  
  # 确保账号有完整功能
  admin_account.update!(
    feature_flags: 2147483647,  # 启用所有功能标志
    limits: {}
  )
  puts "✓ 账号功能限制已移除"
  
rescue => e
  puts "✗ 权限设置失败: #{e.message}"
end

puts ""
puts "现在您应该可以访问所有功能，包括:"
puts "- 用户管理和编辑"
puts "- 账号设置"
puts "- 收件箱配置"
puts "- 团队管理"
puts "- 联系人管理"
puts "- 标签和自定义属性"
puts "- 自动化规则"
puts "- 报告和分析"
