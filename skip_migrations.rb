# 跳过有问题的迁移脚本

puts "=== 跳过有问题的迁移 ==="

# 有问题的迁移列表
problematic_migrations = [
  '20231211010807',  # AddCachedLabelsList
  '20231219000743',  # ReRunCacheLabelJob
  '20231219073832',  # AddLastActivityAtToNotifications
]

problematic_migrations.each do |version|
  begin
    # 检查迁移是否已经存在
    existing = ActiveRecord::SchemaMigration.find_by(version: version)
    
    if existing
      puts "迁移 #{version} 已存在，跳过"
    else
      # 手动插入迁移记录
      ActiveRecord::Base.connection.execute(
        "INSERT INTO schema_migrations (version) VALUES ('#{version}')"
      )
      puts "✓ 已标记迁移 #{version} 为完成"
    end
  rescue => e
    puts "✗ 处理迁移 #{version} 失败: #{e.message}"
  end
end

puts ""
puts "现在尝试运行剩余的迁移..."

# 尝试运行迁移
begin
  ActiveRecord::Migrator.migrate(ActiveRecord::Migrator.migrations_paths)
  puts "✓ 迁移完成"
rescue => e
  puts "✗ 迁移失败: #{e.message}"
end

puts ""
puts "检查迁移状态..."
puts `bundle exec rails db:migrate:status`
