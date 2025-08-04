# 检查Chatwoot数据库结构和功能完整性

puts "=== Chatwoot 数据库结构检查 ==="
puts ""

# 检查所有表
puts "1. 数据库表检查:"
tables = ActiveRecord::Base.connection.tables.sort
puts "总共 #{tables.count} 个表:"
tables.each { |table| puts "  - #{table}" }

puts ""
puts "2. 关键表结构检查:"

# 检查用户表
if ActiveRecord::Base.connection.table_exists?('users')
  columns = ActiveRecord::Base.connection.columns('users')
  puts "users 表 (#{columns.count} 个字段):"
  columns.each { |col| puts "  - #{col.name}: #{col.type}" }
else
  puts "❌ users 表不存在"
end

puts ""

# 检查账号表
if ActiveRecord::Base.connection.table_exists?('accounts')
  columns = ActiveRecord::Base.connection.columns('accounts')
  puts "accounts 表 (#{columns.count} 个字段):"
  columns.each { |col| puts "  - #{col.name}: #{col.type}" }
else
  puts "❌ accounts 表不存在"
end

puts ""

# 检查其他重要表
important_tables = [
  'account_users',
  'inboxes', 
  'conversations',
  'messages',
  'contacts',
  'teams',
  'team_members',
  'custom_attributes',
  'webhooks',
  'integrations'
]

puts "3. 重要功能表检查:"
important_tables.each do |table|
  if ActiveRecord::Base.connection.table_exists?(table)
    count = ActiveRecord::Base.connection.columns(table).count
    puts "✓ #{table} 表存在 (#{count} 个字段)"
  else
    puts "❌ #{table} 表不存在"
  end
end

puts ""
puts "4. 数据检查:"

# 检查用户数据
if defined?(User)
  user_count = User.count
  puts "用户总数: #{user_count}"
  if user_count > 0
    User.limit(3).each do |user|
      puts "  - #{user.name} (#{user.email})"
    end
  end
else
  puts "❌ User 模型不可用"
end

# 检查账号数据
if defined?(Account)
  account_count = Account.count
  puts "账号总数: #{account_count}"
  if account_count > 0
    Account.limit(3).each do |account|
      puts "  - #{account.name}"
    end
  end
else
  puts "❌ Account 模型不可用"
end

puts ""
puts "5. 功能模型检查:"

# 检查重要模型是否可用
models_to_check = [
  'User', 'Account', 'AccountUser', 'Inbox', 'Conversation', 
  'Message', 'Contact', 'Team', 'TeamMember', 'CustomAttribute'
]

models_to_check.each do |model_name|
  begin
    model_class = model_name.constantize
    puts "✓ #{model_name} 模型可用"
  rescue NameError
    puts "❌ #{model_name} 模型不可用"
  end
end

puts ""
puts "=== 检查完成 ==="
