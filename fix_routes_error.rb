# 修复路由错误

puts "=== 修复路由错误 ==="

routes_path = Rails.root.join('config/routes.rb')
routes_content = File.read(routes_path)

# 查找并修复错误的路由语法
if routes_content.include?('collectionmember')
  puts "发现路由语法错误，正在修复..."
  
  # 修复错误的语法
  routes_content = routes_content.gsub(/on: :collectionmember/, 'on: :collection')
  routes_content = routes_content.gsub(/on: :membercollection/, 'on: :member')
  
  # 确保正确的路由格式
  if routes_content.include?('resources :agents')
    # 查找agents资源并确保正确的member路由
    routes_content = routes_content.gsub(
      /(resources :agents[^}]*?)(member do[^}]*?end)/m,
      "\\1"
    )
    
    # 重新添加正确的member路由
    routes_content = routes_content.sub(
      /(resources :agents[^}]*?)(\s+end)/m,
      <<~RUBY.chomp
        \\1
                member do
                  post :toggle_confirmation
                  post :reset_password
                end
        \\2
      RUBY
    )
  end
  
  File.write(routes_path, routes_content)
  puts "✓ 路由错误已修复"
else
  puts "✓ 未发现路由错误"
end

puts "=== 修复完成 ==="
