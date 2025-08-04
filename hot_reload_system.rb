# Chatwoot 热更新系统
# 实现不重启服务的热更新机制

puts "=== Chatwoot 热更新系统 ==="
puts ""

begin
  # 1. 创建热更新管理器
  puts "1. 创建热更新管理器..."
  
  class HotReloadManager
    def self.reload_controllers
      puts "  重新加载控制器..."
      
      # 重新加载所有控制器文件
      Dir.glob(Rails.root.join('app/controllers/**/*.rb')).each do |file|
        begin
          load file
          puts "    ✓ 重新加载: #{File.basename(file)}"
        rescue => e
          puts "    ❌ 加载失败: #{File.basename(file)} - #{e.message}"
        end
      end
      
      # 重新加载路由
      Rails.application.reload_routes!
      puts "    ✓ 路由已重新加载"
    end
    
    def self.reload_models
      puts "  重新加载模型..."
      
      Dir.glob(Rails.root.join('app/models/**/*.rb')).each do |file|
        begin
          load file
          puts "    ✓ 重新加载: #{File.basename(file)}"
        rescue => e
          puts "    ❌ 加载失败: #{File.basename(file)} - #{e.message}"
        end
      end
    end
    
    def self.reload_helpers
      puts "  重新加载助手..."
      
      Dir.glob(Rails.root.join('app/helpers/**/*.rb')).each do |file|
        begin
          load file
          puts "    ✓ 重新加载: #{File.basename(file)}"
        rescue => e
          puts "    ❌ 加载失败: #{File.basename(file)} - #{e.message}"
        end
      end
    end
    
    def self.reload_services
      puts "  重新加载服务..."
      
      Dir.glob(Rails.root.join('app/services/**/*.rb')).each do |file|
        begin
          load file
          puts "    ✓ 重新加载: #{File.basename(file)}"
        rescue => e
          puts "    ❌ 加载失败: #{File.basename(file)} - #{e.message}"
        end
      end
    end
    
    def self.reload_config
      puts "  重新加载配置..."
      
      # 重新加载初始化文件
      Dir.glob(Rails.root.join('config/initializers/**/*.rb')).each do |file|
        begin
          load file
          puts "    ✓ 重新加载: #{File.basename(file)}"
        rescue => e
          puts "    ❌ 加载失败: #{File.basename(file)} - #{e.message}"
        end
      end
    end
    
    def self.clear_cache
      puts "  清除缓存..."
      
      # 清除Rails缓存
      Rails.cache.clear if Rails.cache.respond_to?(:clear)
      
      # 清除类缓存
      ActiveSupport::Dependencies.clear
      
      # 清除常量缓存
      if defined?(ActiveSupport::Dependencies::Reference)
        ActiveSupport::Dependencies::Reference.clear!
      end
      
      puts "    ✓ 缓存已清除"
    end
    
    def self.full_reload
      puts "执行完整热更新..."
      
      clear_cache
      reload_models
      reload_controllers
      reload_helpers
      reload_services
      reload_config
      
      puts "✓ 完整热更新完成"
    end
    
    def self.quick_reload
      puts "执行快速热更新..."
      
      clear_cache
      reload_controllers
      
      puts "✓ 快速热更新完成"
    end
  end
  
  puts "✓ 热更新管理器已创建"

  # 2. 创建热更新API端点
  puts "2. 创建热更新API端点..."
  
  hot_reload_controller_content = <<~RUBY
    class Api::V1::HotReloadController < ApplicationController
      # 跳过认证以便于开发时使用
      skip_before_action :authenticate_user!, only: [:reload, :status]
      
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
          hot_reload_available: true
        }
      end
    end
  RUBY
  
  # 写入热更新控制器
  hot_reload_controller_path = '/app/app/controllers/api/v1/hot_reload_controller.rb'
  File.write(hot_reload_controller_path, hot_reload_controller_content)
  puts "✓ 热更新控制器已创建"

  # 3. 添加热更新路由
  puts "3. 添加热更新路由..."
  
  routes_file = '/app/config/routes.rb'
  routes_content = File.read(routes_file)
  
  unless routes_content.include?('hot_reload')
    # 在API路由中添加热更新端点
    hot_reload_routes = <<~RUBY
      
      # Hot reload endpoints for development
      namespace :api do
        namespace :v1 do
          get 'hot_reload/status', to: 'hot_reload#status'
          post 'hot_reload/reload', to: 'hot_reload#reload'
        end
      end
    RUBY
    
    # 在文件末尾添加路由
    routes_content = routes_content.sub(/end\s*\z/, "#{hot_reload_routes}end")
    File.write(routes_file, routes_content)
    puts "✓ 热更新路由已添加"
  else
    puts "✓ 热更新路由已存在"
  end

  # 4. 创建热更新助手脚本
  puts "4. 创建热更新助手脚本..."
  
  hot_reload_helper_content = <<~RUBY
    # 热更新助手脚本
    
    class HotReloadHelper
      def self.reload_enhanced_api
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
      end
      
      def self.reload_user_changes
        puts "重新加载用户相关更改..."
        
        # 重新加载用户模型
        load '/app/app/models/user.rb' if File.exist?('/app/app/models/user.rb')
        
        # 重新加载账号模型
        load '/app/app/models/account.rb' if File.exist?('/app/app/models/account.rb')
        
        # 重新加载账号用户模型
        load '/app/app/models/account_user.rb' if File.exist?('/app/app/models/account_user.rb')
        
        puts "✓ 用户相关模型已重新加载"
      end
      
      def self.apply_database_changes
        puts "应用数据库更改..."
        
        # 重新加载Active Record
        ActiveRecord::Base.connection.schema_cache.clear!
        ActiveRecord::Base.descendants.each(&:reset_column_information)
        
        puts "✓ 数据库模式已重新加载"
      end
      
      def self.update_frontend_assets
        puts "更新前端资源..."
        
        # 复制JavaScript文件到public目录
        js_files = [
          'enhanced_agents_api.js',
          'chatwoot_ui_enhancer.js',
          'enhanced_features_demo.html'
        ]
        
        js_files.each do |filename|
          if File.exist?("/app/#{filename}")
            FileUtils.cp("/app/#{filename}", "/app/public/#{filename}")
            puts "✓ 已更新: #{filename}"
          end
        end
      end
    end
    
    # 执行热更新
    puts "=== 执行热更新 ==="
    
    HotReloadHelper.reload_enhanced_api
    HotReloadHelper.reload_user_changes
    HotReloadHelper.apply_database_changes
    HotReloadHelper.update_frontend_assets
    
    puts "✓ 热更新完成"
  RUBY
  
  hot_reload_helper_path = '/app/lib/hot_reload_helper.rb'
  FileUtils.mkdir_p(File.dirname(hot_reload_helper_path))
  File.write(hot_reload_helper_path, hot_reload_helper_content)
  puts "✓ 热更新助手已创建"

  # 5. 执行初始热更新
  puts "5. 执行初始热更新..."
  
  # 重新加载当前的增强控制器
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

  # 6. 验证热更新功能
  puts "6. 验证热更新功能..."
  
  # 检查热更新控制器是否可用
  begin
    controller = Api::V1::HotReloadController.new
    puts "✓ 热更新控制器可用"
  rescue => e
    puts "❌ 热更新控制器不可用: #{e.message}"
  end
  
  # 检查路由
  hot_reload_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('hot_reload')
  end
  
  if hot_reload_routes.any?
    puts "✓ 热更新路由已注册 (#{hot_reload_routes.count}个)"
    hot_reload_routes.each do |route|
      puts "  - #{route.verb} #{route.path.spec}"
    end
  else
    puts "❌ 热更新路由未注册"
  end

  puts ""
  puts "=== 热更新系统创建完成 ==="
  puts ""
  puts "✅ 热更新功能已启用！"
  puts ""
  puts "可用的热更新方法:"
  puts ""
  puts "1. API端点:"
  puts "   POST /api/v1/hot_reload/reload?type=quick    # 快速重新加载"
  puts "   POST /api/v1/hot_reload/reload?type=full     # 完整重新加载"
  puts "   POST /api/v1/hot_reload/reload?type=controllers # 仅重新加载控制器"
  puts "   GET  /api/v1/hot_reload/status               # 检查状态"
  puts ""
  puts "2. Rails控制台:"
  puts "   HotReloadManager.quick_reload                # 快速重新加载"
  puts "   HotReloadManager.full_reload                 # 完整重新加载"
  puts "   HotReloadManager.reload_controllers          # 仅重新加载控制器"
  puts ""
  puts "3. 助手脚本:"
  puts "   load '/app/lib/hot_reload_helper.rb'         # 加载助手"
  puts ""
  puts "现在后续的修正都可以使用热更新，无需重启服务！"

rescue => e
  puts "❌ 热更新系统创建失败: #{e.message}"
  puts e.backtrace.first(5)
end
