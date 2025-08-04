# Chatwoot 数据库初始化脚本 - 跳过有问题的迁移

puts "=== Chatwoot 数据库初始化 ==="

begin
  # 创建基础用户表结构（如果不存在）
  unless ActiveRecord::Base.connection.table_exists?('users')
    ActiveRecord::Base.connection.create_table :users do |t|
      t.string :email, null: false, default: ""
      t.string :name, null: false
      t.string :encrypted_password, null: false, default: ""
      t.datetime :confirmed_at
      t.timestamps null: false
    end
    
    ActiveRecord::Base.connection.add_index :users, :email, unique: true
    puts "✓ 创建用户表"
  end

  # 创建基础账号表结构（如果不存在）
  unless ActiveRecord::Base.connection.table_exists?('accounts')
    ActiveRecord::Base.connection.create_table :accounts do |t|
      t.string :name, null: false
      t.timestamps null: false
    end
    puts "✓ 创建账号表"
  end

  # 创建用户账号关联表（如果不存在）
  unless ActiveRecord::Base.connection.table_exists?('account_users')
    ActiveRecord::Base.connection.create_table :account_users do |t|
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.integer :role, default: 0
      t.timestamps null: false
    end
    puts "✓ 创建用户账号关联表"
  end

  puts "✓ 基础数据库结构创建完成"

rescue => e
  puts "⚠ 数据库初始化警告: #{e.message}"
  puts "这可能是因为表已存在，继续..."
end

# 创建管理员用户
puts ""
puts "创建管理员用户..."

begin
  # 检查用户是否已存在
  user = User.find_by(email: 'gibson@localhost.com')
  
  if user
    puts "✓ 用户已存在: #{user.email}"
    
    # 更新密码
    user.update!(
      password: 'Gibson888555!',
      password_confirmation: 'Gibson888555!',
      confirmed_at: Time.current
    )
    puts "✓ 密码已更新"
  else
    # 创建新用户
    user = User.create!(
      name: 'Gibson',
      email: 'gibson@localhost.com',
      password: 'Gibson888555!',
      password_confirmation: 'Gibson888555!',
      confirmed_at: Time.current
    )
    puts "✓ 用户创建成功: #{user.email}"
  end

  # 创建或查找账号
  account = Account.find_or_create_by(name: 'Gibson Admin Account')
  puts "✓ 账号准备完成: #{account.name}"

  # 创建用户账号关联
  account_user = AccountUser.find_or_create_by(user: user, account: account) do |au|
    au.role = 1  # administrator
  end
  puts "✓ 用户权限设置完成"

rescue => e
  puts "✗ 用户创建失败: #{e.message}"
  puts "请通过网页界面手动注册"
end

puts ""
puts "=== 初始化完成 ==="
puts "登录信息:"
puts "  邮箱: gibson@localhost.com"
puts "  密码: Gibson888555!"
puts "  访问: http://localhost:3000"
