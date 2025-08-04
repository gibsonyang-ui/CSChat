# 设置jesse@localhost.com管理员账号

puts "=== 设置jesse@localhost.com管理员账号 ==="
puts ""

begin
  # 1. 查找或创建jesse用户
  puts "1. 查找或创建jesse用户..."
  
  jesse_user = User.find_by(email: 'jesse@localhost.com')
  
  if jesse_user
    puts "✓ 找到现有用户: #{jesse_user.name} (ID: #{jesse_user.id})"
    puts "  - 当前确认状态: #{jesse_user.confirmed_at ? '已确认' : '未确认'}"
    puts "  - 创建时间: #{jesse_user.created_at}"
  else
    puts "❌ 用户不存在，正在创建..."
    
    jesse_user = User.create!(
      name: 'Jesse',
      email: 'jesse@localhost.com',
      password: 'Jesse1234!',
      password_confirmation: 'Jesse1234!',
      confirmed_at: Time.current
    )
    
    puts "✓ Jesse用户已创建: #{jesse_user.name} (ID: #{jesse_user.id})"
  end

  # 2. 更新密码和确认状态
  puts "2. 更新密码和确认状态..."
  
  jesse_user.update!(
    password: 'Jesse1234!',
    password_confirmation: 'Jesse1234!',
    confirmed_at: Time.current
  )
  
  puts "✓ 密码已设置为: Jesse1234!"
  puts "✓ 账号已设置为已认证状态"

  # 3. 确保管理员权限
  puts "3. 确保管理员权限..."
  
  # 获取主账号
  main_account = Account.first
  unless main_account
    puts "❌ 没有找到主账号，正在创建..."
    main_account = Account.create!(
      name: 'Main Account',
      feature_flags: 2147483647,
      limits: {}
    )
    puts "✓ 主账号已创建"
  end
  
  puts "✓ 主账号: #{main_account.name} (ID: #{main_account.id})"

  # 4. 设置账号用户关联
  puts "4. 设置账号用户关联..."
  
  account_user = AccountUser.find_by(user: jesse_user, account: main_account)
  
  if account_user
    puts "✓ 找到现有账号关联"
    puts "  - 当前角色: #{account_user.role}"
    puts "  - 当前可用性: #{account_user.availability}"
    
    # 更新为管理员权限
    account_user.update!(
      role: 'administrator',
      availability: 'online'
    )
    puts "✓ 权限已更新为管理员"
  else
    puts "❌ 账号关联不存在，正在创建..."
    
    account_user = AccountUser.create!(
      user: jesse_user,
      account: main_account,
      role: 'administrator',
      availability: 'online'
    )
    puts "✓ 管理员权限已设置"
  end

  # 5. 添加到收件箱（如果存在）
  puts "5. 添加到收件箱..."
  
  inboxes = main_account.inboxes
  if inboxes.any?
    inboxes.each do |inbox|
      inbox_member = inbox.inbox_members.find_by(user: jesse_user)
      unless inbox_member
        inbox.inbox_members.create!(user: jesse_user)
        puts "✓ 已添加到收件箱: #{inbox.name}"
      else
        puts "✓ 已在收件箱中: #{inbox.name}"
      end
    end
  else
    puts "⚠ 没有找到收件箱"
  end

  # 6. 添加到团队（如果存在）
  puts "6. 添加到团队..."
  
  teams = main_account.teams
  if teams.any?
    teams.each do |team|
      team_member = team.team_members.find_by(user: jesse_user)
      unless team_member
        team.team_members.create!(user: jesse_user)
        puts "✓ 已添加到团队: #{team.name}"
      else
        puts "✓ 已在团队中: #{team.name}"
      end
    end
  else
    puts "⚠ 没有找到团队"
  end

  # 7. 验证最终状态
  puts "7. 验证最终状态..."
  
  jesse_user.reload
  account_user.reload
  
  puts ""
  puts "=== Jesse管理员账号设置完成 ==="
  puts ""
  puts "✅ 账号信息:"
  puts "  - 邮箱: #{jesse_user.email}"
  puts "  - 姓名: #{jesse_user.name}"
  puts "  - 密码: Jesse1234!"
  puts "  - 用户ID: #{jesse_user.id}"
  puts ""
  puts "✅ 状态信息:"
  puts "  - 确认状态: #{jesse_user.confirmed_at ? '已确认' : '未确认'}"
  puts "  - 确认时间: #{jesse_user.confirmed_at}"
  puts "  - 角色: #{account_user.role}"
  puts "  - 权限: #{account_user.administrator? ? '管理员' : '普通用户'}"
  puts "  - 可用性: #{account_user.availability}"
  puts ""
  puts "✅ 关联信息:"
  puts "  - 所属账号: #{main_account.name}"
  puts "  - 收件箱数: #{jesse_user.inbox_members.count}"
  puts "  - 团队数: #{jesse_user.team_members.count}"
  puts ""
  puts "现在可以使用以下信息登录:"
  puts "邮箱: jesse@localhost.com"
  puts "密码: Jesse1234!"
  puts ""
  puts "登录地址: http://localhost:3000"

rescue => e
  puts "❌ 设置失败: #{e.message}"
  puts e.backtrace.first(5)
end
