# Chatwoot 用户管理脚本

puts "=== Chatwoot 用户管理 ==="
puts ""

# 显示所有用户
puts "当前系统用户:"
puts "-" * 50

if User.count == 0
  puts "没有用户"
else
  User.all.each_with_index do |user, index|
    puts "#{index + 1}. #{user.name} (#{user.email})"
    puts "   ID: #{user.id}"
    puts "   创建时间: #{user.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "   确认状态: #{user.confirmed_at ? '已确认' : '未确认'}"
    puts "   最后登录: #{user.last_sign_in_at || '从未登录'}"
    
    # 显示用户的账号关联
    if user.account_users.any?
      user.account_users.each do |au|
        puts "   账号: #{au.account.name} - 角色: #{au.role}"
      end
    else
      puts "   账号: 无关联账号"
    end
    puts ""
  end
end

puts ""
puts "系统账号:"
puts "-" * 50

if Account.count == 0
  puts "没有账号"
else
  Account.all.each_with_index do |account, index|
    puts "#{index + 1}. #{account.name} (ID: #{account.id})"
    puts "   创建时间: #{account.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "   用户数量: #{account.users.count}"
    
    if account.users.any?
      account.users.each do |user|
        role = account.account_users.find_by(user: user)&.role || '未知'
        puts "     - #{user.name} (#{user.email}) - #{role}"
      end
    end
    puts ""
  end
end

puts ""
puts "快速操作命令:"
puts "1. 重置Gibson密码: docker exec cschat-rails-1 bundle exec rails runner /app/simple_password_reset.rb"
puts "2. 查看用户列表: docker exec cschat-rails-1 bundle exec rails runner /app/user_management.rb"
puts "3. 进入Rails控制台: docker exec -it cschat-rails-1 bundle exec rails console"
puts ""
puts "在Rails控制台中的常用命令:"
puts "- User.all                    # 查看所有用户"
puts "- User.find_by(email: 'xxx')  # 查找用户"
puts "- user.update(password: 'xxx') # 更新密码"
puts "- Account.all                 # 查看所有账号"
