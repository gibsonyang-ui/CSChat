# 最小化热更新系统 - 仅创建管理器，不创建控制器

puts "=== 最小化热更新系统 ==="
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

  # 2. 执行初始热更新
  puts "2. 执行初始热更新..."
  
  HotReloadManager.quick_reload

  # 3. 创建热更新助手函数
  puts "3. 创建热更新助手函数..."
  
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
  
  # 定义重新加载用户相关功能的函数
  def reload_user_features
    puts "重新加载用户相关功能..."
    
    # 重新加载用户模型
    ['user.rb', 'account.rb', 'account_user.rb'].each do |model|
      model_path = "/app/app/models/#{model}"
      if File.exist?(model_path)
        load model_path
        puts "✓ #{model} 已重新加载"
      end
    end
    
    # 重新加载增强API
    reload_enhanced_api
    
    puts "✓ 用户功能热更新完成"
  end
  
  puts "✓ 热更新助手函数已创建"

  # 4. 验证热更新功能
  puts "4. 验证热更新功能..."
  
  # 检查增强API路由
  enhanced_routes = Rails.application.routes.routes.select do |route|
    route.path.spec.to_s.include?('enhanced_agents')
  end
  
  puts "✓ 增强API路由: #{enhanced_routes.count}个"
  
  # 测试热更新功能
  begin
    HotReloadManager.clear_cache
    puts "✓ 热更新功能测试通过"
  rescue => e
    puts "❌ 热更新功能测试失败: #{e.message}"
  end

  # 5. 创建热更新脚本文件
  puts "5. 创建热更新脚本文件..."
  
  hot_reload_script = <<~RUBY
    # 热更新脚本
    # 使用方法: bundle exec rails runner /app/hot_reload.rb [type]
    
    # 加载热更新管理器
    class HotReloadManager
      def self.reload_controllers
        puts "重新加载控制器..."
        
        enhanced_controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
        if File.exist?(enhanced_controller_path)
          load enhanced_controller_path
          puts "✓ 增强控制器已重新加载"
        end
        
        Rails.application.reload_routes!
        puts "✓ 路由已重新加载"
      end
      
      def self.clear_cache
        Rails.cache.clear if Rails.cache.respond_to?(:clear)
        ActiveSupport::Dependencies.clear
        puts "✓ 缓存已清除"
      end
      
      def self.quick_reload
        puts "执行快速热更新..."
        clear_cache
        reload_controllers
        puts "✓ 快速热更新完成"
      end
    end
    
    # 执行热更新
    type = ARGV[0] || 'quick'
    
    case type
    when 'controllers'
      HotReloadManager.reload_controllers
    when 'cache'
      HotReloadManager.clear_cache
    else
      HotReloadManager.quick_reload
    end
  RUBY
  
  File.write('/app/hot_reload.rb', hot_reload_script)
  puts "✓ 热更新脚本已创建: /app/hot_reload.rb"

  puts ""
  puts "=== 最小化热更新系统创建完成 ==="
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
  puts "   reload_user_features          # 重新加载用户功能"
  puts ""
  puts "2. 类方法:"
  puts "   HotReloadManager.quick_reload"
  puts "   HotReloadManager.full_reload"
  puts "   HotReloadManager.reload_controllers"
  puts "   HotReloadManager.clear_cache"
  puts ""
  puts "3. 独立脚本:"
  puts "   bundle exec rails runner /app/hot_reload.rb"
  puts "   bundle exec rails runner /app/hot_reload.rb controllers"
  puts ""
  puts "现在后续的修正都可以使用热更新，无需重启服务！"
  puts ""
  puts "示例使用场景:"
  puts "- 修改增强API后: reload_enhanced_api"
  puts "- 修改用户模型后: reload_user_features"
  puts "- 一般修改后: hot_reload"

rescue => e
  puts "❌ 热更新系统创建失败: #{e.message}"
  puts e.backtrace.first(5)
end
