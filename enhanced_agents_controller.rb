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
    @agent.password = generate_password if params[:auto_generate_password]
    @agent.confirmed_at = Time.current if params[:confirmed]

    if @agent.save
      # 创建账号用户关联
      account_user = Current.account.account_users.create!(
        user: @agent,
        role: params[:role] || 'agent'
      )

      # 发送欢迎邮件
      if params[:send_welcome_email]
        AgentNotifications::AccountNotificationMailer
          .with(account: Current.account)
          .agent_added(@agent, params[:password] || @agent.password)
          .deliver_later
      end

      render json: agent_with_enhanced_data(@agent), status: :created
    else
      render json: { errors: @agent.errors }, status: :unprocessable_entity
    end
  end

  def update
    if @agent.update(agent_params)
      render json: agent_with_enhanced_data(@agent)
    else
      render json: { errors: @agent.errors }, status: :unprocessable_entity
    end
  end

  def toggle_confirmation
    if @agent.confirmed_at
      @agent.update!(confirmed_at: nil)
      message = 'Agent confirmation revoked'
    else
      @agent.update!(confirmed_at: Time.current)
      message = 'Agent confirmed successfully'
    end

    render json: { 
      message: message, 
      agent: agent_with_enhanced_data(@agent) 
    }
  end

  def reset_password
    new_password = params[:password] || generate_password
    
    @agent.update!(
      password: new_password,
      password_confirmation: new_password
    )

    # 如果需要强制修改密码
    if params[:force_password_change]
      @agent.update!(password_changed_at: 1.day.ago)
    end

    render json: { 
      message: 'Password reset successfully',
      password: new_password,
      agent: agent_with_enhanced_data(@agent)
    }
  end

  private

  def set_agent
    @agent = Current.account.users.find(params[:id])
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
    authorize(User)
  end
end
