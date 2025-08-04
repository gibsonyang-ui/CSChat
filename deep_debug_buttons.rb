# 深度调试按钮显示问题

puts "=== 深度调试按钮显示问题 ==="
puts ""

begin
  # 1. 检查当前agents页面的完整结构
  puts "1. 检查agents页面完整结构..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  agents_content = File.read(agents_index_path)
  
  puts "✓ 文件大小: #{agents_content.length} 字符"
  puts "✓ 行数: #{agents_content.lines.count}"

  # 2. 查找所有按钮相关的代码
  puts ""
  puts "2. 查找所有按钮相关代码..."
  
  # 查找所有woot-button
  woot_buttons = agents_content.scan(/<woot-button[^>]*>.*?<\/woot-button>/m)
  puts "找到 #{woot_buttons.count} 个woot-button组件"
  
  woot_buttons.each_with_index do |button, index|
    puts "  按钮 #{index + 1}:"
    # 提取关键属性
    icon_match = button.match(/icon="([^"]*)"/)
    tooltip_match = button.match(/v-tooltip\.top="([^"]*)"/)
    click_match = button.match(/@click="([^"]*)"/)
    
    puts "    图标: #{icon_match ? icon_match[1] : '无'}"
    puts "    提示: #{tooltip_match ? tooltip_match[1] : '无'}"
    puts "    点击: #{click_match ? click_match[1] : '无'}"
  end

  # 3. 检查表格结构
  puts ""
  puts "3. 检查表格结构..."
  
  # 查找表格行
  table_rows = agents_content.scan(/<tr[^>]*>.*?<\/tr>/m)
  puts "找到 #{table_rows.count} 个表格行"
  
  # 查找操作列
  action_columns = agents_content.scan(/<td[^>]*class="py-4"[^>]*>.*?<\/td>/m)
  puts "找到 #{action_columns.count} 个操作列"

  # 4. 检查Vue组件的script部分
  puts ""
  puts "4. 检查Vue组件script部分..."
  
  # 查找script标签内容
  script_match = agents_content.match(/<script[^>]*>(.*?)<\/script>/m)
  if script_match
    script_content = script_match[1]
    puts "✓ 找到script部分"
    
    # 检查关键函数
    functions_to_check = [
      'showEnhancedActions',
      'toggleConfirmation',
      'openPasswordModal',
      'resetPassword',
      'enhancedLoading'
    ]
    
    functions_to_check.each do |func|
      if script_content.include?(func)
        puts "  ✓ #{func}: 已定义"
      else
        puts "  ❌ #{func}: 缺失"
      end
    end
  else
    puts "❌ 未找到script部分"
  end

  # 5. 检查template部分的具体结构
  puts ""
  puts "5. 检查template部分具体结构..."
  
  # 查找template标签
  template_match = agents_content.match(/<template[^>]*>(.*?)<\/template>/m)
  if template_match
    template_content = template_match[1]
    puts "✓ 找到template部分"
    
    # 查找操作按钮区域
    button_area_match = template_content.match(/<div class="flex justify-end gap-1">(.*?)<\/div>/m)
    if button_area_match
      button_area = button_area_match[1]
      puts "✓ 找到按钮区域"
      puts "按钮区域内容:"
      button_area.lines.each_with_index do |line, index|
        puts "    #{index + 1}: #{line.strip}" unless line.strip.empty?
      end
    else
      puts "❌ 未找到按钮区域"
      
      # 查找其他可能的按钮容器
      puts "查找其他按钮容器..."
      flex_divs = template_content.scan(/<div[^>]*class="[^"]*flex[^"]*"[^>]*>/)
      puts "找到 #{flex_divs.count} 个flex容器"
      flex_divs.each_with_index do |div, index|
        puts "  #{index + 1}: #{div}"
      end
    end
  else
    puts "❌ 未找到template部分"
  end

  # 6. 检查文件是否被正确修改
  puts ""
  puts "6. 检查文件修改时间..."
  
  file_stat = File.stat(agents_index_path)
  puts "✓ 最后修改时间: #{file_stat.mtime}"
  puts "✓ 文件权限: #{file_stat.mode.to_s(8)}"

  # 7. 检查备份文件对比
  puts ""
  puts "7. 检查备份文件对比..."
  
  backup_path = "#{agents_index_path}.backup"
  if File.exist?(backup_path)
    backup_content = File.read(backup_path)
    puts "✓ 备份文件存在"
    puts "✓ 备份文件大小: #{backup_content.length} 字符"
    puts "✓ 当前文件大小: #{agents_content.length} 字符"
    puts "✓ 大小差异: #{agents_content.length - backup_content.length} 字符"
    
    if agents_content.length > backup_content.length
      puts "✓ 文件已被修改 (增加了内容)"
    elsif agents_content.length == backup_content.length
      puts "⚠ 文件大小相同，可能修改未生效"
    else
      puts "❌ 文件变小了，可能有问题"
    end
  else
    puts "❌ 备份文件不存在"
  end

  # 8. 检查是否有语法错误
  puts ""
  puts "8. 检查Vue文件语法..."
  
  # 检查基本的Vue语法
  syntax_checks = {
    '缺少script结束标签' => !agents_content.include?('</script>'),
    '缺少template结束标签' => !agents_content.include?('</template>'),
    '未配对的引号' => agents_content.count('"') % 2 != 0,
    '未配对的单引号' => agents_content.count("'") % 2 != 0,
  }
  
  syntax_checks.each do |check, has_error|
    status = has_error ? "❌" : "✓"
    puts "  #{status} #{check}: #{has_error ? '有问题' : '正常'}"
  end

  # 9. 生成当前文件的关键部分摘要
  puts ""
  puts "9. 生成文件关键部分摘要..."
  
  # 查找关键行
  key_lines = []
  agents_content.lines.each_with_index do |line, index|
    if line.include?('woot-button') || 
       line.include?('showEnhancedActions') || 
       line.include?('toggleConfirmation') || 
       line.include?('openPasswordModal') ||
       line.include?('enhancedLoading')
      key_lines << "#{index + 1}: #{line.strip}"
    end
  end
  
  puts "关键代码行 (#{key_lines.count}行):"
  key_lines.each { |line| puts "  #{line}" }

  # 10. 检查可能的问题
  puts ""
  puts "10. 可能的问题分析..."
  
  possible_issues = []
  
  # 检查是否有增强按钮
  if !agents_content.include?('showEnhancedActions')
    possible_issues << "showEnhancedActions函数缺失"
  end
  
  if !agents_content.include?('toggleConfirmation')
    possible_issues << "toggleConfirmation函数缺失"
  end
  
  if !agents_content.include?('checkmark') && !agents_content.include?('dismiss')
    possible_issues << "增强按钮图标缺失"
  end
  
  if agents_content.scan(/<woot-button/).count < 3
    possible_issues << "按钮数量不足 (应该至少有3个)"
  end
  
  if possible_issues.any?
    puts "发现的问题:"
    possible_issues.each { |issue| puts "  ❌ #{issue}" }
  else
    puts "✓ 未发现明显问题"
  end

  puts ""
  puts "=== 深度调试完成 ==="
  puts ""
  puts "请检查以上信息，特别关注:"
  puts "1. 按钮区域内容是否包含增强按钮"
  puts "2. script部分是否包含所有必要函数"
  puts "3. 是否有语法错误"
  puts "4. 文件是否被正确修改"

rescue => e
  puts "❌ 调试失败: #{e.message}"
  puts e.backtrace.first(5)
end
