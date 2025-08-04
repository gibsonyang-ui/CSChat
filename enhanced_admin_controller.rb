# 增强的管理员控制器 - 扩展用户管理功能
# 这个文件应该放在 app/controllers/api/v1/accounts/enhanced_admin_controller.rb

class Api::V1::Accounts::EnhancedAdminController < Api::V1::Accounts::BaseController
  before_action :check_admin_authorization
  before_action :set_user, only: [:show_user, :update_user, :delete_user, :toggle_confirmation, :reset_password]

  # GET /api/v1/accounts/{account_id}/enhanced_admin/users
  def list_users
    @users = Current.account.users.includes(:account_users)
    
    users_data = @users.map do |user|
      account_user = user.account_users.find_by(account: Current.account)
      {
        id: user.id,
        name: user.name,
        email: user.email,
        role: account_user&.role,
        confirmed: user.confirmed_at.present?,
        confirmed_at: user.confirmed_at,
        created_at: user.created_at,
        last_sign_in_at: user.last_sign_in_at,
        sign_in_count: user.sign_in_count,
        availability: account_user&.availability,
        custom_attributes: user.custom_attributes || {}
      }
    end
    
    render json: { users: users_data }
  end

  # POST /api/v1/accounts/{account_id}/enhanced_admin/users
  def create_user
    @user = User.new(user_creation_params)
    
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
        message: 'User created successfully',
        user: user_response_data(@user),
        temporary_password: params[:password] # 仅在创建时返回
      }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # GET /api/v1/accounts/{account_id}/enhanced_admin/users/{id}
  def show_user
    render json: { user: user_response_data(@user) }
  end

  # PATCH /api/v1/accounts/{account_id}/enhanced_admin/users/{id}
  def update_user
    if @user.update(user_update_params)
      
      # 更新角色（如果提供）
      if params[:role].present?
        account_user = @user.account_users.find_by(account: Current.account)
        account_user&.update(role: params[:role])
      end
      
      render json: {
        message: 'User updated successfully',
        user: user_response_data(@user)
      }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/accounts/{account_id}/enhanced_admin/users/{id}
  def delete_user
    # 防止删除自己
    if @user == Current.user
      render json: { error: 'Cannot delete your own account' }, status: :forbidden
      return
    end
    
    # 删除账号关联
    account_user = @user.account_users.find_by(account: Current.account)
    account_user&.destroy
    
    # 如果用户没有其他账号关联，删除用户
    if @user.account_users.empty?
      @user.destroy
      message = 'User completely deleted'
    else
      message = 'User removed from current account'
    end
    
    render json: { message: message }
  end

  # POST /api/v1/accounts/{account_id}/enhanced_admin/users/{id}/toggle_confirmation
  def toggle_confirmation
    if @user.confirmed_at.present?
      @user.update!(confirmed_at: nil)
      message = 'User confirmation revoked'
    else
      @user.update!(confirmed_at: Time.current)
      message = 'User confirmed'
    end
    
    render json: {
      message: message,
      user: user_response_data(@user)
    }
  end

  # POST /api/v1/accounts/{account_id}/enhanced_admin/users/{id}/reset_password
  def reset_password
    new_password = params[:password] || generate_secure_password
    
    if @user.update(password: new_password, password_confirmation: new_password)
      
      # 设置强制修改密码标志（如果需要）
      if params[:force_password_change] == true
        custom_attrs = @user.custom_attributes || {}
        custom_attrs['force_password_change'] = true
        @user.update!(custom_attributes: custom_attrs)
      end
      
      render json: {
        message: 'Password reset successfully',
        temporary_password: new_password,
        force_change: params[:force_password_change] == true
      }
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # POST /api/v1/accounts/{account_id}/enhanced_admin/users/bulk_action
  def bulk_action
    user_ids = params[:user_ids] || []
    action = params[:action]
    
    users = Current.account.users.where(id: user_ids)
    results = []
    
    case action
    when 'confirm'
      users.each do |user|
        user.update!(confirmed_at: Time.current)
        results << { id: user.id, status: 'confirmed' }
      end
    when 'revoke_confirmation'
      users.each do |user|
        user.update!(confirmed_at: nil)
        results << { id: user.id, status: 'confirmation_revoked' }
      end
    when 'set_role'
      role = params[:role]
      users.each do |user|
        account_user = user.account_users.find_by(account: Current.account)
        if account_user
          account_user.update!(role: role)
          results << { id: user.id, status: 'role_updated', role: role }
        end
      end
    else
      render json: { error: 'Invalid action' }, status: :bad_request
      return
    end
    
    render json: { message: 'Bulk action completed', results: results }
  end

  # GET /api/v1/accounts/{account_id}/enhanced_admin/user_stats
  def user_stats
    total_users = Current.account.users.count
    confirmed_users = Current.account.users.where.not(confirmed_at: nil).count
    administrators = Current.account.account_users.where(role: 'administrator').count
    agents = Current.account.account_users.where(role: 'agent').count
    
    render json: {
      total_users: total_users,
      confirmed_users: confirmed_users,
      unconfirmed_users: total_users - confirmed_users,
      administrators: administrators,
      agents: agents,
      recent_signins: Current.account.users.where('last_sign_in_at > ?', 7.days.ago).count
    }
  end

  private

  def check_admin_authorization
    account_user = Current.user.account_users.find_by(account: Current.account)
    unless account_user&.administrator?
      render json: { error: 'Administrator access required' }, status: :forbidden
    end
  end

  def set_user
    @user = Current.account.users.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'User not found' }, status: :not_found
  end

  def user_creation_params
    params.permit(:name, :email, :password, :password_confirmation)
  end

  def user_update_params
    params.permit(:name, :email, :display_name, :message_signature, custom_attributes: {})
  end

  def user_response_data(user)
    account_user = user.account_users.find_by(account: Current.account)
    {
      id: user.id,
      name: user.name,
      email: user.email,
      display_name: user.display_name,
      role: account_user&.role,
      confirmed: user.confirmed_at.present?,
      confirmed_at: user.confirmed_at,
      created_at: user.created_at,
      updated_at: user.updated_at,
      last_sign_in_at: user.last_sign_in_at,
      sign_in_count: user.sign_in_count,
      availability: account_user&.availability,
      custom_attributes: user.custom_attributes || {},
      message_signature: user.message_signature
    }
  end

  def generate_secure_password
    # 生成安全的随机密码
    chars = [*'A'..'Z', *'a'..'z', *'0'..'9', '!', '@', '#', '$', '%', '&', '*']
    Array.new(12) { chars.sample }.join
  end
end
