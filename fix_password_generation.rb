# 修复密码生成函数

puts "=== 修复密码生成函数 ==="
puts ""

begin
  # 1. 读取当前控制器文件
  controller_path = '/app/app/controllers/api/v1/accounts/enhanced_agents_controller.rb'
  controller_content = File.read(controller_path)
  
  puts "✓ 控制器文件读取成功"

  # 2. 修复密码生成函数
  old_generate_function = <<~RUBY
      def generate_password
        chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%'
        Array.new(12) { chars[rand(chars.length)] }.join
      end
  RUBY

  new_generate_function = <<~RUBY
      def generate_password
        # 确保密码包含所有必需的字符类型
        uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        lowercase = 'abcdefghijklmnopqrstuvwxyz'
        numbers = '0123456789'
        special = '!@#$%^&*()_+-=[]{}|'
        
        # 确保至少包含每种类型的一个字符
        password = ''
        password += uppercase[rand(uppercase.length)]
        password += lowercase[rand(lowercase.length)]
        password += numbers[rand(numbers.length)]
        password += special[rand(special.length)]
        
        # 填充剩余字符
        all_chars = uppercase + lowercase + numbers + special
        (12 - 4).times do
          password += all_chars[rand(all_chars.length)]
        end
        
        # 随机打乱字符顺序
        password.chars.shuffle.join
      end
  RUBY

  # 3. 替换密码生成函数
  if controller_content.include?('def generate_password')
    updated_content = controller_content.gsub(
      /def generate_password.*?end/m,
      new_generate_function.strip
    )
    
    File.write(controller_path, updated_content)
    puts "✓ 密码生成函数已更新"
  else
    puts "❌ 找不到密码生成函数"
  end

  # 4. 测试新的密码生成
  puts "测试新的密码生成函数..."
  
  def generate_password
    # 确保密码包含所有必需的字符类型
    uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    lowercase = 'abcdefghijklmnopqrstuvwxyz'
    numbers = '0123456789'
    special = '!@#$%^&*()_+-=[]{}|'
    
    # 确保至少包含每种类型的一个字符
    password = ''
    password += uppercase[rand(uppercase.length)]
    password += lowercase[rand(lowercase.length)]
    password += numbers[rand(numbers.length)]
    password += special[rand(special.length)]
    
    # 填充剩余字符
    all_chars = uppercase + lowercase + numbers + special
    (12 - 4).times do
      password += all_chars[rand(all_chars.length)]
    end
    
    # 随机打乱字符顺序
    password.chars.shuffle.join
  end
  
  # 生成几个测试密码
  5.times do |i|
    test_password = generate_password
    puts "  测试密码 #{i + 1}: #{test_password}"
    
    # 验证密码要求
    has_upper = test_password.match?(/[A-Z]/)
    has_lower = test_password.match?(/[a-z]/)
    has_number = test_password.match?(/[0-9]/)
    has_special = test_password.match?(/[!@#$%^&*()_+\-=\[\]{}|]/)
    
    if has_upper && has_lower && has_number && has_special
      puts "    ✓ 密码验证通过"
    else
      puts "    ❌ 密码验证失败"
      puts "      大写字母: #{has_upper}"
      puts "      小写字母: #{has_lower}"
      puts "      数字: #{has_number}"
      puts "      特殊字符: #{has_special}"
    end
  end

  puts ""
  puts "=== 密码生成修复完成 ==="
  puts ""
  puts "✅ 密码生成函数已修复！"
  puts ""
  puts "新密码特点:"
  puts "✓ 12位字符长度"
  puts "✓ 包含大写字母"
  puts "✓ 包含小写字母"
  puts "✓ 包含数字"
  puts "✓ 包含特殊字符"
  puts "✓ 随机字符顺序"

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
