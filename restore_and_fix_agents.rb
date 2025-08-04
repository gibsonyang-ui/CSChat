# 恢复备份文件并正确添加增强功能

puts "=== 恢复备份文件并正确添加增强功能 ==="
puts ""

begin
  # 1. 恢复备份文件
  puts "1. 恢复备份文件..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  backup_path = "#{agents_index_path}.backup"
  
  if File.exist?(backup_path)
    backup_content = File.read(backup_path)
    File.write(agents_index_path, backup_content)
    puts "✓ 已从备份恢复原始文件"
    puts "✓ 文件大小: #{backup_content.length} 字符"
  else
    puts "❌ 备份文件不存在"
    exit 1
  end

  # 2. 读取恢复后的文件
  puts ""
  puts "2. 分析原始文件结构..."
  
  agents_content = File.read(agents_index_path)
  
  # 检查文件结构
  script_count = agents_content.scan(/<script/).count
  template_count = agents_content.scan(/<template/).count
  
  puts "✓ script标签数量: #{script_count}"
  puts "✓ template标签数量: #{template_count}"
  
  if script_count != 1 || template_count != 1
    puts "❌ 文件结构异常"
    exit 1
  end

  # 3. 查找真正的按钮区域
  puts ""
  puts "3. 查找真正的按钮区域..."
  
  # 查找所有包含woot-button的行
  button_lines = []
  agents_content.lines.each_with_index do |line, index|
    if line.include?('woot-button')
      button_lines << "#{index + 1}: #{line.strip}"
    end
  end
  
  puts "找到的按钮行:"
  button_lines.each { |line| puts "  #{line}" }

  # 4. 查找操作列的正确位置
  puts ""
  puts "4. 查找操作列位置..."
  
  # 查找表格中的操作列
  td_lines = []
  agents_content.lines.each_with_index do |line, index|
    if line.include?('<td') && (line.include?('py-4') || line.include?('操作') || line.include?('actions'))
      td_lines << "#{index + 1}: #{line.strip}"
    end
  end
  
  puts "找到的td行:"
  td_lines.each { |line| puts "  #{line}" }

  # 5. 在script部分添加增强功能
  puts ""
  puts "5. 在script部分添加增强功能..."
  
  # 查找script结束位置
  script_end_pattern = /<\/script>/
  script_end_match = agents_content.match(script_end_pattern)
  
  if script_end_match
    puts "✓ 找到script结束位置"
    
    # 准备增强功能的JavaScript代码
    enhanced_js = <<~JS
      
      // Enhanced features for user management
      const { showAlert } = useAlert();
      const showPasswordModal = ref(false);
      const selectedAgentForPassword = ref(null);
      const newPassword = ref('');
      const confirmPassword = ref('');
      const autoGeneratePassword = ref(true);
      const enhancedLoading = ref({});

      // Enhanced methods
      const showEnhancedActions = (agent) => {
        return agent.id !== currentUserId.value;
      };

      // 切换认证状态
      const toggleConfirmation = async (agent) => {
        if (enhancedLoading.value[agent.id]) return;
        
        enhancedLoading.value = { ...enhancedLoading.value, [agent.id]: true };
        
        try {
          const response = await fetch(`/api/v1/accounts/${getters.getCurrentAccountId.value}/enhanced_agents/${agent.id}/toggle_confirmation`, {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'X-Auth-Token': getters.getAuthData.value.authToken,
            },
          });

          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const data = await response.json();
          
          // 更新本地状态
          store.dispatch('agents/get');
          
          showAlert({
            type: 'success',
            message: data.message || (agent.confirmed ? '认证已撤销' : '用户已认证'),
          });
        } catch (error) {
          console.error('Toggle confirmation error:', error);
          showAlert({
            type: 'error',
            message: '操作失败: ' + error.message,
          });
        } finally {
          enhancedLoading.value = { ...enhancedLoading.value, [agent.id]: false };
        }
      };

      // 打开密码重置模态框
      const openPasswordModal = (agent) => {
        selectedAgentForPassword.value = agent;
        newPassword.value = '';
        confirmPassword.value = '';
        autoGeneratePassword.value = true;
        showPasswordModal.value = true;
      };

      // 关闭密码重置模态框
      const closePasswordModal = () => {
        showPasswordModal.value = false;
        selectedAgentForPassword.value = null;
        newPassword.value = '';
        confirmPassword.value = '';
      };

      // 重置密码
      const resetPassword = async () => {
        if (!selectedAgentForPassword.value) return;

        if (!autoGeneratePassword.value) {
          if (!newPassword.value || newPassword.value.length < 8) {
            showAlert({
              type: 'error',
              message: '密码长度至少8位',
            });
            return;
          }

          if (newPassword.value !== confirmPassword.value) {
            showAlert({
              type: 'error',
              message: '密码确认不匹配',
            });
            return;
          }
        }

        try {
          const passwordData = autoGeneratePassword.value 
            ? { auto_generate_password: true }
            : { password: newPassword.value, password_confirmation: confirmPassword.value };

          const response = await fetch(`/api/v1/accounts/${getters.getCurrentAccountId.value}/enhanced_agents/${selectedAgentForPassword.value.id}/reset_password`, {
            method: 'PATCH',
            headers: {
              'Content-Type': 'application/json',
              'X-Auth-Token': getters.getAuthData.value.authToken,
            },
            body: JSON.stringify(passwordData),
          });

          if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
          }

          const data = await response.json();
          
          // 更新本地状态
          store.dispatch('agents/get');
          
          showAlert({
            type: 'success',
            message: `密码重置成功！新密码: ${data.password}`,
            duration: 10000, // 显示10秒
          });

          closePasswordModal();
        } catch (error) {
          console.error('Reset password error:', error);
          showAlert({
            type: 'error',
            message: '密码重置失败: ' + error.message,
          });
        }
      };

      // 生成随机密码预览
      const generatePasswordPreview = () => {
        const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
        let password = '';
        for (let i = 0; i < 12; i++) {
          password += chars.charAt(Math.floor(Math.random() * chars.length));
        }
        return password;
      };
    JS
    
    # 在script结束标签前插入增强功能
    agents_content = agents_content.sub(script_end_pattern, "#{enhanced_js}\n</script>")
    puts "✓ 增强JavaScript功能已添加"
  else
    puts "❌ 未找到script结束位置"
    exit 1
  end

  # 6. 添加必要的imports
  puts ""
  puts "6. 添加必要的imports..."
  
  # 查找import部分并添加Modal和Input
  import_pattern = /(import.*?from.*?;)/
  if agents_content.match(import_pattern)
    enhanced_imports = <<~JS
      import Modal from 'dashboard/components/Modal.vue';
      import Input from 'dashboard/components-next/input/Input.vue';
      import { useAlert } from 'dashboard/composables';
    JS
    
    # 在第一个import后添加
    agents_content = agents_content.sub(import_pattern, "\\1\n#{enhanced_imports}")
    puts "✓ 必要的imports已添加"
  end

  # 7. 写入修改后的文件
  puts ""
  puts "7. 写入修改后的文件..."
  
  File.write(agents_index_path, agents_content)
  puts "✓ 文件已更新"
  puts "✓ 新文件大小: #{agents_content.length} 字符"

  puts ""
  puts "=== 恢复和修复完成 ==="
  puts ""
  puts "✅ 已恢复原始文件并添加增强功能的JavaScript部分"
  puts ""
  puts "下一步需要:"
  puts "1. 找到正确的按钮插入位置"
  puts "2. 添加增强按钮到template部分"
  puts "3. 添加密码重置模态框"

rescue => e
  puts "❌ 恢复和修复失败: #{e.message}"
  puts e.backtrace.first(5)
end
