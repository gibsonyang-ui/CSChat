# 添加增强API路由

puts "=== 添加增强API路由 ==="
puts ""

begin
  routes_file = '/app/config/routes.rb'
  routes_content = File.read(routes_file)
  
  puts "当前路由文件大小: #{routes_content.length} 字符"
  
  # 检查是否已经有enhanced_agents路由
  if routes_content.include?('enhanced_agents')
    puts "✓ enhanced_agents路由已存在"
  else
    puts "❌ enhanced_agents路由不存在，正在添加..."
    
    # 查找agents路由的位置
    agents_match = routes_content.match(/(.*resources :agents.*?end.*?)/m)
    
    if agents_match
      puts "✓ 找到agents路由位置"
      
      # 在agents路由后添加enhanced_agents路由
      enhanced_routes = <<~RUBY
        
        # Enhanced user management routes
        resources :enhanced_agents do
          member do
            patch :toggle_confirmation
            patch :reset_password
          end
        end
      RUBY
      
      # 替换agents路由部分，在其后添加enhanced路由
      new_content = routes_content.sub(
        /(resources :agents.*?end)/m,
        "\\1#{enhanced_routes}"
      )
      
      # 写入新的路由文件
      File.write(routes_file, new_content)
      puts "✓ enhanced_agents路由已添加"
      
      # 验证添加是否成功
      updated_content = File.read(routes_file)
      if updated_content.include?('enhanced_agents')
        puts "✓ 路由添加验证成功"
      else
        puts "❌ 路由添加验证失败"
      end
      
    else
      puts "❌ 找不到agents路由位置"
      
      # 显示routes文件的相关部分
      puts ""
      puts "Routes文件中包含'agents'的行:"
      routes_content.lines.each_with_index do |line, index|
        if line.include?('agents')
          puts "  #{index + 1}: #{line.strip}"
        end
      end
    end
  end
  
  puts ""
  puts "=== 路由添加完成 ==="
  puts ""
  puts "现在需要重新加载Rails应用以使路由生效"
  puts "建议操作: 重启Chatwoot服务"

rescue => e
  puts "❌ 添加路由失败: #{e.message}"
  puts e.backtrace.first(5)
end
