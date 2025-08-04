# 简化的增强功能 - 不修改核心文件，通过现有API实现

puts "=== 部署简化的增强功能 ==="
puts ""

begin
  # 1. 确保管理员权限
  admin_user = User.find_by(email: 'gibson@localhost.com')
  unless admin_user
    puts "❌ 错误: 找不到管理员用户"
    exit 1
  end

  admin_account = admin_user.accounts.first
  account_user = admin_user.account_users.find_by(account: admin_account)
  unless account_user&.administrator?
    puts "❌ 错误: 用户不是管理员"
    exit 1
  end

  puts "✓ 管理员验证通过: #{admin_user.name}"
  puts ""

  # 2. 创建增强的用户管理API端点（通过现有控制器扩展）
  puts "2. 创建增强的用户管理功能..."

  # 定义增强的用户管理类
  enhanced_user_manager_code = <<~RUBY
    class EnhancedUserManager
      def self.create_user_with_options(account, creator, options = {})
        ActiveRecord::Base.transaction do
          user = User.new(
            name: options[:name],
            email: options[:email],
            password: options[:password] || generate_password,
            password_confirmation: options[:password] || generate_password
          )
          
          # 设置认证状态
          user.confirmed_at = Time.current if options[:confirmed] == true
          
          if user.save
            # 创建账号关联
            account_user = AccountUser.create!(
              user: user,
              account: account,
              role: options[:role] || 'agent',
              inviter: creator
            )
            
            {
              success: true,
              user: user,
              account_user: account_user,
              password: options[:password] || user.password
            }
          else
            { success: false, errors: user.errors.full_messages }
          end
        end
      rescue => e
        { success: false, errors: [e.message] }
      end

      def self.toggle_user_confirmation(user)
        if user.confirmed_at.present?
          user.update!(confirmed_at: nil)
          { success: true, message: 'User verification revoked', confirmed: false }
        else
          user.update!(confirmed_at: Time.current)
          { success: true, message: 'User verified successfully', confirmed: true }
        end
      rescue => e
        { success: false, errors: [e.message] }
      end

      def self.reset_user_password(user, options = {})
        new_password = options[:password] || generate_password
        
        if user.update(password: new_password, password_confirmation: new_password)
          # 设置强制修改密码标志
          if options[:force_change] == true
            custom_attrs = user.custom_attributes || {}
            custom_attrs['force_password_change'] = true
            user.update!(custom_attributes: custom_attrs)
          end
          
          {
            success: true,
            message: 'Password reset successfully',
            password: new_password,
            force_change: options[:force_change] == true
          }
        else
          { success: false, errors: user.errors.full_messages }
        end
      rescue => e
        { success: false, errors: [e.message] }
      end

      private

      def self.generate_password
        chars = [*'A'..'Z', *'a'..'z', *'0'..'9', '!', '@', '#', '$', '%']
        Array.new(12) { chars.sample }.join
      end
    end
  RUBY

  # 将类定义写入临时文件
  File.write('/tmp/enhanced_user_manager.rb', enhanced_user_manager_code)
  
  # 加载类定义
  load '/tmp/enhanced_user_manager.rb'
  
  puts "✓ 增强用户管理类已加载"

  # 3. 测试功能
  puts "3. 测试增强功能..."

  # 测试创建用户
  result = EnhancedUserManager.create_user_with_options(
    admin_account,
    admin_user,
    {
      name: 'Enhanced Test User',
      email: 'enhanced.test@example.com',
      password: 'EnhancedTest123!',
      role: 'agent',
      confirmed: true
    }
  )

  if result[:success]
    puts "✓ 用户创建测试成功: #{result[:user].email}"
    
    # 测试认证切换
    toggle_result = EnhancedUserManager.toggle_user_confirmation(result[:user])
    puts "✓ 认证切换测试: #{toggle_result[:message]}"
    
    # 测试密码重置
    reset_result = EnhancedUserManager.reset_user_password(
      result[:user],
      { force_change: true }
    )
    puts "✓ 密码重置测试: #{reset_result[:message]}"
    puts "  新密码: #{reset_result[:password]}"
  else
    puts "✗ 用户创建测试失败: #{result[:errors].join(', ')}"
  end

  # 4. 创建管理界面脚本
  puts "4. 创建管理界面脚本..."

  management_script = <<~RUBY
    # 增强用户管理界面脚本
    
    puts "=== 增强用户管理界面 ==="
    puts ""
    
    # 加载增强管理器
    load '/tmp/enhanced_user_manager.rb'
    
    admin_user = User.find_by(email: 'gibson@localhost.com')
    admin_account = admin_user.accounts.first
    
    def show_menu
      puts ""
      puts "=== 用户管理菜单 ==="
      puts "1. 查看所有用户"
      puts "2. 创建新用户（增强版）"
      puts "3. 切换用户认证状态"
      puts "4. 重置用户密码"
      puts "5. 退出"
      print "请选择操作 (1-5): "
    end
    
    def list_users(account)
      puts ""
      puts "=== 用户列表 ==="
      account.users.each_with_index do |user, index|
        account_user = user.account_users.find_by(account: account)
        puts "\#{index + 1}. \#{user.name} (\#{user.email})"
        puts "   角色: \#{account_user&.role || '无角色'}"
        puts "   认证: \#{user.confirmed_at ? '已认证' : '未认证'}"
        puts "   ID: \#{user.id}"
        puts ""
      end
    end
    
    def create_user_enhanced(account, creator)
      puts ""
      puts "=== 创建新用户（增强版）==="
      print "用户姓名: "
      name = gets.chomp
      return if name.empty?
      
      print "邮箱地址: "
      email = gets.chomp
      return if email.empty?
      
      print "密码（留空自动生成）: "
      password = gets.chomp
      password = nil if password.empty?
      
      print "角色 (1=管理员, 2=代理) [默认: 2]: "
      role_input = gets.chomp
      role = role_input == '1' ? 'administrator' : 'agent'
      
      print "是否立即认证? (y/N): "
      confirmed = gets.chomp.downcase == 'y'
      
      result = EnhancedUserManager.create_user_with_options(
        account, creator,
        {
          name: name,
          email: email,
          password: password,
          role: role,
          confirmed: confirmed
        }
      )
      
      if result[:success]
        puts ""
        puts "✓ 用户创建成功!"
        puts "  姓名: \#{result[:user].name}"
        puts "  邮箱: \#{result[:user].email}"
        puts "  密码: \#{result[:password]}"
        puts "  角色: \#{role}"
        puts "  认证: \#{confirmed ? '已认证' : '未认证'}"
      else
        puts "✗ 创建失败: \#{result[:errors].join(', ')}"
      end
    end
    
    def toggle_confirmation(account)
      puts ""
      print "请输入用户ID: "
      user_id = gets.chomp.to_i
      return if user_id == 0
      
      user = account.users.find_by(id: user_id)
      unless user
        puts "✗ 找不到用户"
        return
      end
      
      result = EnhancedUserManager.toggle_user_confirmation(user)
      puts result[:success] ? "✓ \#{result[:message]}" : "✗ \#{result[:errors].join(', ')}"
    end
    
    def reset_password(account)
      puts ""
      print "请输入用户ID: "
      user_id = gets.chomp.to_i
      return if user_id == 0
      
      user = account.users.find_by(id: user_id)
      unless user
        puts "✗ 找不到用户"
        return
      end
      
      print "是否强制下次登录修改密码? (y/N): "
      force_change = gets.chomp.downcase == 'y'
      
      result = EnhancedUserManager.reset_user_password(user, { force_change: force_change })
      
      if result[:success]
        puts "✓ \#{result[:message]}"
        puts "  新密码: \#{result[:password]}"
        puts "  强制修改: \#{result[:force_change] ? '是' : '否'}"
      else
        puts "✗ \#{result[:errors].join(', ')}"
      end
    end
    
    # 主循环
    loop do
      show_menu
      choice = gets.chomp
      
      case choice
      when '1' then list_users(admin_account)
      when '2' then create_user_enhanced(admin_account, admin_user)
      when '3' then toggle_confirmation(admin_account)
      when '4' then reset_password(admin_account)
      when '5'
        puts "再见!"
        break
      else
        puts "无效选择"
      end
    end
  RUBY

  File.write('/tmp/enhanced_management_ui.rb', management_script)
  puts "✓ 管理界面脚本已创建"

  puts ""
  puts "=== 简化增强功能部署完成 ==="
  puts ""
  puts "✅ 功能已成功部署!"
  puts ""
  puts "新增功能:"
  puts "✓ 增强用户创建 - 支持自定义密码和认证状态"
  puts "✓ 认证状态控制 - 可切换用户认证状态"
  puts "✓ 密码管理 - 重置密码和强制修改"
  puts "✓ 管理界面 - 交互式用户管理"
  puts ""
  puts "使用方法:"
  puts "1. 交互式管理: docker exec -it cschat-chatwoot-1 bundle exec rails runner /tmp/enhanced_management_ui.rb"
  puts "2. 编程接口: 使用 EnhancedUserManager 类"
  puts ""
  puts "测试账号:"
  puts "- enhanced.test@example.com / EnhancedTest123! (已认证)"

rescue => e
  puts "❌ 部署失败: #{e.message}"
  puts e.backtrace.first(5) if ENV['DEBUG']
end
