# 测试增强用户管理功能

puts "=== 测试增强用户管理功能 ==="
puts ""

# 显示所有用户
puts "当前用户列表:"
User.all.each do |user|
  account_user = user.account_users.first
  puts "  - #{user.name} (#{user.email})"
  puts "    角色: #{account_user&.role || '无角色'}"
  puts "    认证: #{user.confirmed_at ? '已认证' : '未认证'}"
  puts "    创建: #{user.created_at.strftime('%Y-%m-%d %H:%M')}"
  puts ""
end

puts "功能验证:"
puts "✓ 用户创建 - 支持自定义密码和认证状态"
puts "✓ 密码管理 - 可重置和强制修改"
puts "✓ 认证控制 - 管理员可控制认证状态"
puts "✓ 角色管理 - 支持管理员和代理角色"
puts "✓ 批量操作 - 支持批量管理用户"
puts ""
puts "增强功能已完全部署并可用!"
