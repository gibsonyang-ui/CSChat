# 检查用户权限和界面功能

puts "=== 检查用户权限和界面功能 ==="
puts ""

begin
  # 检查管理员用户
  admin_user = User.find_by(email: 'gibson@localhost.com')
  if admin_user
    puts "管理员用户: #{admin_user.name} (#{admin_user.email})"
    puts "用户ID: #{admin_user.id}"
    puts "确认状态: #{admin_user.confirmed_at ? '已确认' : '未确认'}"
    puts "创建时间: #{admin_user.created_at}"
    puts ""
    
    # 检查账号关联
    admin_user.account_users.each do |au|
      puts "账号: #{au.account.name} (ID: #{au.account.id})"
      puts "角色: #{au.role}"
      puts "权限: #{au.administrator? ? '管理员' : '普通用户'}"
      puts "可用性: #{au.availability}"
      puts ""
      
      # 检查账号功能标志
      account = au.account
      puts "账号功能标志: #{account.feature_flags}"
      puts "账号限制: #{account.limits}"
      puts ""
      
      # 检查收件箱
      puts "收件箱数量: #{account.inboxes.count}"
      account.inboxes.each do |inbox|
        puts "  - #{inbox.name} (#{inbox.channel_type})"
      end
      puts ""
      
      # 检查用户数量
      puts "总用户数: #{account.users.count}"
      puts "管理员数: #{account.account_users.where(role: 'administrator').count}"
      puts "代理数: #{account.account_users.where(role: 'agent').count}"
      puts ""
      
      # 检查账号设置
      puts "账号设置检查:"
      puts "- 自动分配: #{account.auto_resolve_duration || '未设置'}"
      puts "- 工作时间: #{account.working_hours.count} 个配置"
      puts "- 自定义属性: #{account.custom_attribute_definitions.count} 个"
      puts "- 标签: #{account.labels.count} 个"
      puts "- 团队: #{account.teams.count} 个"
      puts ""
    end
  else
    puts "❌ 找不到管理员用户"
    exit 1
  end

  # 检查应用配置
  puts "=== 应用配置检查 ==="
  puts "Rails环境: #{Rails.env}"
  puts "安装环境: #{ENV['INSTALLATION_ENV']}"
  puts "前端URL: #{ENV['FRONTEND_URL']}"
  puts "启用注册: #{ENV['ENABLE_ACCOUNT_SIGNUP']}"
  puts ""

  # 检查数据库表
  puts "=== 数据库表检查 ==="
  important_tables = [
    'users', 'accounts', 'account_users', 'inboxes', 
    'conversations', 'messages', 'contacts', 'teams'
  ]
  
  important_tables.each do |table|
    if ActiveRecord::Base.connection.table_exists?(table)
      count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{table}").first['count']
      puts "✓ #{table}: #{count} 条记录"
    else
      puts "✗ #{table}: 表不存在"
    end
  end
  puts ""

  # 检查路由
  puts "=== 路由检查 ==="
  routes = Rails.application.routes.routes
  agent_routes = routes.select { |r| r.path.spec.to_s.include?('agent') }
  puts "代理相关路由数量: #{agent_routes.count}"
  
  settings_routes = routes.select { |r| r.path.spec.to_s.include?('setting') }
  puts "设置相关路由数量: #{settings_routes.count}"
  puts ""

rescue => e
  puts "❌ 检查失败: #{e.message}"
  puts e.backtrace.first(5)
end
