# 简单用户创建脚本 - 跳过复杂的数据库结构

puts "=== 简单用户创建 ==="

begin
  # 尝试创建用户
  user = User.new(
    name: 'Gibson',
    email: 'gibson@localhost.com',
    password: 'Gibson888555!',
    password_confirmation: 'Gibson888555!',
    confirmed_at: Time.current
  )
  
  if user.save
    puts "✓ 用户创建成功"
    puts "邮箱: #{user.email}"
    puts "姓名: #{user.name}"
  else
    puts "✗ 用户创建失败: #{user.errors.full_messages.join(', ')}"
  end
  
rescue => e
  puts "✗ 创建用户时出错: #{e.message}"
  puts "这可能是因为数据库结构不完整"
end

puts ""
puts "如果用户创建失败，请通过网页界面注册新账号"
puts "访问: http://localhost:3000"
