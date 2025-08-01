# Chatwoot 用户管理脚本
# 使用方法: docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner manage_users.rb

puts "=== Chatwoot 用户管理工具 ==="
puts ""

# 显示所有用户
def list_users
  puts "当前系统用户:"
  puts "-" * 50
  User.all.each_with_index do |user, index|
    puts "#{index + 1}. #{user.name} (#{user.email})"
    puts "   创建时间: #{user.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    puts "   确认状态: #{user.confirmed_at ? '已确认' : '未确认'}"
    
    # 显示用户的账号和角色
    user.account_users.each do |au|
      puts "   账号: #{au.account.name} - 角色: #{au.role}"
    end
    puts ""
  end
end

# 修改用户密码
def change_password(email, new_password)
  user = User.find_by(email: email)
  if user
    user.update!(
      password: new_password,
      password_confirmation: new_password
    )
    puts "✓ 用户 #{email} 的密码已更新"
  else
    puts "✗ 找不到邮箱为 #{email} 的用户"
  end
end

# 创建新用户
def create_user(name, email, password, account_name = nil)
  # 检查用户是否已存在
  if User.find_by(email: email)
    puts "✗ 邮箱 #{email} 已被使用"
    return
  end
  
  # 创建用户
  user = User.create!(
    name: name,
    email: email,
    password: password,
    password_confirmation: password,
    confirmed_at: Time.current
  )
  
  puts "✓ 用户创建成功: #{user.name} (#{user.email})"
  
  # 如果指定了账号名称，将用户添加到账号
  if account_name
    account = Account.find_by(name: account_name) || Account.first
    if account
      AccountUser.create!(
        account: account,
        user: user,
        role: 'agent'
      )
      puts "✓ 用户已添加到账号: #{account.name}"
    end
  end
end

# 删除用户
def delete_user(email)
  user = User.find_by(email: email)
  if user
    # 删除用户的账号关联
    user.account_users.destroy_all
    # 删除用户
    user.destroy!
    puts "✓ 用户 #{email} 已删除"
  else
    puts "✗ 找不到邮箱为 #{email} 的用户"
  end
end

# 设置用户角色
def set_user_role(email, account_name, role)
  user = User.find_by(email: email)
  account = Account.find_by(name: account_name)
  
  if user && account
    account_user = AccountUser.find_by(user: user, account: account)
    if account_user
      account_user.update!(role: role)
      puts "✓ 用户 #{email} 在账号 #{account_name} 中的角色已设置为: #{role}"
    else
      # 创建新的关联
      AccountUser.create!(
        user: user,
        account: account,
        role: role
      )
      puts "✓ 用户 #{email} 已添加到账号 #{account_name}，角色: #{role}"
    end
  else
    puts "✗ 找不到指定的用户或账号"
  end
end

# 主菜单
def main_menu
  loop do
    puts ""
    puts "请选择操作:"
    puts "1. 查看所有用户"
    puts "2. 修改用户密码"
    puts "3. 创建新用户"
    puts "4. 删除用户"
    puts "5. 设置用户角色"
    puts "6. 退出"
    print "请输入选项 (1-6): "
    
    choice = STDIN.gets.chomp
    
    case choice
    when '1'
      list_users
    when '2'
      print "请输入用户邮箱: "
      email = STDIN.gets.chomp
      print "请输入新密码: "
      password = STDIN.gets.chomp
      change_password(email, password)
    when '3'
      print "请输入用户姓名: "
      name = STDIN.gets.chomp
      print "请输入用户邮箱: "
      email = STDIN.gets.chomp
      print "请输入密码: "
      password = STDIN.gets.chomp
      print "请输入账号名称 (可选): "
      account_name = STDIN.gets.chomp
      account_name = nil if account_name.empty?
      create_user(name, email, password, account_name)
    when '4'
      print "请输入要删除的用户邮箱: "
      email = STDIN.gets.chomp
      print "确认删除用户 #{email}? (y/N): "
      confirm = STDIN.gets.chomp.downcase
      if confirm == 'y'
        delete_user(email)
      else
        puts "操作已取消"
      end
    when '5'
      print "请输入用户邮箱: "
      email = STDIN.gets.chomp
      print "请输入账号名称: "
      account_name = STDIN.gets.chomp
      print "请输入角色 (administrator/agent): "
      role = STDIN.gets.chomp
      set_user_role(email, account_name, role)
    when '6'
      puts "再见！"
      break
    else
      puts "无效选项，请重新选择"
    end
  end
end

# 如果直接运行脚本，显示当前用户并启动菜单
if __FILE__ == $0
  list_users
  
  # 检查是否在交互模式下运行
  if STDIN.tty?
    main_menu
  else
    puts ""
    puts "要使用交互模式，请运行:"
    puts "docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner -e production manage_users.rb"
  end
end
