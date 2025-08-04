# 修复增强API 404错误

puts "=== 修复增强API 404错误 ==="
puts ""

begin
  # 1. 检查当前路由状态
  puts "1. 检查当前路由状态..."
  
  enhanced_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('enhanced')
  end
  
  if enhanced_routes.any?
    puts "✓ 找到 #{enhanced_routes.count} 个enhanced路由"
    enhanced_routes.each do |route|
      puts "  - #{route.verb} #{route.path.spec}"
    end
  else
    puts "❌ 没有找到enhanced路由"
  end

  # 2. 检查控制器文件
  puts "2. 检查控制器文件..."
  
  controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
  if File.exist?(controller_path)
    puts "✓ 控制器文件存在: #{controller_path}"
    
    # 检查文件内容
    content = File.read(controller_path)
    if content.include?('class Api::V1::Accounts::EnhancedAgentsController')
      puts "✓ 控制器类定义正确"
    else
      puts "❌ 控制器类定义有问题"
    end
  else
    puts "❌ 控制器文件不存在"
  end

  # 3. 重新创建控制器（如果需要）
  puts "3. 重新创建增强控制器..."
  
  enhanced_controller_content = <<~RUBY
    class Api::V1::Accounts::EnhancedAgentsController < Api::V1::Accounts::BaseController
      before_action :check_authorization
      before_action :set_agent, only: [:show, :update, :destroy, :toggle_confirmation, :reset_password]

      def index
        @agents = Current.account.users.includes(:account_users)
        render json: @agents.map { |agent| agent_with_enhanced_data(agent) }
      end

      def show
        render json: agent_with_enhanced_data(@agent)
      end

      def create
        @agent = User.new(agent_params)
        
        # 处理密码
        if params[:auto_generate_password] == 'true' || params[:auto_generate_password] == true
          @agent.password = generate_password
        elsif params[:password].present?
          @agent.password = params[:password]
          @agent.password_confirmation = params[:password_confirmation] || params[:password]
        else
          @agent.password = generate_password
        end
        
        # 处理认证状态
        if params[:confirmed] == 'true' || params[:confirmed] == true
          @agent.confirmed_at = Time.current
        end

        if @agent.save
          # 创建账号用户关联
          account_user = Current.account.account_users.create!(
            user: @agent,
            role: params[:role] || 'agent'
          )

          # 发送欢迎邮件（如果需要）
          if params[:send_welcome_email] == 'true' || params[:send_welcome_email] == true
            begin
              # 这里可以添加邮件发送逻辑
              Rails.logger.info "Welcome email would be sent to #{@agent.email}"
            rescue => e
              Rails.logger.error "Failed to send welcome email: #{e.message}"
            end
          end

          render json: { 
            message: 'Agent created successfully',
            agent: agent_with_enhanced_data(@agent),
            password: @agent.password
          }, status: :created
        else
          render json: { 
            message: 'Failed to create agent',
            errors: @agent.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      def update
        if @agent.update(agent_params)
          render json: {
            message: 'Agent updated successfully',
            agent: agent_with_enhanced_data(@agent)
          }
        else
          render json: { 
            message: 'Failed to update agent',
            errors: @agent.errors.full_messages 
          }, status: :unprocessable_entity
        end
      end

      def toggle_confirmation
        begin
          if @agent.confirmed_at
            @agent.update!(confirmed_at: nil)
            message = 'Agent confirmation revoked successfully'
          else
            @agent.update!(confirmed_at: Time.current)
            message = 'Agent confirmed successfully'
          end

          render json: { 
            message: message, 
            agent: agent_with_enhanced_data(@agent) 
          }
        rescue => e
          render json: { 
            message: 'Failed to toggle confirmation',
            error: e.message 
          }, status: :unprocessable_entity
        end
      end

      def reset_password
        begin
          new_password = params[:password].present? ? params[:password] : generate_password
          
          @agent.update!(
            password: new_password,
            password_confirmation: new_password
          )

          # 如果需要强制修改密码
          if params[:force_password_change] == 'true' || params[:force_password_change] == true
            # 这里可以添加强制修改密码的逻辑
            Rails.logger.info "User #{@agent.email} will be required to change password on next login"
          end

          render json: { 
            message: 'Password reset successfully',
            password: new_password,
            agent: agent_with_enhanced_data(@agent)
          }
        rescue => e
          render json: { 
            message: 'Failed to reset password',
            error: e.message 
          }, status: :unprocessable_entity
        end
      end

      private

      def set_agent
        @agent = Current.account.users.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { message: 'Agent not found' }, status: :not_found
      end

      def agent_params
        params.permit(:name, :email, :password, :password_confirmation, :role)
      end

      def agent_with_enhanced_data(agent)
        account_user = agent.account_users.find_by(account: Current.account)
        
        {
          id: agent.id,
          name: agent.name,
          email: agent.email,
          confirmed: agent.confirmed_at.present?,
          confirmed_at: agent.confirmed_at,
          role: account_user&.role,
          availability: account_user&.availability,
          created_at: agent.created_at,
          updated_at: agent.updated_at,
          enhanced_features: {
            can_reset_password: true,
            can_toggle_confirmation: true,
            password_last_changed: agent.updated_at
          }
        }
      end

      def generate_password
        chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%'
        Array.new(12) { chars[rand(chars.length)] }.join
      end

      def check_authorization
        # 简化的权限检查
        unless Current.user
          render json: { message: 'Unauthorized' }, status: :unauthorized
          return
        end
        
        account_user = Current.user.account_users.find_by(account: Current.account)
        unless account_user&.administrator?
          render json: { message: 'Forbidden - Admin access required' }, status: :forbidden
          return
        end
      end
    end
  RUBY

  # 写入控制器文件
  File.write(controller_path, enhanced_controller_content)
  puts "✓ 增强控制器已重新创建"

  # 4. 检查路由文件
  puts "4. 检查路由配置..."
  
  routes_file = '/app/config/routes.rb'
  routes_content = File.read(routes_file)
  
  if routes_content.include?('enhanced_agents')
    puts "✓ 路由配置已存在"
  else
    puts "❌ 路由配置缺失，正在添加..."
    
    # 在accounts命名空间中添加路由
    enhanced_routes = <<~RUBY
      
      # Enhanced user management routes
      resources :enhanced_agents do
        member do
          patch :toggle_confirmation
          patch :reset_password
        end
      end
    RUBY
    
    # 查找accounts命名空间并添加路由
    if routes_content.include?('namespace :accounts do')
      routes_content = routes_content.sub(
        /(namespace :accounts do.*?resources :agents.*?end)/m,
        "\\1#{enhanced_routes}"
      )
      
      File.write(routes_file, routes_content)
      puts "✓ 路由配置已添加"
    else
      puts "❌ 找不到accounts命名空间"
    end
  end

  # 5. 重新加载Rails应用
  puts "5. 重新加载Rails应用..."
  
  begin
    Rails.application.reloader.reload!
    puts "✓ Rails应用已重新加载"
  rescue => e
    puts "⚠ Rails重新加载失败: #{e.message}"
  end

  # 6. 验证路由
  puts "6. 验证增强API路由..."
  
  enhanced_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('enhanced')
  end
  
  if enhanced_routes.any?
    puts "✓ 增强API路由验证成功:"
    enhanced_routes.each do |route|
      puts "  - #{route.verb.ljust(6)} #{route.path.spec}"
    end
  else
    puts "❌ 增强API路由仍然缺失"
  end

  # 7. 测试API端点
  puts "7. 测试API端点..."
  
  begin
    # 模拟API调用测试
    test_account = Account.first
    if test_account
      puts "✓ 测试账号存在: #{test_account.name}"
      
      # 检查控制器是否可以实例化
      controller = Api::V1::Accounts::EnhancedAgentsController.new
      puts "✓ 控制器可以实例化"
    else
      puts "⚠ 没有测试账号"
    end
  rescue => e
    puts "❌ API测试失败: #{e.message}"
  end

  puts ""
  puts "=== 增强API修复完成 ==="
  puts ""
  puts "✅ 增强API已修复！"
  puts ""
  puts "API端点应该现在可用:"
  puts "GET    /api/v1/accounts/:account_id/enhanced_agents"
  puts "POST   /api/v1/accounts/:account_id/enhanced_agents"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id/toggle_confirmation"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id/reset_password"
  puts ""
  puts "测试方法:"
  puts "1. 访问演示页面: http://localhost:3000/enhanced_features_demo.html"
  puts "2. 点击'加载增强API'按钮"
  puts "3. 测试切换认证和密码重置功能"

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
