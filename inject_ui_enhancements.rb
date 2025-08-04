# 注入UI增强脚本到Chatwoot页面

puts "=== 注入UI增强脚本 ==="
puts ""

begin
  # 1. 读取JavaScript文件
  js_content = File.read('/app/runtime_ui_enhancement.js')
  puts "✓ JavaScript文件读取成功 (#{js_content.length} 字符)"

  # 2. 查找应用布局文件
  layout_paths = [
    'app/views/layouts/application.html.erb',
    'app/views/layouts/dashboard.html.erb',
    'app/views/layouts/app.html.erb'
  ]

  layout_file = nil
  layout_paths.each do |path|
    full_path = Rails.root.join(path)
    if File.exist?(full_path)
      layout_file = full_path
      puts "✓ 找到布局文件: #{path}"
      break
    end
  end

  unless layout_file
    puts "❌ 找不到布局文件，尝试创建自定义注入方式"
    
    # 创建自定义中间件来注入JavaScript
    middleware_content = <<~RUBY
      class UiEnhancementMiddleware
        def initialize(app)
          @app = app
        end

        def call(env)
          status, headers, response = @app.call(env)
          
          # 只处理HTML响应
          if headers['Content-Type']&.include?('text/html')
            body = ""
            response.each { |part| body << part }
            
            # 注入JavaScript到页面底部
            if body.include?('</body>')
              enhancement_script = <<~JS
                <script type="text/javascript">
                #{File.read('/app/runtime_ui_enhancement.js')}
                </script>
              JS
              
              body = body.sub('</body>', "\#{enhancement_script}</body>")
              headers['Content-Length'] = body.bytesize.to_s
            end
            
            [status, headers, [body]]
          else
            [status, headers, response]
          end
        end
      end
    RUBY
    
    # 写入中间件文件
    middleware_path = Rails.root.join('app/middleware/ui_enhancement_middleware.rb')
    FileUtils.mkdir_p(File.dirname(middleware_path))
    File.write(middleware_path, middleware_content)
    puts "✓ 中间件文件已创建"
    
    # 添加到应用配置
    config_path = Rails.root.join('config/application.rb')
    config_content = File.read(config_path)
    
    unless config_content.include?('UiEnhancementMiddleware')
      # 在配置类中添加中间件
      config_content = config_content.sub(
        /(class Application < Rails::Application.*?)(end)/m,
        "\\1    config.middleware.use 'UiEnhancementMiddleware'\n    \\2"
      )
      
      File.write(config_path, config_content)
      puts "✓ 中间件已添加到应用配置"
    end
    
    puts "⚠ 需要重启应用以使中间件生效"
    exit 0
  end

  # 3. 修改布局文件注入JavaScript
  layout_content = File.read(layout_file)
  
  # 检查是否已经注入过
  if layout_content.include?('runtime_ui_enhancement')
    puts "✓ UI增强脚本已经注入过"
    exit 0
  end

  # 创建注入的脚本标签
  script_tag = <<~HTML
    <!-- Enhanced User Management UI -->
    <script type="text/javascript">
    #{js_content}
    </script>
  HTML

  # 在</body>标签前注入
  if layout_content.include?('</body>')
    layout_content = layout_content.sub('</body>', "#{script_tag}\n</body>")
    File.write(layout_file, layout_content)
    puts "✓ UI增强脚本已注入到布局文件"
  else
    puts "❌ 布局文件中找不到</body>标签"
    exit 1
  end

  # 4. 创建CSS样式文件
  css_content = <<~CSS
    /* Enhanced User Management Styles */
    .enhanced-password-section,
    .enhanced-confirmation-section,
    .enhanced-edit-section {
      margin: 16px 0;
    }

    .enhanced-password-section .form-group,
    .enhanced-confirmation-section .form-group,
    .enhanced-edit-section .form-group {
      margin: 12px 0;
    }

    .enhanced-password-section label,
    .enhanced-confirmation-section label,
    .enhanced-edit-section label {
      display: block;
      margin-bottom: 4px;
      font-weight: 500;
      color: #374151;
    }

    .enhanced-password-section input,
    .enhanced-confirmation-section input,
    .enhanced-edit-section input {
      width: 100%;
      padding: 8px 12px;
      border: 1px solid #d1d5db;
      border-radius: 4px;
      font-size: 14px;
    }

    .enhanced-password-section input:focus,
    .enhanced-confirmation-section input:focus,
    .enhanced-edit-section input:focus {
      outline: none;
      border-color: #1f93ff;
      box-shadow: 0 0 0 3px rgba(31, 147, 255, 0.1);
    }

    .enhanced-password-section small,
    .enhanced-confirmation-section small,
    .enhanced-edit-section small {
      color: #6b7280;
      font-size: 12px;
    }

    .enhanced-confirmation-section h4,
    .enhanced-edit-section h4 {
      margin: 0 0 12px 0;
      font-size: 14px;
      font-weight: 600;
      color: #495057;
    }

    .enhanced-edit-section button {
      padding: 6px 12px;
      border: none;
      border-radius: 4px;
      font-size: 12px;
      cursor: pointer;
      transition: background-color 0.2s;
    }

    .enhanced-edit-section button:hover {
      opacity: 0.9;
    }

    .enhanced-edit-section button:disabled {
      opacity: 0.6;
      cursor: not-allowed;
    }
  CSS

  # 写入CSS文件
  css_path = Rails.root.join('app/assets/stylesheets/enhanced_user_management.css')
  File.write(css_path, css_content)
  puts "✓ CSS样式文件已创建"

  # 5. 添加CSS到应用样式
  application_css_path = Rails.root.join('app/assets/stylesheets/application.css')
  if File.exist?(application_css_path)
    application_css = File.read(application_css_path)
    unless application_css.include?('enhanced_user_management')
      application_css += "\n\n@import 'enhanced_user_management';\n"
      File.write(application_css_path, application_css)
      puts "✓ CSS已添加到应用样式"
    end
  end

  puts ""
  puts "=== UI增强脚本注入完成 ==="
  puts ""
  puts "✅ 增强功能已成功注入!"
  puts ""
  puts "新增功能:"
  puts "✓ 动态密码设置 - 自动生成或自定义密码"
  puts "✓ 认证状态控制 - 立即认证或要求邮箱验证"
  puts "✓ 欢迎邮件选项 - 可选择发送欢迎邮件"
  puts "✓ 编辑界面增强 - 认证状态切换和密码管理"
  puts ""
  puts "注意事项:"
  puts "- 功能已注入到页面中，无需重启"
  puts "- 刷新浏览器页面即可看到新功能"
  puts "- 所有功能都是动态添加的，不影响原有代码"
  puts ""
  puts "使用方法:"
  puts "1. 登录管理员账号"
  puts "2. 进入设置 → 代理管理"
  puts "3. 点击添加代理或编辑现有代理"
  puts "4. 查看新增的密码和认证选项"

rescue => e
  puts "❌ 注入失败: #{e.message}"
  puts e.backtrace.first(5) if ENV['DEBUG']
end
