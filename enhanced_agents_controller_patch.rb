# 增强的Agents控制器补丁 - 添加密码和认证管理功能
# 这个文件包含对现有agents控制器的增强

puts "=== 应用Agents控制器增强补丁 ==="

# 检查是否存在agents控制器
controller_path = Rails.root.join('app/controllers/api/v1/accounts/agents_controller.rb')

unless File.exist?(controller_path)
  puts "❌ 找不到agents控制器文件"
  exit 1
end

# 读取现有控制器内容
controller_content = File.read(controller_path)

# 检查是否已经应用过补丁
if controller_content.include?('# Enhanced user management patch')
  puts "✓ 增强补丁已经应用过"
  exit 0
end

puts "正在应用增强补丁..."

# 创建增强的create方法
enhanced_create_method = <<~RUBY
  # Enhanced user management patch
  def create
    ActiveRecord::Base.transaction do
      @user = User.new(user_params)
      
      # 设置认证状态
      @user.confirmed_at = Time.current if params[:confirmed] == true
      
      if @user.save
        # 创建账号关联
        account_user = AccountUser.create!(
          user: @user,
          account: Current.account,
          role: params[:role] || 'agent',
          inviter: Current.user
        )
        
        # 发送欢迎邮件（如果需要）
        if params[:send_welcome_email] == true && @user.confirmed_at.present?
          # UserMailer.welcome_email(@user).deliver_later
        end
        
        render json: {
          message: 'Agent created successfully',
          user: user_response_data(@user)
        }, status: :created
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # 切换用户认证状态
  def toggle_confirmation
    @agent = Current.account.users.find(params[:id])
    
    if @agent.confirmed_at.present?
      @agent.update!(confirmed_at: nil)
      message = 'User verification revoked'
    else
      @agent.update!(confirmed_at: Time.current)
      message = 'User verified successfully'
    end
    
    render json: {
      message: message,
      user: user_response_data(@agent)
    }
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # 重置用户密码
  def reset_password
    @agent = Current.account.users.find(params[:id])
    
    new_password = params[:password] || generate_secure_password
    
    if @agent.update(password: new_password, password_confirmation: new_password)
      # 设置强制修改密码标志（如果需要）
      if params[:force_password_change] == true
        custom_attrs = @agent.custom_attributes || {}
        custom_attrs['force_password_change'] = true
        @agent.update!(custom_attributes: custom_attrs)
      end
      
      render json: {
        message: 'Password reset successfully',
        temporary_password: new_password,
        force_change: params[:force_password_change] == true
      }
    else
      render json: { errors: @agent.errors.full_messages }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def user_response_data(user)
    account_user = user.account_users.find_by(account: Current.account)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      role: account_user&.role,
      confirmed: user.confirmed_at.present?,
      confirmed_at: user.confirmed_at,
      created_at: user.created_at,
      updated_at: user.updated_at,
      availability: account_user&.availability,
      custom_attributes: user.custom_attributes || {}
    }
  end

  def generate_secure_password
    # 生成安全的随机密码
    chars = [*'A'..'Z', *'a'..'z', *'0'..'9', '!', '@', '#', '$', '%', '&', '*']
    Array.new(12) { chars.sample }.join
  end

  def user_params
    params.permit(:name, :email, :password, :password_confirmation, :role, :confirmed, :send_welcome_email)
  end
RUBY

# 在控制器类的最后添加新方法
if controller_content.include?('private')
  # 在private之前插入新方法
  controller_content = controller_content.sub(/(\s+private)/, "#{enhanced_create_method}\n\\1")
else
  # 在类结束之前插入新方法
  controller_content = controller_content.sub(/(\s+end\s*$)/, "#{enhanced_create_method}\n\\1")
end

# 写回文件
File.write(controller_path, controller_content)

puts "✓ Agents控制器增强补丁应用成功"

# 添加路由
routes_path = Rails.root.join('config/routes.rb')
routes_content = File.read(routes_path)

unless routes_content.include?('toggle_confirmation')
  puts "正在添加增强路由..."
  
  # 查找agents资源定义
  if routes_content.include?('resources :agents')
    # 在agents资源中添加新路由
    enhanced_routes = <<~RUBY
            member do
              post :toggle_confirmation
              post :reset_password
            end
    RUBY
    
    routes_content = routes_content.sub(
      /(resources :agents[^}]*?)(\s+end)/m,
      "\\1#{enhanced_routes}\\2"
    )
    
    File.write(routes_path, routes_content)
    puts "✓ 增强路由添加成功"
  else
    puts "⚠ 无法找到agents资源定义，请手动添加路由"
  end
end

puts ""
puts "=== 增强补丁应用完成 ==="
puts ""
puts "新增功能:"
puts "✓ 创建用户时支持设置密码和认证状态"
puts "✓ 切换用户认证状态 (POST /api/v1/accounts/:account_id/agents/:id/toggle_confirmation)"
puts "✓ 重置用户密码 (POST /api/v1/accounts/:account_id/agents/:id/reset_password)"
puts ""
puts "请重启Rails服务器以使更改生效"
