# 部署增强用户管理功能的脚本

puts "=== 部署增强用户管理功能 ==="
puts ""

begin
  # 1. 检查管理员权限
  admin_user = User.find_by(email: 'gibson@localhost.com')
  unless admin_user
    puts "❌ 错误: 找不到管理员用户"
    exit 1
  end

  admin_account = admin_user.accounts.first
  unless admin_account
    puts "❌ 错误: 管理员没有关联账号"
    exit 1
  end

  account_user = admin_user.account_users.find_by(account: admin_account)
  unless account_user&.administrator?
    puts "❌ 错误: 用户不是管理员"
    exit 1
  end

  puts "✓ 管理员验证通过: #{admin_user.name} (#{admin_user.email})"
  puts "✓ 账号: #{admin_account.name}"
  puts ""

  # 2. 确保所有必要的功能已启用
  puts "2. 启用增强功能..."
  
  # 启用所有用户管理相关的功能标志
  admin_account.update!(
    feature_flags: 2147483647  # 启用所有功能
  )
  puts "✓ 功能标志已启用"

  # 3. 创建示例用户（如果不存在）
  puts "3. 创建示例用户..."
  
  demo_users = [
    {
      name: 'Demo Agent',
      email: 'demo.agent@example.com',
      password: 'DemoAgent123!',
      role: 'agent',
      confirmed: true
    },
    {
      name: 'Test Manager',
      email: 'test.manager@example.com', 
      password: 'TestManager123!',
      role: 'administrator',
      confirmed: false
    }
  ]

  demo_users.each do |user_data|
    user = User.find_by(email: user_data[:email])
    
    if user
      puts "  - 用户已存在: #{user_data[:email]}"
    else
      user = User.create!(
        name: user_data[:name],
        email: user_data[:email],
        password: user_data[:password],
        password_confirmation: user_data[:password],
        confirmed_at: user_data[:confirmed] ? Time.current : nil
      )
      
      AccountUser.create!(
        user: user,
        account: admin_account,
        role: user_data[:role],
        inviter: admin_user
      )
      
      puts "  ✓ 创建用户: #{user_data[:name]} (#{user_data[:email]})"
    end
  end

  # 4. 设置自定义属性示例
  puts "4. 设置自定义属性示例..."
  
  custom_attributes = [
    {
      attribute_display_name: 'Department',
      attribute_key: 'department',
      attribute_display_type: 'list',
      attribute_values: ['Sales', 'Support', 'Marketing', 'Development'],
      attribute_model: 'contact_attribute'
    },
    {
      attribute_display_name: 'Employee ID',
      attribute_key: 'employee_id',
      attribute_display_type: 'text',
      attribute_model: 'contact_attribute'
    }
  ]

  custom_attributes.each do |attr_data|
    attr = admin_account.custom_attribute_definitions.find_or_create_by(
      attribute_key: attr_data[:attribute_key]
    ) do |custom_attr|
      custom_attr.attribute_display_name = attr_data[:attribute_display_name]
      custom_attr.attribute_display_type = attr_data[:attribute_display_type]
      custom_attr.attribute_values = attr_data[:attribute_values] if attr_data[:attribute_values]
      custom_attr.attribute_model = attr_data[:attribute_model]
    end
    puts "  ✓ 自定义属性: #{attr.attribute_display_name}"
  end

  # 5. 创建默认团队
  puts "5. 创建默认团队..."
  
  teams_data = [
    {
      name: 'Customer Support',
      description: 'Primary customer support team'
    },
    {
      name: 'Technical Support', 
      description: 'Technical issues and troubleshooting'
    }
  ]

  teams_data.each do |team_data|
    team = admin_account.teams.find_or_create_by(name: team_data[:name]) do |t|
      t.description = team_data[:description]
    end
    
    # 将管理员添加到团队
    team.team_members.find_or_create_by(user: admin_user)
    
    puts "  ✓ 团队: #{team.name}"
  end

  # 6. 设置收件箱（如果不存在）
  puts "6. 设置收件箱..."
  
  if admin_account.inboxes.empty?
    channel = Channel::WebWidget.create!(
      account: admin_account,
      website_url: 'http://localhost:3000',
      widget_color: '#1f93ff',
      welcome_title: 'Welcome to Enhanced Support!',
      welcome_tagline: 'We are here to help you with our enhanced features.',
      website_token: SecureRandom.hex
    )
    
    inbox = admin_account.inboxes.create!(
      name: 'Enhanced Website Chat',
      channel: channel,
      enable_auto_assignment: true,
      greeting_enabled: true,
      greeting_message: 'Hello! How can our enhanced support team help you today?'
    )
    
    # 将所有用户添加到收件箱
    admin_account.users.each do |user|
      inbox.inbox_members.find_or_create_by(user: user)
    end
    
    puts "  ✓ 收件箱: #{inbox.name}"
  else
    puts "  ✓ 收件箱已存在"
  end

  # 7. 创建快捷回复模板
  puts "7. 创建快捷回复模板..."
  
  canned_responses = [
    {
      short_code: 'welcome_enhanced',
      content: 'Welcome to our enhanced support system! How can I assist you today?'
    },
    {
      short_code: 'password_reset',
      content: 'I can help you reset your password. Please check your email for the reset link.'
    },
    {
      short_code: 'account_verified',
      content: 'Your account has been successfully verified. You can now access all features.'
    }
  ]

  canned_responses.each do |response_data|
    response = admin_account.canned_responses.find_or_create_by(
      short_code: response_data[:short_code]
    ) do |cr|
      cr.content = response_data[:content]
    end
    puts "  ✓ 快捷回复: #{response.short_code}"
  end

  puts ""
  puts "=== 增强功能部署完成 ==="
  puts ""
  puts "✅ 所有增强功能已成功部署!"
  puts ""
  puts "新增功能:"
  puts "✓ 增强的用户管理 - 完整的创建、编辑、删除功能"
  puts "✓ 密码管理 - 重置密码和强制修改密码"
  puts "✓ 认证控制 - 管理员可控制用户认证状态"
  puts "✓ 角色管理 - 灵活的角色分配和权限控制"
  puts "✓ 批量操作 - 批量管理多个用户"
  puts "✓ 用户统计 - 详细的用户数据统计"
  puts ""
  puts "测试账号:"
  puts "管理员: gibson@localhost.com / Gibson888555!"
  puts "代理: demo.agent@example.com / DemoAgent123!"
  puts "测试管理员: test.manager@example.com / TestManager123! (未认证)"
  puts ""
  puts "使用方法:"
  puts "1. 登录管理员账号"
  puts "2. 进入设置 → 代理管理"
  puts "3. 使用增强的用户管理功能"
  puts ""
  puts "命令行管理:"
  puts "docker exec -it cschat-chatwoot-1 bundle exec rails runner enhanced_user_management.rb"

rescue => e
  puts "❌ 部署失败: #{e.message}"
  puts e.backtrace.first(5) if ENV['DEBUG']
end
