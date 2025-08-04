# 创建增强的用户管理API端点

puts "=== 创建增强的用户管理API端点 ==="
puts ""

begin
  # 1. 创建增强的代理控制器
  puts "1. 创建增强的代理控制器..."
  
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
  RUBY

  # 写入控制器文件
  controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
  File.write(controller_path, enhanced_controller_content)
  puts "✓ 增强代理控制器已创建: #{controller_path}"

  # 2. 添加路由
  puts "2. 添加增强API路由..."
  
  routes_file = '/app/config/routes.rb'
  routes_content = File.read(routes_file)
  
  # 检查是否已经添加过路由
  unless routes_content.include?('enhanced_agents')
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
        /(namespace :accounts do.*?)(end)/m,
        "\\1#{enhanced_routes}    \\2"
      )
      
      File.write(routes_file, routes_content)
      puts "✓ 增强API路由已添加"
    else
      puts "❌ 找不到accounts命名空间"
    end
  else
    puts "✓ 增强API路由已存在"
  end

  # 3. 创建前端JavaScript API客户端
  puts "3. 创建前端JavaScript API客户端..."
  
  api_client_content = <<~JS
    // Enhanced Agents API Client
    class EnhancedAgentsAPI {
      constructor() {
        this.baseURL = '/api/v1/accounts/' + this.getAccountId() + '/enhanced_agents';
        this.headers = {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        };
      }

      getAccountId() {
        // 从当前URL或全局变量获取账号ID
        const match = window.location.pathname.match(/accounts\\/(\\d+)/);
        return match ? match[1] : '1';
      }

      getCSRFToken() {
        const token = document.querySelector('meta[name="csrf-token"]');
        return token ? token.getAttribute('content') : '';
      }

      async request(url, options = {}) {
        const response = await fetch(url, {
          headers: this.headers,
          ...options
        });

        if (!response.ok) {
          throw new Error(`HTTP error! status: ${response.status}`);
        }

        return response.json();
      }

      async getAgents() {
        return this.request(this.baseURL);
      }

      async getAgent(id) {
        return this.request(`${this.baseURL}/${id}`);
      }

      async createAgent(agentData) {
        return this.request(this.baseURL, {
          method: 'POST',
          body: JSON.stringify(agentData)
        });
      }

      async updateAgent(id, agentData) {
        return this.request(`${this.baseURL}/${id}`, {
          method: 'PATCH',
          body: JSON.stringify(agentData)
        });
      }

      async toggleConfirmation(id) {
        return this.request(`${this.baseURL}/${id}/toggle_confirmation`, {
          method: 'PATCH'
        });
      }

      async resetPassword(id, passwordData = {}) {
        return this.request(`${this.baseURL}/${id}/reset_password`, {
          method: 'PATCH',
          body: JSON.stringify(passwordData)
        });
      }
    }

    // 全局实例
    window.enhancedAgentsAPI = new EnhancedAgentsAPI();

    // 增强功能集成
    function integrateEnhancedFeatures() {
      console.log('🚀 集成增强用户管理功能...');

      // 监听页面变化
      const observer = new MutationObserver(() => {
        enhanceAgentForms();
        enhanceAgentList();
      });

      observer.observe(document.body, {
        childList: true,
        subtree: true
      });

      // 初始增强
      enhanceAgentForms();
      enhanceAgentList();
    }

    function enhanceAgentForms() {
      // 增强添加代理表单
      const addForms = document.querySelectorAll('form:not(.enhanced)');
      addForms.forEach(form => {
        if (form.querySelector('input[type="email"]')) {
          enhanceAddAgentForm(form);
        }
      });
    }

    function enhanceAddAgentForm(form) {
      form.classList.add('enhanced');
      
      // 添加增强字段
      const emailInput = form.querySelector('input[type="email"]');
      if (!emailInput) return;

      const enhancedHTML = `
        <div class="enhanced-fields" style="margin: 16px 0; padding: 16px; background: #f8f9fa; border-radius: 8px; border: 1px solid #e9ecef;">
          <h4 style="margin: 0 0 12px 0; color: #495057; font-size: 14px;">🚀 增强选项</h4>
          
          <label style="display: flex; align-items: center; margin: 8px 0;">
            <input type="checkbox" id="enhanced-auto-password" checked style="margin-right: 8px;">
            <span>自动生成密码</span>
          </label>
          
          <div id="enhanced-manual-password" style="display: none; margin: 8px 0;">
            <input type="password" placeholder="自定义密码" style="width: 100%; margin-bottom: 8px; padding: 8px;">
            <input type="password" placeholder="确认密码" style="width: 100%; padding: 8px;">
          </div>
          
          <label style="display: flex; align-items: center; margin: 8px 0;">
            <input type="checkbox" id="enhanced-confirm-account" style="margin-right: 8px;">
            <span>立即认证账号</span>
          </label>
          
          <label style="display: flex; align-items: center; margin: 8px 0;">
            <input type="checkbox" id="enhanced-welcome-email" style="margin-right: 8px;">
            <span>发送欢迎邮件</span>
          </label>
        </div>
      `;

      emailInput.closest('div').insertAdjacentHTML('afterend', enhancedHTML);

      // 添加事件监听
      const autoPasswordCheckbox = form.querySelector('#enhanced-auto-password');
      const manualPasswordDiv = form.querySelector('#enhanced-manual-password');

      autoPasswordCheckbox.addEventListener('change', function() {
        manualPasswordDiv.style.display = this.checked ? 'none' : 'block';
      });

      // 拦截表单提交
      form.addEventListener('submit', async function(e) {
        e.preventDefault();
        
        const formData = new FormData(form);
        const agentData = {
          name: formData.get('name'),
          email: formData.get('email'),
          role: formData.get('role') || 'agent',
          auto_generate_password: autoPasswordCheckbox.checked,
          confirmed: form.querySelector('#enhanced-confirm-account').checked,
          send_welcome_email: form.querySelector('#enhanced-welcome-email').checked
        };

        if (!autoPasswordCheckbox.checked) {
          const passwordInputs = manualPasswordDiv.querySelectorAll('input[type="password"]');
          agentData.password = passwordInputs[0].value;
          agentData.password_confirmation = passwordInputs[1].value;
        }

        try {
          const result = await window.enhancedAgentsAPI.createAgent(agentData);
          alert('✅ 代理创建成功！');
          location.reload();
        } catch (error) {
          alert('❌ 创建失败: ' + error.message);
        }
      });
    }

    function enhanceAgentList() {
      // 增强代理列表
      const agentRows = document.querySelectorAll('tr:not(.enhanced)');
      agentRows.forEach(row => {
        if (row.querySelector('td')) {
          enhanceAgentRow(row);
        }
      });
    }

    function enhanceAgentRow(row) {
      row.classList.add('enhanced');
      
      // 添加增强按钮
      const lastCell = row.querySelector('td:last-child');
      if (lastCell) {
        const enhancedButtons = `
          <button onclick="toggleAgentConfirmation(this)" style="margin: 2px; padding: 4px 8px; background: #28a745; color: white; border: none; border-radius: 4px; font-size: 11px;">切换认证</button>
          <button onclick="resetAgentPassword(this)" style="margin: 2px; padding: 4px 8px; background: #dc3545; color: white; border: none; border-radius: 4px; font-size: 11px;">重置密码</button>
        `;
        lastCell.insertAdjacentHTML('beforeend', enhancedButtons);
      }
    }

    // 全局函数
    window.toggleAgentConfirmation = async function(button) {
      const row = button.closest('tr');
      const agentId = getAgentIdFromRow(row);
      
      try {
        const result = await window.enhancedAgentsAPI.toggleConfirmation(agentId);
        alert('✅ ' + result.message);
        location.reload();
      } catch (error) {
        alert('❌ 操作失败: ' + error.message);
      }
    };

    window.resetAgentPassword = async function(button) {
      const row = button.closest('tr');
      const agentId = getAgentIdFromRow(row);
      
      const newPassword = prompt('输入新密码（留空自动生成）:');
      const forceChange = confirm('是否要求用户下次登录时修改密码？');
      
      try {
        const result = await window.enhancedAgentsAPI.resetPassword(agentId, {
          password: newPassword,
          force_password_change: forceChange
        });
        
        alert(`✅ 密码重置成功！\\n新密码: ${result.password}`);
      } catch (error) {
        alert('❌ 重置失败: ' + error.message);
      }
    };

    function getAgentIdFromRow(row) {
      // 从行中提取代理ID（需要根据实际HTML结构调整）
      const editButton = row.querySelector('a[href*="/edit"], button[data-id]');
      if (editButton) {
        const href = editButton.getAttribute('href');
        const match = href ? href.match(/\\/(\\d+)/) : null;
        return match ? match[1] : '1';
      }
      return '1';
    }

    // 自动启动
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', integrateEnhancedFeatures);
    } else {
      integrateEnhancedFeatures();
    }

    console.log('✅ 增强用户管理API客户端已加载');
  JS

  # 写入API客户端文件
  api_client_path = '/app/public/enhanced_agents_api.js'
  File.write(api_client_path, api_client_content)
  puts "✓ 前端API客户端已创建: #{api_client_path}"

  puts ""
  puts "=== 增强API创建完成 ==="
  puts ""
  puts "✅ 增强用户管理API已创建！"
  puts ""
  puts "新增功能："
  puts "✓ 增强代理控制器 - 完整的CRUD和特殊操作"
  puts "✓ API路由 - RESTful接口"
  puts "✓ 前端API客户端 - JavaScript集成"
  puts ""
  puts "API端点："
  puts "GET    /api/v1/accounts/:account_id/enhanced_agents"
  puts "POST   /api/v1/accounts/:account_id/enhanced_agents"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id/toggle_confirmation"
  puts "PATCH  /api/v1/accounts/:account_id/enhanced_agents/:id/reset_password"
  puts ""
  puts "前端集成："
  puts "访问: http://localhost:3000/enhanced_agents_api.js"
  puts ""
  puts "建议操作："
  puts "1. 重启Rails服务以加载新的控制器和路由"
  puts "2. 在浏览器中加载API客户端脚本"
  puts "3. 测试增强功能"

rescue => e
  puts "❌ 创建增强API失败: #{e.message}"
  puts e.backtrace.first(5)
end
