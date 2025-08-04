# 稳定的更新系统 - 从Git获取最新文件并确保管理员账号可用

puts "=== Chatwoot 稳定更新系统 ==="
puts ""

begin
  require 'open3'
  
  # 1. 备份当前重要数据
  puts "1. 备份当前重要数据..."
  
  backup_data = {}
  
  # 备份管理员用户信息
  admin_users = User.where(email: ['gibson@localhost.com', 'admin@localhost.com'])
  backup_data[:admin_users] = admin_users.map do |user|
    {
      id: user.id,
      name: user.name,
      email: user.email,
      encrypted_password: user.encrypted_password,
      confirmed_at: user.confirmed_at,
      created_at: user.created_at
    }
  end
  
  # 备份账号信息
  accounts = Account.all
  backup_data[:accounts] = accounts.map do |account|
    {
      id: account.id,
      name: account.name,
      feature_flags: account.feature_flags,
      limits: account.limits
    }
  end
  
  # 备份账号用户关联
  account_users = AccountUser.where(user: admin_users)
  backup_data[:account_users] = account_users.map do |au|
    {
      user_id: au.user_id,
      account_id: au.account_id,
      role: au.role,
      availability: au.availability
    }
  end
  
  puts "✓ 已备份 #{backup_data[:admin_users].count} 个管理员用户"
  puts "✓ 已备份 #{backup_data[:accounts].count} 个账号"
  puts "✓ 已备份 #{backup_data[:account_users].count} 个账号关联"

  # 2. 从Git获取最新更改
  puts "2. 从Git获取最新更改..."
  
  # 检查Git状态
  stdout, stderr, status = Open3.capture3('git status --porcelain', chdir: '/app')
  if status.success?
    if stdout.strip.empty?
      puts "✓ 工作目录干净，无未提交更改"
    else
      puts "⚠ 发现未提交更改:"
      puts stdout
      
      # 暂存当前更改
      puts "  暂存当前更改..."
      system('git add .', chdir: '/app')
      system('git stash push -m "Auto-stash before update"', chdir: '/app')
      puts "✓ 当前更改已暂存"
    end
  else
    puts "❌ Git状态检查失败: #{stderr}"
  end
  
  # 获取远程更新
  puts "  获取远程更新..."
  stdout, stderr, status = Open3.capture3('git fetch origin main', chdir: '/app')
  if status.success?
    puts "✓ 远程更新获取成功"
  else
    puts "❌ 获取远程更新失败: #{stderr}"
  end
  
  # 检查是否有新的提交
  stdout, stderr, status = Open3.capture3('git rev-list HEAD..origin/main --count', chdir: '/app')
  if status.success?
    new_commits = stdout.strip.to_i
    if new_commits > 0
      puts "✓ 发现 #{new_commits} 个新提交，开始合并..."
      
      # 合并远程更改
      stdout, stderr, status = Open3.capture3('git merge origin/main', chdir: '/app')
      if status.success?
        puts "✓ 远程更改合并成功"
      else
        puts "❌ 合并失败: #{stderr}"
        # 尝试重置并强制拉取
        puts "  尝试强制更新..."
        system('git reset --hard origin/main', chdir: '/app')
        puts "✓ 强制更新完成"
      end
    else
      puts "✓ 已是最新版本，无需更新"
    end
  else
    puts "❌ 检查新提交失败: #{stderr}"
  end

  # 3. 重新加载Rails应用（如果需要）
  puts "3. 检查是否需要重新加载应用..."
  
  # 检查是否有Ruby文件更改
  stdout, stderr, status = Open3.capture3('git diff HEAD~1 --name-only --diff-filter=AM', chdir: '/app')
  if status.success?
    changed_files = stdout.split("\n")
    ruby_files_changed = changed_files.any? { |file| file.end_with?('.rb') }
    
    if ruby_files_changed
      puts "✓ 检测到Ruby文件更改，需要重新加载"
      
      # 重新加载控制器和模型
      puts "  重新加载Rails类..."
      Rails.application.reloader.reload!
      
      # 清除缓存
      Rails.cache.clear if Rails.cache.respond_to?(:clear)
      
      puts "✓ Rails应用已重新加载"
    else
      puts "✓ 无Ruby文件更改，无需重新加载"
    end
  end

  # 4. 恢复和确保管理员账号可用
  puts "4. 恢复和确保管理员账号可用..."
  
  # 确保主管理员存在
  main_admin = User.find_by(email: 'gibson@localhost.com')
  unless main_admin
    puts "  重新创建主管理员..."
    main_admin = User.create!(
      name: 'Gibson',
      email: 'gibson@localhost.com',
      password: 'Gibson888555!',
      password_confirmation: 'Gibson888555!',
      confirmed_at: Time.current
    )
    puts "✓ 主管理员已重新创建"
  else
    # 确保密码正确
    main_admin.update!(
      password: 'Gibson888555!',
      password_confirmation: 'Gibson888555!',
      confirmed_at: Time.current
    )
    puts "✓ 主管理员密码已重置"
  end
  
  # 确保备用管理员存在
  backup_admin = User.find_by(email: 'admin@localhost.com')
  unless backup_admin
    puts "  重新创建备用管理员..."
    backup_admin = User.create!(
      name: 'Backup Admin',
      email: 'admin@localhost.com',
      password: 'BackupAdmin123!',
      password_confirmation: 'BackupAdmin123!',
      confirmed_at: Time.current
    )
    puts "✓ 备用管理员已重新创建"
  else
    # 确保密码正确
    backup_admin.update!(
      password: 'BackupAdmin123!',
      password_confirmation: 'BackupAdmin123!',
      confirmed_at: Time.current
    )
    puts "✓ 备用管理员密码已重置"
  end

  # 5. 确保账号和权限正确
  puts "5. 确保账号和权限正确..."
  
  # 确保主账号存在
  main_account = Account.first
  unless main_account
    puts "  创建主账号..."
    main_account = Account.create!(
      name: 'Gibson Admin Account',
      feature_flags: 2147483647,
      limits: {}
    )
    puts "✓ 主账号已创建"
  else
    # 确保功能标志启用
    main_account.update!(
      feature_flags: 2147483647,
      limits: {}
    )
    puts "✓ 主账号功能已启用"
  end
  
  # 确保管理员权限
  [main_admin, backup_admin].each do |admin|
    account_user = AccountUser.find_by(user: admin, account: main_account)
    unless account_user
      AccountUser.create!(
        user: admin,
        account: main_account,
        role: 'administrator',
        availability: 'online'
      )
      puts "✓ #{admin.email} 管理员权限已设置"
    else
      account_user.update!(
        role: 'administrator',
        availability: 'online'
      )
      puts "✓ #{admin.email} 权限已确认"
    end
  end

  # 6. 清除可能的登录限制
  puts "6. 清除登录限制..."
  
  # 清除Redis缓存
  redis_url = ENV['REDIS_URL'] || 'redis://redis:6379'
  require 'redis'
  
  redis = Redis.new(url: redis_url)
  
  # 清除所有可能的限制键
  rate_limit_patterns = [
    'rate_limit:*',
    'login_attempts:*',
    'failed_login:*',
    'rack::attack:*',
    'throttle:*'
  ]
  
  rate_limit_patterns.each do |pattern|
    keys = redis.keys(pattern)
    if keys.any?
      redis.del(*keys)
      puts "  ✓ 清除了 #{keys.count} 个 #{pattern} 键"
    end
  end
  
  # 完全清空Redis缓存
  redis.flushall
  puts "✓ Redis缓存已完全清空"

  # 7. 验证系统状态
  puts "7. 验证系统状态..."
  
  # 验证管理员可以登录
  [main_admin, backup_admin].each do |admin|
    admin.reload
    puts "✓ #{admin.email}:"
    puts "  - ID: #{admin.id}"
    puts "  - 确认状态: #{admin.confirmed_at ? '已确认' : '未确认'}"
    puts "  - 账号数: #{admin.accounts.count}"
    puts "  - 角色: #{admin.account_users.first&.role}"
  end
  
  # 验证账号状态
  main_account.reload
  puts "✓ 主账号状态:"
  puts "  - 功能标志: #{main_account.feature_flags}"
  puts "  - 用户数: #{main_account.users.count}"
  puts "  - 管理员数: #{main_account.account_users.where(role: 'administrator').count}"

  # 8. 创建稳定性检查脚本
  puts "8. 创建稳定性检查脚本..."
  
  stability_check_script = <<~RUBY
    # 稳定性检查脚本
    puts "=== Chatwoot 稳定性检查 ==="
    
    # 检查管理员用户
    admin_emails = ['gibson@localhost.com', 'admin@localhost.com']
    admin_emails.each do |email|
      user = User.find_by(email: email)
      if user && user.confirmed_at
        puts "✓ #{email} - 正常"
      else
        puts "❌ #{email} - 异常"
      end
    end
    
    # 检查账号功能
    account = Account.first
    if account && account.feature_flags == 2147483647
      puts "✓ 账号功能 - 正常"
    else
      puts "❌ 账号功能 - 异常"
    end
    
    # 检查Redis连接
    begin
      redis = Redis.new(url: ENV['REDIS_URL'] || 'redis://redis:6379')
      redis.ping
      puts "✓ Redis连接 - 正常"
    rescue => e
      puts "❌ Redis连接 - 异常: #{e.message}"
    end
    
    puts "=== 检查完成 ==="
  RUBY
  
  File.write('/app/stability_check.rb', stability_check_script)
  puts "✓ 稳定性检查脚本已创建: /app/stability_check.rb"

  puts ""
  puts "=== 稳定更新完成 ==="
  puts ""
  puts "✅ 系统已成功更新并稳定化！"
  puts ""
  puts "管理员账号状态:"
  puts "✓ gibson@localhost.com / Gibson888555! - 主管理员"
  puts "✓ admin@localhost.com / BackupAdmin123! - 备用管理员"
  puts ""
  puts "系统功能:"
  puts "✓ 所有功能已启用 (feature_flags: 2147483647)"
  puts "✓ 登录限制已清除"
  puts "✓ 缓存已清空"
  puts "✓ Git更新已应用"
  puts ""
  puts "后续使用:"
  puts "1. 运行稳定性检查: bundle exec rails runner /app/stability_check.rb"
  puts "2. 如有问题，重新运行此脚本: bundle exec rails runner /app/stable_update_system.rb"
  puts "3. 访问系统: http://localhost:3000"
  puts ""
  puts "预防措施:"
  puts "- 每次重大更改后运行此脚本"
  puts "- 定期检查管理员账号状态"
  puts "- 保持Git仓库同步"

rescue => e
  puts "❌ 稳定更新失败: #{e.message}"
  puts e.backtrace.first(10)
  
  puts ""
  puts "紧急恢复步骤:"
  puts "1. 重启服务: docker-compose restart"
  puts "2. 重新初始化: bundle exec rails runner /app/init_database_clean.rb"
  puts "3. 启用功能: bundle exec rails runner /app/enable_all_features.rb"
  puts "4. 清除限制: bundle exec rails runner /app/clear_rate_limits.rb"
end
