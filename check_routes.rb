# 检查增强API路由

puts "=== 检查增强API路由 ==="
puts ""

# 检查所有路由
all_routes = Rails.application.routes.routes
puts "总路由数: #{all_routes.count}"

# 查找enhanced相关路由
enhanced_routes = all_routes.select do |route|
  route.path.spec.to_s.include?('enhanced')
end

puts "Enhanced路由数: #{enhanced_routes.count}"

if enhanced_routes.any?
  puts ""
  puts "Enhanced路由列表:"
  enhanced_routes.each do |route|
    puts "  #{route.verb.ljust(6)} #{route.path.spec}"
  end
else
  puts ""
  puts "❌ 没有找到enhanced路由"
  
  # 检查accounts相关路由
  accounts_routes = all_routes.select do |route|
    route.path.spec.to_s.include?('accounts') && route.path.spec.to_s.include?('agents')
  end
  
  puts ""
  puts "Accounts/Agents路由 (#{accounts_routes.count}个):"
  accounts_routes.first(5).each do |route|
    puts "  #{route.verb.ljust(6)} #{route.path.spec}"
  end
end

# 检查控制器是否可以加载
puts ""
puts "检查控制器:"
begin
  controller_class = Api::V1::Accounts::EnhancedAgentsController
  puts "✓ 控制器类可以加载: #{controller_class}"
rescue => e
  puts "❌ 控制器加载失败: #{e.message}"
end

puts ""
puts "=== 检查完成 ==="
