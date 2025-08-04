# 修复账号功能标志

puts "=== 修复账号功能标志 ==="

begin
  # 获取管理员用户和账号
  admin_user = User.find_by(email: 'gibson@localhost.com')
  admin_account = admin_user.accounts.first
  
  puts "管理员账号: #{admin_account.name}"
  
  # 检查当前的feature_flags字段
  puts "当前feature_flags: #{admin_account.feature_flags.inspect}"
  
  # 使用SQL直接更新，避免Rails验证问题
  ActiveRecord::Base.connection.execute(
    "UPDATE accounts SET feature_flags = 2147483647 WHERE id = #{admin_account.id}"
  )
  
  puts "✓ 功能标志已更新"
  
  # 重新加载账号
  admin_account.reload
  puts "新的feature_flags: #{admin_account.feature_flags}"
  
  # 确保管理员权限
  admin_account_user = AccountUser.find_by(user: admin_user, account: admin_account)
  admin_account_user.update!(role: 'administrator')
  puts "✓ 管理员权限已确认"
  
  # 创建默认标签
  puts "创建默认标签..."
  default_labels = [
    { title: 'urgent', description: 'Urgent issues', color: '#FF6B6B' },
    { title: 'bug', description: 'Bug reports', color: '#FFA500' },
    { title: 'feature', description: 'Feature requests', color: '#4ECDC4' }
  ]
  
  default_labels.each do |label_data|
    begin
      label = admin_account.labels.find_or_create_by(title: label_data[:title]) do |l|
        l.description = label_data[:description]
        l.color = label_data[:color]
      end
      puts "✓ 标签: #{label.title}"
    rescue => e
      puts "⚠ 标签创建警告: #{e.message}"
    end
  end
  
  # 创建测试代理用户
  puts "创建测试代理用户..."
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
    puts "✓ 测试代理用户: #{test_user.email}"
  end
  
  puts ""
  puts "=== 修复完成 ==="
  puts ""
  puts "现在您应该可以访问所有管理功能:"
  puts "✓ 用户管理 - 添加、编辑、删除用户"
  puts "✓ 账号设置 - 修改账号配置"
  puts "✓ 收件箱管理 - 创建和配置收件箱"
  puts "✓ 团队管理 - 创建和管理团队"
  puts "✓ 标签管理 - 创建和使用标签"
  puts "✓ 报告分析 - 查看统计数据"
  puts ""
  puts "登录信息:"
  puts "管理员: gibson@localhost.com / Gibson888555!"
  puts "代理: agent@example.com / TestAgent123!"
  
rescue => e
  puts "✗ 修复失败: #{e.message}"
end
