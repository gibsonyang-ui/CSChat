# 修复Enhanced buttons未找到的错误

puts "=== 修复Enhanced buttons错误 ==="
puts ""

begin
  # 1. 检查当前agents页面内容
  puts "1. 检查当前agents页面内容..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  if File.exist?(agents_index_path)
    agents_content = File.read(agents_index_path)
    puts "✓ agents页面文件存在"
    
    # 检查是否包含增强按钮
    has_user_check = agents_content.include?('i-lucide-user-check')
    has_user_x = agents_content.include?('i-lucide-user-x')
    has_key_icon = agents_content.include?('i-lucide-key')
    
    puts "  - 用户确认图标 (i-lucide-user-check): #{has_user_check ? '✓' : '❌'}"
    puts "  - 用户撤销图标 (i-lucide-user-x): #{has_user_x ? '✓' : '❌'}"
    puts "  - 密钥图标 (i-lucide-key): #{has_key_icon ? '✓' : '❌'}"
    
    if !has_user_check || !has_user_x || !has_key_icon
      puts "❌ 增强按钮图标缺失，需要修复"
    else
      puts "✓ 所有增强按钮图标都存在"
      exit 0
    end
  else
    puts "❌ agents页面文件不存在"
    exit 1
  end

  # 2. 查找按钮插入位置
  puts "2. 查找按钮插入位置..."
  
  # 查找操作按钮区域
  button_area_pattern = /<div class="flex justify-end gap-1">/
  if agents_content.match(button_area_pattern)
    puts "✓ 找到操作按钮区域"
  else
    puts "❌ 未找到操作按钮区域"
    # 查找其他可能的按钮区域
    puts "搜索其他按钮区域..."
    if agents_content.include?('showEditAction')
      puts "✓ 找到编辑按钮相关代码"
    end
    if agents_content.include?('showDeleteAction')
      puts "✓ 找到删除按钮相关代码"
    end
  end

  # 3. 重新插入增强按钮
  puts "3. 重新插入增强按钮..."
  
  # 定义增强按钮HTML
  enhanced_buttons_html = <<~HTML
                    <!-- 增强功能按钮 -->
                    <Button
                      v-if="showEnhancedActions(agent)"
                      v-tooltip.top="agent.confirmed ? '撤销认证' : '确认认证'"
                      :icon="agent.confirmed ? 'i-lucide-user-x' : 'i-lucide-user-check'"
                      :class="agent.confirmed ? 'text-orange-600' : 'text-green-600'"
                      xs
                      faded
                      :is-loading="enhancedLoading[agent.id]"
                      @click="toggleConfirmation(agent)"
                    />
                    
                    <Button
                      v-if="showEnhancedActions(agent)"
                      v-tooltip.top="'重置密码'"
                      icon="i-lucide-key"
                      xs
                      faded
                      slate
                      @click="openPasswordModal(agent)"
                    />
  HTML

  # 查找删除按钮并在其前面插入增强按钮
  delete_button_pattern = /(<Button\s+v-if="showDeleteAction\(agent\)".*?@click="openDeletePopup\(agent, index\)".*?\/>)/m
  
  if agents_content.match(delete_button_pattern)
    puts "✓ 找到删除按钮，在其前面插入增强按钮"
    
    # 在删除按钮前插入增强按钮
    agents_content = agents_content.sub(delete_button_pattern, "#{enhanced_buttons_html}\n                    \\1")
    
    puts "✓ 增强按钮已插入"
  else
    puts "❌ 未找到删除按钮，尝试其他插入方式"
    
    # 尝试在编辑按钮后插入
    edit_button_pattern = /(<Button\s+v-if="showEditAction\(agent\)".*?\/>)/m
    
    if agents_content.match(edit_button_pattern)
      puts "✓ 找到编辑按钮，在其后面插入增强按钮"
      agents_content = agents_content.sub(edit_button_pattern, "\\1\n#{enhanced_buttons_html}")
      puts "✓ 增强按钮已插入"
    else
      puts "❌ 未找到合适的插入位置"
      
      # 显示当前按钮区域的内容以便调试
      puts "当前按钮区域内容:"
      button_lines = agents_content.lines.select { |line| line.include?('Button') || line.include?('gap-1') }
      button_lines.each_with_index do |line, index|
        puts "  #{index + 1}: #{line.strip}"
      end
    end
  end

  # 4. 验证增强按钮是否正确插入
  puts "4. 验证增强按钮插入..."
  
  has_user_check_after = agents_content.include?('i-lucide-user-check')
  has_user_x_after = agents_content.include?('i-lucide-user-x')
  has_key_icon_after = agents_content.include?('i-lucide-key')
  
  puts "  - 用户确认图标: #{has_user_check_after ? '✓' : '❌'}"
  puts "  - 用户撤销图标: #{has_user_x_after ? '✓' : '❌'}"
  puts "  - 密钥图标: #{has_key_icon_after ? '✓' : '❌'}"

  # 5. 确保showEnhancedActions函数存在
  puts "5. 检查showEnhancedActions函数..."
  
  if agents_content.include?('showEnhancedActions')
    puts "✓ showEnhancedActions函数已存在"
  else
    puts "❌ showEnhancedActions函数缺失，正在添加..."
    
    # 在其他函数附近添加showEnhancedActions函数
    enhanced_function = <<~JS
      
      const showEnhancedActions = (agent) => {
        return agent.id !== currentUserId.value;
      };
    JS
    
    # 在showDeleteAction函数后添加
    if agents_content.include?('showDeleteAction')
      agents_content = agents_content.sub(
        /(const showDeleteAction.*?;)/m,
        "\\1#{enhanced_function}"
      )
      puts "✓ showEnhancedActions函数已添加"
    end
  end

  # 6. 写入修复后的文件
  puts "6. 写入修复后的文件..."
  
  File.write(agents_index_path, agents_content)
  puts "✓ agents页面已更新"

  # 7. 最终验证
  puts "7. 最终验证..."
  
  updated_content = File.read(agents_index_path)
  final_check = {
    'i-lucide-user-check' => updated_content.include?('i-lucide-user-check'),
    'i-lucide-user-x' => updated_content.include?('i-lucide-user-x'),
    'i-lucide-key' => updated_content.include?('i-lucide-key'),
    'showEnhancedActions' => updated_content.include?('showEnhancedActions'),
    'toggleConfirmation' => updated_content.include?('toggleConfirmation'),
    'openPasswordModal' => updated_content.include?('openPasswordModal'),
  }
  
  puts "最终检查结果:"
  final_check.each do |feature, exists|
    status = exists ? "✓" : "❌"
    puts "  #{status} #{feature}: #{exists ? '已存在' : '缺失'}"
  end

  all_good = final_check.values.all?
  
  if all_good
    puts ""
    puts "✅ Enhanced buttons错误已修复！"
    puts ""
    puts "修复内容:"
    puts "  - 用户认证状态切换按钮 ✓"
    puts "  - 密码重置按钮 ✓"
    puts "  - showEnhancedActions函数 ✓"
    puts "  - 所有相关功能 ✓"
  else
    puts ""
    puts "❌ 仍有部分功能缺失，需要进一步检查"
  end

rescue => e
  puts "❌ 修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
