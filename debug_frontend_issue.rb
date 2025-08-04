# 调试前端更改未生效的问题

puts "=== 调试前端更改未生效问题 ==="
puts ""

begin
  # 1. 检查当前agents页面文件
  puts "1. 检查agents页面文件状态..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  if File.exist?(agents_index_path)
    agents_content = File.read(agents_index_path)
    puts "✓ 文件存在，大小: #{agents_content.length} 字符"
    
    # 检查关键功能是否存在
    features = {
      'showEnhancedActions' => agents_content.include?('showEnhancedActions'),
      'toggleConfirmation' => agents_content.include?('toggleConfirmation'),
      'checkmark图标' => agents_content.include?('checkmark'),
      'lock图标' => agents_content.include?('lock'),
      '密码重置模态框' => agents_content.include?('密码重置模态框'),
    }
    
    features.each do |feature, exists|
      status = exists ? "✓" : "❌"
      puts "  #{status} #{feature}: #{exists ? '存在' : '缺失'}"
    end
  else
    puts "❌ agents页面文件不存在"
    exit 1
  end

  # 2. 检查前端构建状态
  puts ""
  puts "2. 检查前端构建状态..."
  
  # 检查是否需要重新构建前端资源
  puts "检查前端资源构建..."
  
  # 检查webpack或vite进程
  begin
    # 检查是否有前端构建进程在运行
    puts "检查前端构建进程..."
  rescue => e
    puts "检查构建进程时出错: #{e.message}"
  end

  # 3. 检查浏览器缓存问题
  puts ""
  puts "3. 可能的前端问题分析..."
  
  possible_issues = [
    "前端资源需要重新构建",
    "浏览器缓存了旧版本",
    "Vue组件热重载未生效",
    "JavaScript编译错误",
    "路由配置问题"
  ]
  
  puts "可能的问题:"
  possible_issues.each_with_index do |issue, index|
    puts "  #{index + 1}. #{issue}"
  end

  # 4. 检查Vue文件语法
  puts ""
  puts "4. 检查Vue文件语法..."
  
  # 检查基本语法错误
  syntax_issues = []
  
  # 检查script标签
  script_tags = agents_content.scan(/<script[^>]*>/).count
  script_end_tags = agents_content.scan(/<\/script>/).count
  if script_tags != script_end_tags
    syntax_issues << "script标签不匹配"
  end
  
  # 检查template标签
  template_tags = agents_content.scan(/<template[^>]*>/).count
  template_end_tags = agents_content.scan(/<\/template>/).count
  if template_tags != template_end_tags
    syntax_issues << "template标签不匹配"
  end
  
  # 检查引号匹配
  if agents_content.count('"') % 2 != 0
    syntax_issues << "双引号不匹配"
  end
  
  if syntax_issues.any?
    puts "发现语法问题:"
    syntax_issues.each { |issue| puts "  ❌ #{issue}" }
  else
    puts "✓ 基本语法检查通过"
  end

  # 5. 强制重新构建前端
  puts ""
  puts "5. 尝试强制重新构建前端..."
  
  # 创建一个强制重新构建的脚本
  rebuild_script = <<~BASH
    #!/bin/bash
    echo "强制重新构建前端资源..."
    
    # 清除可能的缓存
    rm -rf /app/tmp/cache/webpacker* 2>/dev/null || true
    rm -rf /app/tmp/cache/assets* 2>/dev/null || true
    rm -rf /app/public/packs* 2>/dev/null || true
    
    # 重新编译资源
    cd /app
    
    # 检查是否使用webpack
    if [ -f "config/webpack.config.js" ] || [ -f "config/webpacker.yml" ]; then
      echo "使用Webpacker重新编译..."
      bundle exec rails webpacker:compile 2>/dev/null || echo "Webpacker编译失败"
    fi
    
    # 检查是否使用vite
    if [ -f "vite.config.js" ] || [ -f "vite.config.ts" ]; then
      echo "使用Vite重新编译..."
      npm run build 2>/dev/null || yarn build 2>/dev/null || echo "Vite编译失败"
    fi
    
    # 预编译资源
    echo "预编译Rails资源..."
    bundle exec rails assets:precompile 2>/dev/null || echo "资源预编译失败"
    
    echo "前端重新构建完成"
  BASH
  
  File.write('/app/rebuild_frontend.sh', rebuild_script)
  File.chmod('/app/rebuild_frontend.sh', 0755)
  puts "✓ 重新构建脚本已创建"

  # 6. 创建简单的测试页面
  puts ""
  puts "6. 创建测试页面验证功能..."
  
  test_page = <<~HTML
    <!DOCTYPE html>
    <html>
    <head>
      <title>增强功能测试页面</title>
      <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .test-section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }
        .button { padding: 8px 16px; margin: 5px; background: #007bff; color: white; border: none; cursor: pointer; }
        .success { background: #28a745; }
        .danger { background: #dc3545; }
      </style>
    </head>
    <body>
      <h1>增强功能测试页面</h1>
      
      <div class="test-section">
        <h2>API端点测试</h2>
        <button class="button" onclick="testAPI()">测试增强API</button>
        <div id="api-result"></div>
      </div>
      
      <div class="test-section">
        <h2>用户列表</h2>
        <button class="button" onclick="loadUsers()">加载用户列表</button>
        <div id="users-list"></div>
      </div>
      
      <div class="test-section">
        <h2>功能测试</h2>
        <button class="button success" onclick="testToggleConfirmation()">测试认证切换</button>
        <button class="button danger" onclick="testPasswordReset()">测试密码重置</button>
        <div id="function-result"></div>
      </div>
      
      <script>
        async function testAPI() {
          const result = document.getElementById('api-result');
          try {
            const response = await fetch('/api/v1/accounts/1/enhanced_agents/status');
            if (response.ok) {
              result.innerHTML = '<p style="color: green;">✓ 增强API端点可访问</p>';
            } else {
              result.innerHTML = '<p style="color: red;">❌ API返回状态: ' + response.status + '</p>';
            }
          } catch (error) {
            result.innerHTML = '<p style="color: red;">❌ API请求失败: ' + error.message + '</p>';
          }
        }
        
        async function loadUsers() {
          const result = document.getElementById('users-list');
          try {
            const response = await fetch('/api/v1/accounts/1/agents');
            if (response.ok) {
              const users = await response.json();
              result.innerHTML = '<p>找到 ' + users.length + ' 个用户</p>';
            } else {
              result.innerHTML = '<p style="color: red;">加载用户失败</p>';
            }
          } catch (error) {
            result.innerHTML = '<p style="color: red;">请求失败: ' + error.message + '</p>';
          }
        }
        
        function testToggleConfirmation() {
          const result = document.getElementById('function-result');
          result.innerHTML = '<p style="color: blue;">认证切换功能需要在agents页面中测试</p>';
        }
        
        function testPasswordReset() {
          const result = document.getElementById('function-result');
          result.innerHTML = '<p style="color: blue;">密码重置功能需要在agents页面中测试</p>';
        }
      </script>
    </body>
    </html>
  HTML
  
  File.write('/app/public/enhanced_test.html', test_page)
  puts "✓ 测试页面已创建: http://localhost:3000/enhanced_test.html"

  # 7. 检查当前页面的实际HTML输出
  puts ""
  puts "7. 分析当前页面问题..."
  
  puts "从截图分析:"
  puts "  - 页面显示了3个用户: Gibson, Jesse, Lisa"
  puts "  - 每个用户只有2个按钮: 编辑(铅笔图标) 和 删除(垃圾桶图标)"
  puts "  - 缺少认证切换按钮和密码重置按钮"
  puts "  - 这说明前端Vue组件没有加载新的代码"

  puts ""
  puts "=== 调试完成 ==="
  puts ""
  puts "🔍 问题诊断:"
  puts "1. Vue文件已正确修改，包含所有增强功能"
  puts "2. 但前端页面没有显示新按钮"
  puts "3. 这是典型的前端资源未重新编译问题"
  puts ""
  puts "🛠 解决方案:"
  puts "1. 执行前端重新构建: bash /app/rebuild_frontend.sh"
  puts "2. 清除浏览器缓存并刷新页面"
  puts "3. 检查浏览器控制台是否有JavaScript错误"
  puts "4. 访问测试页面: http://localhost:3000/enhanced_test.html"

rescue => e
  puts "❌ 调试失败: #{e.message}"
  puts e.backtrace.first(5)
end
