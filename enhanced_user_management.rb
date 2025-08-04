# 增强的Chatwoot用户管理脚本 - 支持管理员完整账号管理功能

puts "=== 增强的Chatwoot用户管理系统 ==="
puts ""

class EnhancedUserManager
  def initialize
    @current_admin = User.find_by(email: 'gibson@localhost.com')
    @current_account = @current_admin&.accounts&.first
    
    unless @current_admin&.account_users&.find_by(account: @current_account)&.administrator?
      puts "❌ 错误: 需要管理员权限才能使用此功能"
      exit 1
    end
    
    puts "✓ 管理员: #{@current_admin.name} (#{@current_admin.email})"
    puts "✓ 当前账号: #{@current_account.name}"
    puts ""
  end

  # 显示所有用户
  def list_users
    puts "=== 用户列表 ==="
    puts ""
    
    @current_account.users.each_with_index do |user, index|
      account_user = user.account_users.find_by(account: @current_account)
      
      puts "#{index + 1}. #{user.name} (#{user.email})"
      puts "   ID: #{user.id}"
      puts "   角色: #{account_user&.role || '无角色'}"
      puts "   认证状态: #{user.confirmed_at ? '已认证' : '未认证'}"
      puts "   创建时间: #{user.created_at.strftime('%Y-%m-%d %H:%M:%S')}"
      puts "   最后登录: #{user.last_sign_in_at&.strftime('%Y-%m-%d %H:%M:%S') || '从未登录'}"
      puts "   登录次数: #{user.sign_in_count}"
      puts ""
    end
  end

  # 创建新用户 - 增强版
  def create_user_enhanced
    puts "=== 创建新用户 ==="
    puts ""
    
    print "用户姓名: "
    name = gets_input
    return if name.empty?
    
    print "邮箱地址: "
    email = gets_input
    return if email.empty?
    
    # 检查邮箱是否已存在
    if User.find_by(email: email)
      puts "❌ 错误: 邮箱 #{email} 已被使用"
      return
    end
    
    print "密码 (留空使用默认密码): "
    password = gets_input
    password = generate_default_password if password.empty?
    
    print "角色 (1=管理员, 2=代理) [默认: 2]: "
    role_input = gets_input
    role = case role_input
           when '1' then 'administrator'
           else 'agent'
           end
    
    print "是否立即认证账号? (y/N) [默认: N]: "
    confirm_input = gets_input.downcase
    confirmed_at = confirm_input == 'y' ? Time.current : nil
    
    begin
      # 创建用户
      user = User.create!(
        name: name,
        email: email,
        password: password,
        password_confirmation: password,
        confirmed_at: confirmed_at
      )
      
      # 添加到当前账号
      AccountUser.create!(
        user: user,
        account: @current_account,
        role: role,
        inviter: @current_admin
      )
      
      puts ""
      puts "✓ 用户创建成功!"
      puts "  姓名: #{user.name}"
      puts "  邮箱: #{user.email}"
      puts "  密码: #{password}"
      puts "  角色: #{role}"
      puts "  认证状态: #{confirmed_at ? '已认证' : '未认证'}"
      
      # 如果未认证，提供认证选项
      unless confirmed_at
        puts ""
        puts "⚠ 用户需要邮箱认证才能登录"
        print "是否现在手动认证? (y/N): "
        if gets_input.downcase == 'y'
          confirm_user(user)
        end
      end
      
    rescue => e
      puts "❌ 用户创建失败: #{e.message}"
    end
  end

  # 修改用户密码 - 增强版
  def change_user_password
    puts "=== 修改用户密码 ==="
    puts ""
    
    print "请输入用户邮箱: "
    email = gets_input
    return if email.empty?
    
    user = @current_account.users.find_by(email: email)
    unless user
      puts "❌ 错误: 找不到邮箱为 #{email} 的用户"
      return
    end
    
    puts "用户信息: #{user.name} (#{user.email})"
    puts ""
    
    print "新密码 (留空自动生成): "
    new_password = gets_input
    new_password = generate_default_password if new_password.empty?
    
    print "是否要求用户下次登录时修改密码? (y/N): "
    force_change = gets_input.downcase == 'y'
    
    begin
      user.update!(
        password: new_password,
        password_confirmation: new_password
      )
      
      # 如果要求强制修改密码，可以设置一个标志
      if force_change
        user.update!(custom_attributes: user.custom_attributes.merge('force_password_change' => true))
      end
      
      puts ""
      puts "✓ 密码修改成功!"
      puts "  用户: #{user.name}"
      puts "  新密码: #{new_password}"
      puts "  强制修改: #{force_change ? '是' : '否'}"
      
    rescue => e
      puts "❌ 密码修改失败: #{e.message}"
    end
  end

  # 管理用户认证状态
  def manage_user_confirmation
    puts "=== 管理用户认证状态 ==="
    puts ""
    
    print "请输入用户邮箱: "
    email = gets_input
    return if email.empty?
    
    user = @current_account.users.find_by(email: email)
    unless user
      puts "❌ 错误: 找不到邮箱为 #{email} 的用户"
      return
    end
    
    puts "用户信息: #{user.name} (#{user.email})"
    puts "当前认证状态: #{user.confirmed_at ? '已认证' : '未认证'}"
    puts ""
    
    if user.confirmed_at
      print "是否要取消用户认证? (y/N): "
      if gets_input.downcase == 'y'
        user.update!(confirmed_at: nil)
        puts "✓ 用户认证已取消，用户需要重新认证邮箱"
      end
    else
      print "是否要认证用户? (y/N): "
      if gets_input.downcase == 'y'
        confirm_user(user)
      end
    end
  end

  # 修改用户角色
  def change_user_role
    puts "=== 修改用户角色 ==="
    puts ""
    
    print "请输入用户邮箱: "
    email = gets_input
    return if email.empty?
    
    user = @current_account.users.find_by(email: email)
    unless user
      puts "❌ 错误: 找不到邮箱为 #{email} 的用户"
      return
    end
    
    account_user = user.account_users.find_by(account: @current_account)
    
    puts "用户信息: #{user.name} (#{user.email})"
    puts "当前角色: #{account_user&.role || '无角色'}"
    puts ""
    
    puts "可选角色:"
    puts "1. 管理员 (administrator)"
    puts "2. 代理 (agent)"
    print "请选择新角色 (1-2): "
    
    role_choice = gets_input
    new_role = case role_choice
               when '1' then 'administrator'
               when '2' then 'agent'
               else
                 puts "❌ 无效选择"
                 return
               end
    
    begin
      if account_user
        account_user.update!(role: new_role)
      else
        AccountUser.create!(
          user: user,
          account: @current_account,
          role: new_role,
          inviter: @current_admin
        )
      end
      
      puts "✓ 用户角色已更新为: #{new_role}"
      
    rescue => e
      puts "❌ 角色修改失败: #{e.message}"
    end
  end

  # 删除用户
  def delete_user
    puts "=== 删除用户 ==="
    puts ""
    
    print "请输入要删除的用户邮箱: "
    email = gets_input
    return if email.empty?
    
    user = @current_account.users.find_by(email: email)
    unless user
      puts "❌ 错误: 找不到邮箱为 #{email} 的用户"
      return
    end
    
    # 防止删除自己
    if user == @current_admin
      puts "❌ 错误: 不能删除自己的账号"
      return
    end
    
    puts "用户信息: #{user.name} (#{user.email})"
    puts "⚠ 警告: 此操作将永久删除用户及其所有数据"
    print "确认删除? 请输入 'DELETE' 确认: "
    
    confirmation = gets_input
    unless confirmation == 'DELETE'
      puts "操作已取消"
      return
    end
    
    begin
      # 删除账号关联
      user.account_users.where(account: @current_account).destroy_all
      
      # 如果用户没有其他账号关联，删除用户
      if user.account_users.empty?
        user.destroy!
        puts "✓ 用户已完全删除"
      else
        puts "✓ 用户已从当前账号移除（用户在其他账号中仍存在）"
      end
      
    rescue => e
      puts "❌ 删除失败: #{e.message}"
    end
  end

  # 主菜单
  def main_menu
    loop do
      puts ""
      puts "=== 用户管理菜单 ==="
      puts "1. 查看所有用户"
      puts "2. 创建新用户"
      puts "3. 修改用户密码"
      puts "4. 管理用户认证状态"
      puts "5. 修改用户角色"
      puts "6. 删除用户"
      puts "7. 退出"
      print "请选择操作 (1-7): "
      
      choice = gets_input
      
      case choice
      when '1' then list_users
      when '2' then create_user_enhanced
      when '3' then change_user_password
      when '4' then manage_user_confirmation
      when '5' then change_user_role
      when '6' then delete_user
      when '7'
        puts "再见!"
        break
      else
        puts "❌ 无效选择，请重新输入"
      end
    end
  end

  private

  def gets_input
    input = STDIN.gets&.chomp
    input || ""
  end

  def generate_default_password
    # 生成安全的默认密码
    chars = [*'A'..'Z', *'a'..'z', *'0'..'9', '!', '@', '#', '$', '%']
    Array.new(12) { chars.sample }.join
  end

  def confirm_user(user)
    user.update!(confirmed_at: Time.current)
    puts "✓ 用户 #{user.email} 已认证"
  end
end

# 运行管理器
if __FILE__ == $0
  begin
    manager = EnhancedUserManager.new
    
    # 检查是否在交互模式
    if STDIN.tty?
      manager.main_menu
    else
      puts "要使用交互模式，请运行:"
      puts "docker exec -it cschat-chatwoot-1 bundle exec rails runner enhanced_user_management.rb"
    end
    
  rescue => e
    puts "❌ 系统错误: #{e.message}"
    puts e.backtrace.first(3) if ENV['DEBUG']
  end
end
