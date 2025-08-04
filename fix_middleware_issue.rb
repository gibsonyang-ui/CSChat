# 修复中间件配置问题

puts "=== 修复中间件配置问题 ==="

begin
  # 1. 移除有问题的中间件配置
  config_path = Rails.root.join('config/application.rb')
  config_content = File.read(config_path)
  
  if config_content.include?('UiEnhancementMiddleware')
    puts "移除有问题的中间件配置..."
    
    # 移除中间件配置行
    config_content = config_content.gsub(/\s*config\.middleware\.use\s+['"]?UiEnhancementMiddleware['"]?\s*\n/, '')
    
    File.write(config_path, config_content)
    puts "✓ 中间件配置已移除"
  end

  # 2. 删除中间件文件
  middleware_path = Rails.root.join('app/middleware/ui_enhancement_middleware.rb')
  if File.exist?(middleware_path)
    File.delete(middleware_path)
    puts "✓ 中间件文件已删除"
  end

  # 3. 创建一个简单的静态文件服务方案
  puts "创建静态文件服务方案..."
  
  # 创建public目录下的增强脚本
  public_js_path = Rails.root.join('public/enhanced_user_management.js')
  js_content = File.read('/app/runtime_ui_enhancement.js')
  File.write(public_js_path, js_content)
  puts "✓ JavaScript文件已复制到public目录"

  # 创建一个简单的HTML页面来加载脚本
  html_content = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
        <title>Chatwoot 增强功能加载器</title>
        <meta charset="UTF-8">
    </head>
    <body>
        <script>
            // 自动加载增强功能到父窗口
            if (window.parent && window.parent !== window) {
                // 在iframe中，加载到父窗口
                var script = window.parent.document.createElement('script');
                script.src = '/enhanced_user_management.js';
                window.parent.document.head.appendChild(script);
                
                // 显示加载消息
                document.body.innerHTML = '<div style="padding: 20px; text-align: center; font-family: Arial, sans-serif;"><h2>🚀 增强功能已加载</h2><p>Chatwoot用户管理增强功能已成功加载到主页面。</p><p><a href="javascript:window.close();">关闭此窗口</a></p></div>';
            } else {
                // 直接访问，加载到当前窗口
                var script = document.createElement('script');
                script.src = '/enhanced_user_management.js';
                document.head.appendChild(script);
                
                document.body.innerHTML = '<div style="padding: 20px; text-align: center; font-family: Arial, sans-serif;"><h2>🚀 增强功能已加载</h2><p>Chatwoot用户管理增强功能已加载。</p><p><a href="/">返回主页</a></p></div>';
            }
        </script>
    </body>
    </html>
  HTML

  html_path = Rails.root.join('public/load_enhancements.html')
  File.write(html_path, html_content)
  puts "✓ 增强功能加载页面已创建"

  puts ""
  puts "=== 修复完成 ==="
  puts ""
  puts "✅ 中间件问题已修复!"
  puts ""
  puts "现在可以通过以下方式使用增强功能:"
  puts "1. 访问: http://localhost:3000/load_enhancements.html"
  puts "2. 或直接在浏览器控制台运行:"
  puts "   var script = document.createElement('script');"
  puts "   script.src = '/enhanced_user_management.js';"
  puts "   document.head.appendChild(script);"
  puts ""
  puts "3. 或使用书签工具: chatwoot_user_bookmarklet.html"

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5) if ENV['DEBUG']
end
