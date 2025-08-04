# 简化的热更新系统

puts "=== 简化热更新系统 ==="
puts ""

begin
  # 1. 创建热更新管理器类
  puts "1. 创建热更新管理器..."
  
  # 定义热更新管理器
  class HotReloadManager
    def self.reload_controllers
      puts "  重新加载控制器..."
      
      # 重新加载增强控制器
      enhanced_controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
      if File.exist?(enhanced_controller_path)
        load enhanced_controller_path
        puts "    ✓ 增强控制器已重新加载"
      end
      
      # 重新加载路由
      Rails.application.reload_routes!
      puts "    ✓ 路由已重新加载"
    end
    
    def self.clear_cache
      puts "  清除缓存..."
      
      # 清除Rails缓存
      Rails.cache.clear if Rails.cache.respond_to?(:clear)
      
      # 清除类缓存
      ActiveSupport::Dependencies.clear
      
      puts "    ✓ 缓存已清除"
    end
    
    def self.reload_models
      puts "  重新加载模型..."
      
      models = ['user.rb', 'account.rb', 'account_user.rb']
      models.each do |model|
        model_path = "/app/app/models/#{model}"
        if File.exist?(model_path)
          load model_path
          puts "    ✓ #{model} 已重新加载"
        end
      end
    end
    
    def self.quick_reload
      puts "执行快速热更新..."
      
      clear_cache
      reload_controllers
      
      puts "✓ 快速热更新完成"
    end
    
    def self.full_reload
      puts "执行完整热更新..."
      
      clear_cache
      reload_models
      reload_controllers
      
      puts "✓ 完整热更新完成"
    end
  end
  
  puts "✓ 热更新管理器已创建"

  # 2. 创建简化的热更新控制器
  puts "2. 创建热更新控制器..."
  
  hot_reload_controller_content = <<~RUBY
    class Api::V1::HotReloadController < Api::V1::BaseController
      # 简化认证，仅检查用户是否存在
      before_action :ensure_user_exists
      
      def reload
        type = params[:type] || 'quick'
        
        begin
          case type
          when 'full'
            HotReloadManager.full_reload
            message = 'Full hot reload completed successfully'
          when 'controllers'
            HotReloadManager.reload_controllers
            message = 'Controllers reloaded successfully'
          when 'models'
            HotReloadManager.reload_models
            message = 'Models reloaded successfully'
          else
            HotReloadManager.quick_reload
            message = 'Quick hot reload completed successfully'
          end
          
          render json: { 
            status: 'success', 
            message: message,
            timestamp: Time.current,
            type: type
          }
        rescue => e
          render json: { 
            status: 'error', 
            message: e.message,
            timestamp: Time.current,
            type: type
          }, status: :internal_server_error
        end
      end
      
      def status
        render json: {
          status: 'running',
          environment: Rails.env,
          timestamp: Time.current,
          hot_reload_available: true,
          routes_count: Rails.application.routes.routes.count
        }
      end
      
      private
      
      def ensure_user_exists
        # 简化的用户检查
        unless Current.user
          render json: { message: 'User required for hot reload' }, status: :unauthorized
        end
      end
    end
  RUBY
  
  # 写入热更新控制器
  hot_reload_controller_path = '/app/app/controllers/api/v1/hot_reload_controller.rb'
  File.write(hot_reload_controller_path, hot_reload_controller_content)
  puts "✓ 热更新控制器已创建"

  # 3. 添加热更新路由（如果不存在）
  puts "3. 检查热更新路由..."
  
  routes_file = '/app/config/routes.rb'
  routes_content = File.read(routes_file)
  
  unless routes_content.include?('hot_reload')
    puts "  添加热更新路由..."
    
    # 在accounts命名空间中添加热更新路由
    hot_reload_routes = <<~RUBY
      
      # Hot reload endpoints
      resources :hot_reload, only: [] do
        collection do
          get :status
          post :reload
        end
      end
    RUBY
    
    # 在accounts命名空间中添加
    if routes_content.include?('namespace :accounts do')
      routes_content = routes_content.sub(
        /(namespace :accounts do.*?resources :enhanced_agents.*?end)/m,
        "\\1#{hot_reload_routes}"
      )
      
      File.write(routes_file, routes_content)
      puts "  ✓ 热更新路由已添加"
    else
      puts "  ❌ 找不到accounts命名空间"
    end
  else
    puts "  ✓ 热更新路由已存在"
  end

  # 4. 执行初始热更新
  puts "4. 执行初始热更新..."
  
  HotReloadManager.quick_reload

  # 5. 创建热更新助手函数
  puts "5. 创建热更新助手函数..."
  
  # 定义全局热更新函数
  def hot_reload(type = 'quick')
    case type.to_s
    when 'full'
      HotReloadManager.full_reload
    when 'controllers'
      HotReloadManager.reload_controllers
    when 'models'
      HotReloadManager.reload_models
    else
      HotReloadManager.quick_reload
    end
  end
  
  # 定义快速重新加载增强API的函数
  def reload_enhanced_api
    puts "重新加载增强API..."
    
    # 重新加载增强控制器
    enhanced_controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
    if File.exist?(enhanced_controller_path)
      load enhanced_controller_path
      puts "✓ 增强控制器已重新加载"
    end
    
    # 重新加载路由
    Rails.application.reload_routes!
    puts "✓ 路由已重新加载"
    
    # 清除缓存
    Rails.cache.clear if Rails.cache.respond_to?(:clear)
    puts "✓ 缓存已清除"
    
    puts "✓ 增强API热更新完成"
  end
  
  puts "✓ 热更新助手函数已创建"

  # 6. 验证热更新功能
  puts "6. 验证热更新功能..."
  
  # 检查路由
  hot_reload_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('hot_reload')
  end
  
  if hot_reload_routes.any?
    puts "✓ 热更新路由已注册 (#{hot_reload_routes.count}个)"
  else
    puts "⚠ 热更新路由未找到，但功能仍可通过Rails控制台使用"
  end
  
  # 检查增强API路由
  enhanced_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('enhanced_agents')
  end
  
  puts "✓ 增强API路由: #{enhanced_routes.count}个"

  puts ""
  puts "=== 简化热更新系统创建完成 ==="
  puts ""
  puts "✅ 热更新功能已启用！"
  puts ""
  puts "使用方法:"
  puts ""
  puts "1. Rails控制台命令:"
  puts "   hot_reload                    # 快速热更新"
  puts "   hot_reload('full')            # 完整热更新"
  puts "   hot_reload('controllers')     # 仅重新加载控制器"
  puts "   reload_enhanced_api           # 重新加载增强API"
  puts ""
  puts "2. 类方法:"
  puts "   HotReloadManager.quick_reload"
  puts "   HotReloadManager.full_reload"
  puts "   HotReloadManager.reload_controllers"
  puts ""
  puts "3. 如果路由可用，API端点:"
  puts "   GET  /api/v1/accounts/:account_id/hot_reload/status"
  puts "   POST /api/v1/accounts/:account_id/hot_reload/reload"
  puts ""
  puts "现在后续的修正都可以使用热更新，无需重启服务！"
  puts ""
  puts "示例: 修改增强API后运行 reload_enhanced_api 即可生效"

rescue => e
  puts "❌ 热更新系统创建失败: #{e.message}"
  puts e.backtrace.first(5)
end
