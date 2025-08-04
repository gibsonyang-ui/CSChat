# 启用所有Chatwoot功能和管理界面

puts "=== 启用所有Chatwoot功能 ==="
puts ""

begin
  # 获取管理员用户和账号
  admin_user = User.find_by(email: 'gibson@localhost.com')
  unless admin_user
    puts "❌ 找不到管理员用户"
    exit 1
  end

  admin_account = admin_user.accounts.first
  unless admin_account
    puts "❌ 找不到管理员账号"
    exit 1
  end

  puts "管理员: #{admin_user.name}"
  puts "账号: #{admin_account.name}"
  puts "当前功能标志: #{admin_account.feature_flags}"
  puts ""

  # 1. 启用所有功能标志
  puts "1. 启用所有功能标志..."
  
  # 设置最大功能标志值（启用所有功能）
  admin_account.update!(feature_flags: 2147483647)
  puts "✓ 功能标志已设置为: #{admin_account.feature_flags}"

  # 2. 移除所有限制
  puts "2. 移除账号限制..."
  admin_account.update!(limits: {})
  puts "✓ 账号限制已清除"

  # 3. 确保管理员权限
  puts "3. 确保管理员权限..."
  account_user = admin_user.account_users.find_by(account: admin_account)
  account_user.update!(role: 'administrator')
  puts "✓ 管理员权限已确认"

  # 4. 创建基础收件箱（如果不存在）
  puts "4. 创建基础收件箱..."
  if admin_account.inboxes.empty?
    # 创建网站聊天收件箱
    channel = Channel::WebWidget.create!(
      account: admin_account,
      website_url: 'http://localhost:3000',
      widget_color: '#1f93ff',
      welcome_title: 'Welcome to Support!',
      welcome_tagline: 'We are here to help you.',
      website_token: SecureRandom.hex
    )
    
    inbox = admin_account.inboxes.create!(
      name: 'Website Chat',
      channel: channel,
      enable_auto_assignment: true,
      greeting_enabled: true,
      greeting_message: 'Hello! How can we help you today?'
    )
    
    # 将管理员添加到收件箱
    inbox.inbox_members.create!(user: admin_user)
    
    puts "✓ 网站聊天收件箱已创建: #{inbox.name}"
  else
    puts "✓ 收件箱已存在"
  end

  # 5. 创建基础团队
  puts "5. 创建基础团队..."
  if admin_account.teams.empty?
    team = admin_account.teams.create!(
      name: 'Support Team',
      description: 'Main customer support team'
    )
    
    # 将管理员添加到团队
    team.team_members.create!(user: admin_user)
    
    puts "✓ 支持团队已创建: #{team.name}"
  else
    puts "✓ 团队已存在"
  end

  # 6. 创建基础标签
  puts "6. 创建基础标签..."
  if admin_account.labels.empty?
    default_labels = [
      { title: 'urgent', description: 'Urgent issues', color: '#FF6B6B' },
      { title: 'bug', description: 'Bug reports', color: '#FFA500' },
      { title: 'feature', description: 'Feature requests', color: '#4ECDC4' },
      { title: 'question', description: 'General questions', color: '#45B7D1' }
    ]
    
    default_labels.each do |label_data|
      label = admin_account.labels.create!(
        title: label_data[:title],
        description: label_data[:description],
        color: label_data[:color]
      )
      puts "  ✓ 标签: #{label.title}"
    end
  else
    puts "✓ 标签已存在"
  end

  # 7. 创建自定义属性
  puts "7. 创建自定义属性..."
  if admin_account.custom_attribute_definitions.empty?
    custom_attributes = [
      {
        attribute_display_name: 'Customer Priority',
        attribute_key: 'customer_priority',
        attribute_display_type: 'list',
        attribute_values: ['High', 'Medium', 'Low'],
        attribute_model: 'contact_attribute'
      },
      {
        attribute_display_name: 'Source',
        attribute_key: 'source',
        attribute_display_type: 'list',
        attribute_values: ['Website', 'Email', 'Phone', 'Social Media'],
        attribute_model: 'contact_attribute'
      }
    ]
    
    custom_attributes.each do |attr_data|
      attr = admin_account.custom_attribute_definitions.create!(
        attribute_display_name: attr_data[:attribute_display_name],
        attribute_key: attr_data[:attribute_key],
        attribute_display_type: attr_data[:attribute_display_type],
        attribute_values: attr_data[:attribute_values],
        attribute_model: attr_data[:attribute_model]
      )
      puts "  ✓ 自定义属性: #{attr.attribute_display_name}"
    end
  else
    puts "✓ 自定义属性已存在"
  end

  # 8. 创建快捷回复
  puts "8. 创建快捷回复..."
  if admin_account.canned_responses.empty?
    canned_responses = [
      {
        short_code: 'hello',
        content: 'Hello! How can I help you today?'
      },
      {
        short_code: 'thanks',
        content: 'Thank you for contacting us. Have a great day!'
      },
      {
        short_code: 'followup',
        content: 'I will follow up with you shortly with more information.'
      }
    ]
    
    canned_responses.each do |response_data|
      response = admin_account.canned_responses.create!(
        short_code: response_data[:short_code],
        content: response_data[:content]
      )
      puts "  ✓ 快捷回复: #{response.short_code}"
    end
  else
    puts "✓ 快捷回复已存在"
  end

  # 9. 创建测试代理用户
  puts "9. 创建测试代理用户..."
  test_agent = admin_account.users.find_by(email: 'agent@example.com')
  unless test_agent
    test_agent = User.create!(
      name: 'Test Agent',
      email: 'agent@example.com',
      password: 'TestAgent123!',
      password_confirmation: 'TestAgent123!',
      confirmed_at: Time.current
    )
    
    AccountUser.create!(
      user: test_agent,
      account: admin_account,
      role: 'agent',
      inviter: admin_user
    )
    
    # 将代理添加到收件箱和团队
    if admin_account.inboxes.any?
      admin_account.inboxes.first.inbox_members.create!(user: test_agent)
    end
    
    if admin_account.teams.any?
      admin_account.teams.first.team_members.create!(user: test_agent)
    end
    
    puts "✓ 测试代理已创建: #{test_agent.email}"
  else
    puts "✓ 测试代理已存在"
  end

  # 10. 验证最终状态
  puts ""
  puts "=== 最终状态验证 ==="
  admin_account.reload
  
  puts "✓ 功能标志: #{admin_account.feature_flags}"
  puts "✓ 总用户数: #{admin_account.users.count}"
  puts "✓ 管理员数: #{admin_account.account_users.where(role: 'administrator').count}"
  puts "✓ 代理数: #{admin_account.account_users.where(role: 'agent').count}"
  puts "✓ 收件箱数: #{admin_account.inboxes.count}"
  puts "✓ 团队数: #{admin_account.teams.count}"
  puts "✓ 标签数: #{admin_account.labels.count}"
  puts "✓ 自定义属性数: #{admin_account.custom_attribute_definitions.count}"
  puts "✓ 快捷回复数: #{admin_account.canned_responses.count}"

  puts ""
  puts "=== 功能启用完成 ==="
  puts ""
  puts "🎉 所有功能已启用！现在您应该可以看到："
  puts "✓ 设置菜单中的所有管理选项"
  puts "✓ 代理管理功能"
  puts "✓ 收件箱管理"
  puts "✓ 团队管理"
  puts "✓ 标签管理"
  puts "✓ 自定义属性"
  puts "✓ 快捷回复"
  puts "✓ 报告和分析"
  puts ""
  puts "登录信息:"
  puts "管理员: gibson@localhost.com / Gibson888555!"
  puts "代理: agent@example.com / TestAgent123!"
  puts ""
  puts "请刷新浏览器页面以查看所有功能！"

rescue => e
  puts "❌ 启用功能失败: #{e.message}"
  puts e.backtrace.first(5)
end
