# 简单的密码重置脚本

puts "=== 简单密码重置 ==="

email = 'gibson@localhost.com'
password = 'Gibson888555!'

# 查找用户
user = User.find_by(email: email)

if user
  puts "找到用户: #{user.name} (#{user.email})"
  
  # 重置密码
  user.password = password
  user.password_confirmation = password
  user.confirmed_at = Time.current
  
  if user.save
    puts "✓ 密码重置成功"
    puts "邮箱: #{email}"
    puts "新密码: #{password}"
  else
    puts "✗ 密码重置失败: #{user.errors.full_messages.join(', ')}"
  end
else
  puts "用户不存在: #{email}"
  puts "请先通过网页界面注册账号"
end

puts ""
puts "登录信息:"
puts "  访问地址: http://localhost:3000"
puts "  邮箱: #{email}"
puts "  密码: #{password}"
