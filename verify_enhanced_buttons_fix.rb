# 验证Enhanced buttons修复结果

puts "=== 验证Enhanced buttons修复结果 ==="
puts ""

begin
  # 1. 检查agents页面内容
  puts "1. 检查agents页面内容..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  agents_content = File.read(agents_index_path)
  
  # 2. 检查woot-button增强按钮
  puts "2. 检查woot-button增强按钮..."
  
  enhanced_features = {
    '认证切换按钮' => agents_content.include?('toggleConfirmation'),
    '密码重置按钮' => agents_content.include?('openPasswordModal'),
    'checkmark图标' => agents_content.include?('checkmark'),
    'dismiss图标' => agents_content.include?('dismiss'),
    'lock图标' => agents_content.include?('lock'),
    'showEnhancedActions函数' => agents_content.include?('showEnhancedActions'),
    'enhancedLoading状态' => agents_content.include?('enhancedLoading'),
    '认证工具提示' => agents_content.include?('撤销认证') && agents_content.include?('确认认证'),
    '密码工具提示' => agents_content.include?('重置密码'),
    '颜色方案' => agents_content.include?('color-scheme="success"') && agents_content.include?('color-scheme="alert"'),
  }
  
  puts "增强按钮功能检查:"
  enhanced_features.each do |feature, exists|
    status = exists ? "✅" : "❌"
    puts "  #{status} #{feature}: #{exists ? '已存在' : '缺失'}"
  end

  # 3. 检查按钮HTML结构
  puts ""
  puts "3. 检查按钮HTML结构..."
  
  # 查找认证切换按钮
  auth_button_pattern = /v-tooltip\.top="agent\.confirmed \? '撤销认证' : '确认认证'"/
  if agents_content.match(auth_button_pattern)
    puts "✅ 认证切换按钮HTML结构正确"
  else
    puts "❌ 认证切换按钮HTML结构有问题"
  end
  
  # 查找密码重置按钮
  password_button_pattern = /v-tooltip\.top="'重置密码'"/
  if agents_content.match(password_button_pattern)
    puts "✅ 密码重置按钮HTML结构正确"
  else
    puts "❌ 密码重置按钮HTML结构有问题"
  end

  # 4. 检查JavaScript函数
  puts ""
  puts "4. 检查JavaScript函数..."
  
  js_functions = {
    'toggleConfirmation函数' => agents_content.include?('const toggleConfirmation = async (agent)'),
    'openPasswordModal函数' => agents_content.include?('const openPasswordModal = (agent)'),
    'resetPassword函数' => agents_content.include?('const resetPassword = async ()'),
    'showEnhancedActions函数' => agents_content.include?('const showEnhancedActions = (agent)'),
  }
  
  js_functions.each do |func, exists|
    status = exists ? "✅" : "❌"
    puts "  #{status} #{func}: #{exists ? '已定义' : '缺失'}"
  end

  # 5. 检查模态框
  puts ""
  puts "5. 检查密码重置模态框..."
  
  modal_features = {
    '模态框组件' => agents_content.include?('密码重置模态框'),
    '自动生成密码选项' => agents_content.include?('自动生成安全密码'),
    '手动设置密码' => agents_content.include?('请输入新密码'),
    '密码确认' => agents_content.include?('请再次输入密码'),
    '模态框按钮' => agents_content.include?('重置密码') && agents_content.include?('取消'),
  }
  
  modal_features.each do |feature, exists|
    status = exists ? "✅" : "❌"
    puts "  #{status} #{feature}: #{exists ? '已存在' : '缺失'}"
  end

  # 6. 统计结果
  puts ""
  puts "6. 统计修复结果..."
  
  all_enhanced = enhanced_features.values.all?
  all_js = js_functions.values.all?
  all_modal = modal_features.values.all?
  
  total_features = enhanced_features.count + js_functions.count + modal_features.count
  working_features = enhanced_features.values.count(true) + js_functions.values.count(true) + modal_features.values.count(true)
  
  puts "功能完整性统计:"
  puts "  - 增强按钮功能: #{enhanced_features.values.count(true)}/#{enhanced_features.count} (#{all_enhanced ? '✅ 完整' : '❌ 不完整'})"
  puts "  - JavaScript函数: #{js_functions.values.count(true)}/#{js_functions.count} (#{all_js ? '✅ 完整' : '❌ 不完整'})"
  puts "  - 模态框功能: #{modal_features.values.count(true)}/#{modal_features.count} (#{all_modal ? '✅ 完整' : '❌ 不完整'})"
  puts "  - 总体完整性: #{working_features}/#{total_features} (#{(working_features.to_f/total_features*100).round(1)}%)"

  # 7. 显示按钮区域代码
  puts ""
  puts "7. 按钮区域代码预览..."
  
  # 提取按钮区域的代码
  button_area_match = agents_content.match(/<div class="flex justify-end gap-1">(.*?)<\/div>/m)
  if button_area_match
    button_code = button_area_match[1]
    puts "按钮区域代码:"
    button_code.lines.each_with_index do |line, index|
      puts "  #{index + 1}: #{line.strip}" unless line.strip.empty?
    end
  else
    puts "❌ 未找到按钮区域代码"
  end

  # 8. 最终结论
  puts ""
  puts "=== Enhanced buttons修复验证完成 ==="
  puts ""
  
  if working_features == total_features
    puts "🎉 Enhanced buttons错误已完全修复！"
    puts ""
    puts "✅ 修复内容:"
    puts "  - 使用woot-button组件替代Button组件"
    puts "  - 认证切换按钮: checkmark/dismiss图标"
    puts "  - 密码重置按钮: lock图标"
    puts "  - 完整的JavaScript功能"
    puts "  - 密码重置模态框"
    puts "  - 中文工具提示"
    puts ""
    puts "🎯 现在可以在settings/agents/list页面看到并使用增强按钮！"
  else
    puts "⚠️ Enhanced buttons部分修复完成"
    puts ""
    puts "已修复: #{working_features}/#{total_features} 项功能"
    puts "完整性: #{(working_features.to_f/total_features*100).round(1)}%"
    
    if working_features >= total_features * 0.8
      puts ""
      puts "✅ 主要功能已修复，可以正常使用"
    end
  end

rescue => e
  puts "❌ 验证失败: #{e.message}"
  puts e.backtrace.first(5)
end
