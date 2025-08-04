# 修复woot-button组件的增强按钮

puts "=== 修复woot-button组件的增强按钮 ==="
puts ""

begin
  # 1. 读取当前agents页面
  puts "1. 读取当前agents页面..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  agents_content = File.read(agents_index_path)
  puts "✓ agents页面已读取"

  # 2. 查找woot-button区域
  puts "2. 查找woot-button区域..."
  
  # 查找编辑按钮的位置
  edit_button_pattern = /(<woot-button\s+v-if="showEditAction\(agent\)".*?@click="openEditPopup\(agent\)".*?\/>)/m
  
  if agents_content.match(edit_button_pattern)
    puts "✓ 找到编辑按钮位置"
  else
    puts "❌ 未找到编辑按钮"
    exit 1
  end

  # 3. 定义增强按钮（使用woot-button组件）
  puts "3. 定义增强按钮..."
  
  enhanced_woot_buttons = <<~HTML
                <woot-button
                  v-if="showEnhancedActions(agent)"
                  v-tooltip.top="agent.confirmed ? '撤销认证' : '确认认证'"
                  variant="smooth"
                  size="tiny"
                  :color-scheme="agent.confirmed ? 'alert' : 'success'"
                  :icon="agent.confirmed ? 'dismiss' : 'checkmark'"
                  class-names="grey-btn"
                  :is-loading="enhancedLoading[agent.id]"
                  @click="toggleConfirmation(agent)"
                />
                
                <woot-button
                  v-if="showEnhancedActions(agent)"
                  v-tooltip.top="'重置密码'"
                  variant="smooth"
                  size="tiny"
                  color-scheme="secondary"
                  icon="lock"
                  class-names="grey-btn"
                  @click="openPasswordModal(agent)"
                />
  HTML

  # 4. 在编辑按钮后插入增强按钮
  puts "4. 插入增强按钮..."
  
  agents_content = agents_content.sub(edit_button_pattern, "\\1\n#{enhanced_woot_buttons}")
  puts "✓ 增强按钮已插入"

  # 5. 确保所有必要的函数都存在
  puts "5. 检查必要函数..."
  
  # 检查showEnhancedActions函数
  if !agents_content.include?('showEnhancedActions')
    puts "添加showEnhancedActions函数..."
    
    show_enhanced_function = <<~JS
      
      const showEnhancedActions = (agent) => {
        return agent.id !== currentUserId.value;
      };
    JS
    
    # 在showDeleteAction函数后添加
    agents_content = agents_content.sub(
      /(const showDeleteAction.*?;)/m,
      "\\1#{show_enhanced_function}"
    )
    puts "✓ showEnhancedActions函数已添加"
  else
    puts "✓ showEnhancedActions函数已存在"
  end

  # 检查enhancedLoading状态
  if !agents_content.include?('enhancedLoading')
    puts "添加enhancedLoading状态..."
    
    # 在其他ref定义附近添加
    enhanced_loading_ref = "const enhancedLoading = ref({});"
    
    # 查找其他ref定义并在其后添加
    if agents_content.include?('const loading = ref')
      agents_content = agents_content.sub(
        /(const loading = ref.*?;)/m,
        "\\1\n  #{enhanced_loading_ref}"
      )
      puts "✓ enhancedLoading状态已添加"
    end
  else
    puts "✓ enhancedLoading状态已存在"
  end

  # 6. 写入修复后的文件
  puts "6. 写入修复后的文件..."
  
  File.write(agents_index_path, agents_content)
  puts "✓ agents页面已更新"

  # 7. 验证修复结果
  puts "7. 验证修复结果..."
  
  updated_content = File.read(agents_index_path)
  
  verification = {
    '认证切换按钮' => updated_content.include?('toggleConfirmation'),
    '密码重置按钮' => updated_content.include?('openPasswordModal'),
    'showEnhancedActions函数' => updated_content.include?('showEnhancedActions'),
    'enhancedLoading状态' => updated_content.include?('enhancedLoading'),
    '认证图标' => updated_content.include?('checkmark') && updated_content.include?('dismiss'),
    '密码图标' => updated_content.include?('lock'),
  }
  
  puts "验证结果:"
  verification.each do |feature, exists|
    status = exists ? "✓" : "❌"
    puts "  #{status} #{feature}: #{exists ? '已存在' : '缺失'}"
  end

  all_good = verification.values.all?
  
  if all_good
    puts ""
    puts "✅ woot-button增强按钮修复完成！"
    puts ""
    puts "新增按钮:"
    puts "  - 认证状态切换: checkmark/dismiss 图标"
    puts "  - 密码重置: lock 图标"
    puts "  - 颜色方案: success/alert/secondary"
    puts "  - 工具提示: 中文说明"
  else
    puts ""
    puts "❌ 仍有部分功能缺失"
  end

  # 8. 显示按钮区域的最终内容
  puts ""
  puts "8. 按钮区域最终内容预览:"
  
  button_section = updated_content.scan(/(<div class="flex justify-end gap-1">.*?<\/div>)/m).first
  if button_section
    puts button_section[0].lines.each_with_index.map { |line, i| "  #{i+1}: #{line.strip}" }.join("\n")
  end

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
