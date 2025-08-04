# 基础热更新系统

puts "=== 基础热更新系统 ==="
puts ""

begin
  # 1. 创建简单的热更新管理器
  puts "1. 创建热更新管理器..."
  
  class HotReloadManager
    def self.reload_enhanced_controller
      puts "  重新加载增强控制器..."
      
      enhanced_controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
      if File.exist?(enhanced_controller_path)
        load enhanced_controller_path
        puts "    ✓ 增强控制器已重新加载"
      end
    end
    
    def self.reload_routes
      puts "  重新加载路由..."
      Rails.application.reload_routes!
      puts "    ✓ 路由已重新加载"
    end
    
    def self.clear_rails_cache
      puts "  清除Rails缓存..."
      Rails.cache.clear if Rails.cache.respond_to?(:clear)
      puts "    ✓ Rails缓存已清除"
    end
    
    def self.reload_user_model
      puts "  重新加载用户模型..."
      user_model_path = '/app/app/models/user.rb'
      if File.exist?(user_model_path)
        load user_model_path
        puts "    ✓ 用户模型已重新加载"
      end
    end
    
    def self.quick_reload
      puts "执行快速热更新..."
      
      clear_rails_cache
      reload_enhanced_controller
      reload_routes
      
      puts "✓ 快速热更新完成"
    end
    
    def self.reload_enhanced_api
      puts "重新加载增强API..."
      
      reload_enhanced_controller
      reload_routes
      clear_rails_cache
      
      puts "✓ 增强API热更新完成"
    end
  end
  
  puts "✓ 热更新管理器已创建"

  # 2. 创建全局助手函数
  puts "2. 创建全局助手函数..."
  
  # 定义全局热更新函数
  def hot_reload
    HotReloadManager.quick_reload
  end
  
  def reload_enhanced_api
    HotReloadManager.reload_enhanced_api
  end
  
  def reload_user_features
    puts "重新加载用户功能..."
    HotReloadManager.reload_user_model
    HotReloadManager.reload_enhanced_controller
    HotReloadManager.reload_routes
    puts "✓ 用户功能热更新完成"
  end
  
  puts "✓ 全局助手函数已创建"

  # 3. 执行初始热更新
  puts "3. 执行初始热更新..."
  
  HotReloadManager.clear_rails_cache
  HotReloadManager.reload_enhanced_controller
  HotReloadManager.reload_routes

  # 4. 验证功能
  puts "4. 验证功能..."
  
  # 检查增强API路由
  enhanced_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('enhanced_agents')
  end
  
  puts "✓ 增强API路由: #{enhanced_routes.count}个"

  # 5. 创建独立的热更新脚本
  puts "5. 创建独立热更新脚本..."
  
  hot_reload_script = <<~RUBY
    # 独立热更新脚本
    # 使用: docker exec cschat-chatwoot-1 bundle exec rails runner /app/hot_reload.rb
    
    puts "执行热更新..."
    
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
    
    puts "✓ 热更新完成"
  RUBY
  
  File.write('/app/hot_reload.rb', hot_reload_script)
  puts "✓ 独立热更新脚本已创建"

  # 6. 创建快速命令脚本
  puts "6. 创建快速命令脚本..."
  
  quick_commands = <<~RUBY
    # 快速命令脚本
    # 提供常用的热更新命令
    
    class QuickReload
      def self.enhanced_api
        puts "快速重新加载增强API..."
        load '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
        Rails.application.reload_routes!
        Rails.cache.clear if Rails.cache.respond_to?(:clear)
        puts "✓ 增强API已重新加载"
      end
      
      def self.all
        puts "快速重新加载所有..."
        enhanced_api
        puts "✓ 全部重新加载完成"
      end
    end
    
    # 根据参数执行相应操作
    action = ARGV[0] || 'all'
    
    case action
    when 'api', 'enhanced'
      QuickReload.enhanced_api
    else
      QuickReload.all
    end
  RUBY
  
  File.write('/app/quick_reload.rb', quick_commands)
  puts "✓ 快速命令脚本已创建"

  puts ""
  puts "=== 基础热更新系统创建完成 ==="
  puts ""
  puts "✅ 热更新功能已启用！"
  puts ""
  puts "使用方法:"
  puts ""
  puts "1. Rails控制台命令:"
  puts "   hot_reload                    # 快速热更新"
  puts "   reload_enhanced_api           # 重新加载增强API"
  puts "   reload_user_features          # 重新加载用户功能"
  puts ""
  puts "2. 类方法:"
  puts "   HotReloadManager.quick_reload"
  puts "   HotReloadManager.reload_enhanced_api"
  puts "   HotReloadManager.clear_rails_cache"
  puts ""
  puts "3. 独立脚本 (推荐):"
  puts "   docker exec cschat-chatwoot-1 bundle exec rails runner /app/hot_reload.rb"
  puts "   docker exec cschat-chatwoot-1 bundle exec rails runner /app/quick_reload.rb"
  puts "   docker exec cschat-chatwoot-1 bundle exec rails runner /app/quick_reload.rb api"
  puts ""
  puts "4. 一键命令 (最简单):"
  puts "   docker exec cschat-chatwoot-1 bundle exec rails runner /app/hot_reload.rb"
  puts ""
  puts "现在后续的修正都可以使用热更新，无需重启服务！"
  puts ""
  puts "常用场景:"
  puts "- 修改增强API后运行: reload_enhanced_api"
  puts "- 修改任何控制器后运行: hot_reload"
  puts "- 快速修复后运行: docker exec ... /app/hot_reload.rb"

rescue => e
  puts "❌ 热更新系统创建失败: #{e.message}"
  puts e.backtrace.first(3)
end
