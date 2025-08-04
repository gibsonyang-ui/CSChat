# 简单验证Jesse账号

puts "=== Jesse账号验证 ==="
puts ""

# 查找Jesse用户
jesse = User.find_by(email: 'jesse@localhost.com')

if jesse
  puts "✅ Jesse账号信息:"
  puts "  - 邮箱: #{jesse.email}"
  puts "  - 姓名: #{jesse.name}"
  puts "  - 用户ID: #{jesse.id}"
  puts "  - 确认状态: #{jesse.confirmed_at ? '已确认' : '未确认'}"
  puts "  - 密码验证: #{jesse.valid_password?('Jesse1234!') ? '通过' : '失败'}"
  
  # 检查管理员权限
  account_user = jesse.account_users.first
  if account_user
    puts "  - 角色: #{account_user.role}"
    puts "  - 权限: #{account_user.administrator? ? '管理员' : '普通用户'}"
  end
  
  puts ""
  puts "🎯 登录信息:"
  puts "  邮箱: jesse@localhost.com"
  puts "  密码: Jesse1234!"
  puts "  地址: http://localhost:3000"
else
  puts "❌ Jesse用户不存在"
end

puts ""
puts "所有管理员账号:"
User.all.each do |user|
  au = user.account_users.first
  if au&.administrator?
    status = user.confirmed_at ? '已确认' : '未确认'
    puts "  - #{user.email} (#{status})"
  end
end
