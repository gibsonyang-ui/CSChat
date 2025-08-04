# 修复权限和功能完整性

puts "=== 修复Chatwoot权限和功能 ==="
puts ""

begin
  # 获取管理员用户和账号
  admin_user = User.find_by(email: 'gibson@localhost.com')
  admin_account = admin_user.accounts.first
  
  puts "管理员用户: #{admin_user.name} (#{admin_user.email})"
  puts "管理员账号: #{admin_account.name}"
  puts ""
  
  # 1. 确保管理员有完整权限
  puts "1. 设置管理员完整权限..."
  admin_account_user = AccountUser.find_by(user: admin_user, account: admin_account)
  admin_account_user.update!(role: 'administrator')
  puts "✓ 管理员角色已设置"
  
  # 2. 启用所有功能标志
  puts "2. 启用所有功能标志..."
  admin_account.update!(
    feature_flags: {
      'agent_management' => true,
      'team_management' => true,
      'inbox_management' => true,
      'labels' => true,
      'custom_attributes' => true,
      'automation_rules' => true,
      'canned_responses' => true,
      'integrations' => true,
      'campaigns' => true,
      'help_center' => true,
      'voice_recorder' => true,
      'emoji_picker' => true,
      'attachment_processor' => true
    },
    limits: {}
  )
  puts "✓ 所有功能已启用"
  
  # 3. 创建默认标签（修复标签问题）
  puts "3. 创建默认标签..."
  default_labels = [
    { title: 'urgent', description: 'Urgent issues', color: '#FF6B6B' },
    { title: 'bug', description: 'Bug reports', color: '#FFA500' },
    { title: 'feature', description: 'Feature requests', color: '#4ECDC4' },
    { title: 'question', description: 'General questions', color: '#45B7D1' }
  ]
  
  default_labels.each do |label_data|
    label = admin_account.labels.find_or_create_by(title: label_data[:title]) do |l|
      l.description = label_data[:description]
      l.color = label_data[:color]
    end
    puts "✓ 标签创建: #{label.title}"
  end
  
  # 4. 创建默认快捷回复
  puts "4. 创建默认快捷回复..."
  default_responses = [
    {
      short_code: 'hello',
      content: 'Hello! How can I help you today?'
    },
    {
      short_code: 'thanks',
      content: 'Thank you for contacting us. Have a great day!'
    }
  ]
  
  default_responses.each do |response_data|
    canned_response = admin_account.canned_responses.find_or_create_by(
      short_code: response_data[:short_code]
    ) do |cr|
      cr.content = response_data[:content]
    end
    puts "✓ 快捷回复创建: #{canned_response.short_code}"
  end
  
  # 5. 确保收件箱配置完整
  puts "5. 配置收件箱..."
  inbox = admin_account.inboxes.first
  if inbox
    # 确保管理员在收件箱中
    unless inbox.inbox_members.exists?(user: admin_user)
      inbox.inbox_members.create!(user: admin_user)
    end
    puts "✓ 管理员已添加到收件箱"
    
    # 配置收件箱设置
    inbox.update!(
      enable_auto_assignment: true,
      enable_email_collect: true,
      greeting_enabled: true,
      greeting_message: 'Hi there! Welcome to our support chat.'
    )
    puts "✓ 收件箱设置已配置"
  end
  
  # 6. 创建默认自定义属性
  puts "6. 创建默认自定义属性..."
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
    custom_attr = admin_account.custom_attribute_definitions.find_or_create_by(
      attribute_key: attr_data[:attribute_key]
    ) do |attr|
      attr.attribute_display_name = attr_data[:attribute_display_name]
      attr.attribute_display_type = attr_data[:attribute_display_type]
      attr.attribute_values = attr_data[:attribute_values]
      attr.attribute_model = attr_data[:attribute_model]
    end
    puts "✓ 自定义属性创建: #{custom_attr.attribute_display_name}"
  end
  
  # 7. 设置工作时间
  puts "7. 设置工作时间..."
  working_hour = admin_account.working_hours.find_or_create_by(inbox: inbox) do |wh|
    wh.day_of_week = 1
    wh.closed_all_day = false
    wh.open_hour = 9
    wh.open_minutes = 0
    wh.close_hour = 17
    wh.close_minutes = 0
  end
  puts "✓ 工作时间已设置"
  
  # 8. 创建测试用户（如果不存在）
  puts "8. 创建测试用户..."
  test_user = User.find_or_create_by(email: 'agent@example.com') do |user|
    user.name = 'Test Agent'
    user.password = 'TestAgent123!'
    user.password_confirmation = 'TestAgent123!'
    user.confirmed_at = Time.current
  end
  
  if test_user.persisted?
    # 将测试用户添加到账号
    AccountUser.find_or_create_by(user: test_user, account: admin_account) do |au|
      au.role = 'agent'
    end
    
    # 将测试用户添加到收件箱
    if inbox
      inbox.inbox_members.find_or_create_by(user: test_user)
    end
    
    puts "✓ 测试代理用户创建: #{test_user.email}"
  end
  
  puts ""
  puts "=== 权限和功能修复完成 ==="
  puts ""
  puts "现在您的账号具有以下完整功能:"
  puts "✓ 用户管理 - 可以添加、编辑、删除用户"
  puts "✓ 账号设置 - 可以修改账号配置"
  puts "✓ 收件箱管理 - 可以创建和配置收件箱"
  puts "✓ 团队管理 - 可以创建和管理团队"
  puts "✓ 联系人管理 - 可以管理客户联系人"
  puts "✓ 标签管理 - 可以创建和使用标签"
  puts "✓ 自定义属性 - 可以创建自定义字段"
  puts "✓ 快捷回复 - 可以创建快捷回复模板"
  puts "✓ 自动化规则 - 可以设置自动化流程"
  puts "✓ 工作时间 - 可以设置营业时间"
  puts "✓ 报告分析 - 可以查看统计报告"
  puts ""
  puts "登录信息:"
  puts "管理员 - gibson@localhost.com / Gibson888555!"
  puts "代理 - agent@example.com / TestAgent123!"
  
rescue => e
  puts "✗ 修复过程中出错: #{e.message}"
  puts e.backtrace.first(5)
end
