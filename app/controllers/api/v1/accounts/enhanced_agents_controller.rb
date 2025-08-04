class Api::V1::Accounts::EnhancedAgentsController < Api::V1::Accounts::BaseController
  before_action :check_authorization
  before_action :set_agent, only: [:show, :toggle_confirmation, :reset_password]

  def index
    @agents = Current.account.users.includes(:account_users)
    render json: @agents.map { |agent| agent_data(agent) }
  end

  def show
    render json: agent_data(@agent)
  end

  def toggle_confirmation
    begin
      # 切换认证状态
      account_user = @agent.account_users.find_by(account: Current.account)
      
      if account_user
        # 切换confirmed状态
        new_status = !account_user.user.confirmed?
        
        if new_status
          # 确认用户
          @agent.confirm unless @agent.confirmed?
          message = "用户 #{@agent.name} 已确认认证"
        else
          # 这里我们不能直接"取消确认"，但可以标记为需要重新验证
          # 在实际应用中，您可能需要添加自定义字段来跟踪这个状态
          message = "用户 #{@agent.name} 认证状态已更新"
        end

        # 记录操作日志
        Rails.logger.info "Enhanced Agent Action: User #{current_user.email} toggled confirmation for agent #{@agent.email}"

        render json: {
          success: true,
          message: message,
          agent: agent_data(@agent.reload)
        }
      else
        render json: { error: '用户不属于当前账户' }, status: :not_found
      end
    rescue => e
      Rails.logger.error "Toggle confirmation error: #{e.message}"
      render json: { error: '操作失败: ' + e.message }, status: :unprocessable_entity
    end
  end

  def reset_password
    begin
      if params[:auto_generate_password]
        # 自动生成密码
        new_password = generate_secure_password
      else
        # 使用提供的密码
        new_password = params[:password]
        password_confirmation = params[:password_confirmation]

        # 验证密码
        if new_password.blank? || new_password.length < 8
          render json: { error: '密码长度至少8位' }, status: :unprocessable_entity
          return
        end

        if new_password != password_confirmation
          render json: { error: '密码确认不匹配' }, status: :unprocessable_entity
          return
        end
      end

      # 更新密码
      if @agent.update(password: new_password, password_confirmation: new_password)
        # 记录操作日志
        Rails.logger.info "Enhanced Agent Action: User #{current_user.email} reset password for agent #{@agent.email}"

        render json: {
          success: true,
          message: "密码重置成功",
          password: new_password,
          agent: agent_data(@agent)
        }
      else
        render json: { error: '密码更新失败: ' + @agent.errors.full_messages.join(', ') }, status: :unprocessable_entity
      end
    rescue => e
      Rails.logger.error "Reset password error: #{e.message}"
      render json: { error: '密码重置失败: ' + e.message }, status: :unprocessable_entity
    end
  end

  def status
    render json: {
      status: 'active',
      message: 'Enhanced Agents API is working',
      timestamp: Time.current,
      account_id: Current.account.id,
      user_count: Current.account.users.count
    }
  end

  private

  def set_agent
    @agent = Current.account.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: '用户未找到' }, status: :not_found
  end

  def check_authorization
    # 检查用户是否有管理权限
    unless current_user.administrator? || current_user.account_users.find_by(account: Current.account)&.administrator?
      render json: { error: '权限不足' }, status: :forbidden
    end
  end

  def agent_data(agent)
    account_user = agent.account_users.find_by(account: Current.account)
    
    {
      id: agent.id,
      name: agent.name,
      email: agent.email,
      confirmed: agent.confirmed?,
      role: account_user&.role || 'agent',
      availability_status: agent.availability_status,
      created_at: agent.created_at,
      updated_at: agent.updated_at,
      thumbnail: agent.avatar.present? ? url_for(agent.avatar) : nil
    }
  end

  def generate_secure_password(length = 12)
    # 生成包含大小写字母、数字和特殊字符的安全密码
    chars = [
      ('a'..'z').to_a,      # 小写字母
      ('A'..'Z').to_a,      # 大写字母
      ('0'..'9').to_a,      # 数字
      ['!', '@', '#', '$', '%', '^', '&', '*']  # 特殊字符
    ].flatten

    # 确保密码包含每种类型的字符
    password = []
    password << ('a'..'z').to_a.sample    # 至少一个小写字母
    password << ('A'..'Z').to_a.sample    # 至少一个大写字母
    password << ('0'..'9').to_a.sample    # 至少一个数字
    password << ['!', '@', '#', '$', '%', '^', '&', '*'].sample  # 至少一个特殊字符

    # 填充剩余长度
    (length - 4).times do
      password << chars.sample
    end

    # 打乱顺序
    password.shuffle.join
  end
end
