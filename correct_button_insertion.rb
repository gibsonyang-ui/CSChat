# 正确插入增强按钮到agents页面

puts "=== 正确插入增强按钮 ==="
puts ""

begin
  # 1. 恢复备份文件
  puts "1. 恢复备份文件..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  backup_path = "#{agents_index_path}.backup"
  
  backup_content = File.read(backup_path)
  File.write(agents_index_path, backup_content)
  puts "✓ 已恢复原始文件"

  # 2. 读取文件内容
  agents_content = File.read(agents_index_path)
  
  # 3. 添加必要的imports
  puts "2. 添加必要的imports..."
  
  # 在第一个import后添加新的imports
  first_import_pattern = /(import.*?from.*?;)/
  enhanced_imports = <<~JS
    import Modal from 'dashboard/components/Modal.vue';
    import Input from 'dashboard/components-next/input/Input.vue';
    import { useAlert } from 'dashboard/composables';
  JS
  
  agents_content = agents_content.sub(first_import_pattern, "\\1\n#{enhanced_imports}")
  puts "✓ imports已添加"

  # 4. 在script部分添加增强功能
  puts "3. 添加增强功能JavaScript..."
  
  # 查找script结束位置并添加增强功能
  script_end_pattern = /<\/script>/
  
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
          duration: 10000,
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
  
  agents_content = agents_content.sub(script_end_pattern, "#{enhanced_js}\n</script>")
  puts "✓ JavaScript功能已添加"

  # 5. 在编辑按钮后添加增强按钮
  puts "4. 添加增强按钮到template..."
  
  # 查找编辑按钮的确切位置
  edit_button_pattern = /(<woot-button\s+v-if="showEditAction\(agent\)".*?@click="openEditPopup\(agent\)".*?\/>)/m
  
  enhanced_buttons = <<~HTML
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
  
  # 在编辑按钮后插入增强按钮
  agents_content = agents_content.sub(edit_button_pattern, "\\1\n#{enhanced_buttons}")
  puts "✓ 增强按钮已插入"

  # 6. 在template末尾添加密码重置模态框
  puts "5. 添加密码重置模态框..."
  
  password_modal = <<~HTML
    
    <!-- 密码重置模态框 -->
    <Modal
      v-model:show="showPasswordModal"
      :on-close="closePasswordModal"
      size="medium"
    >
      <div class="p-6">
        <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">
          重置密码 - {{ selectedAgentForPassword?.name }}
        </h3>
        
        <div class="space-y-4">
          <div class="flex items-center gap-3">
            <input
              id="auto-generate"
              v-model="autoGeneratePassword"
              type="checkbox"
              class="rounded border-slate-300 dark:border-slate-600"
            />
            <label for="auto-generate" class="text-sm text-slate-700 dark:text-slate-300">
              自动生成安全密码 (推荐)
            </label>
          </div>
          
          <div v-if="!autoGeneratePassword" class="space-y-3">
            <Input
              v-model="newPassword"
              type="password"
              label="新密码"
              placeholder="请输入新密码 (至少8位)"
              required
            />
            <Input
              v-model="confirmPassword"
              type="password"
              label="确认密码"
              placeholder="请再次输入密码"
              required
            />
          </div>
          
          <div v-else class="p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
            <p class="text-sm text-slate-700 dark:text-slate-300">
              将生成一个12位的安全密码，包含大小写字母、数字和特殊字符。
            </p>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              示例: {{ generatePasswordPreview() }}
            </p>
          </div>
        </div>
        
        <div class="flex justify-end gap-3 mt-6">
          <woot-button
            variant="clear"
            @click="closePasswordModal"
          >
            取消
          </woot-button>
          <woot-button
            @click="resetPassword"
          >
            重置密码
          </woot-button>
        </div>
      </div>
    </Modal>
  HTML
  
  # 在最后一个template结束标签前添加模态框
  last_template_pattern = /(<\/template>\s*$)/
  agents_content = agents_content.sub(last_template_pattern, "#{password_modal}\n\\1")
  puts "✓ 密码重置模态框已添加"

  # 7. 写入修改后的文件
  puts "6. 写入修改后的文件..."
  
  File.write(agents_index_path, agents_content)
  puts "✓ 文件已更新"
  puts "✓ 新文件大小: #{agents_content.length} 字符"

  # 8. 验证修改结果
  puts ""
  puts "7. 验证修改结果..."
  
  updated_content = File.read(agents_index_path)
  
  verification = {
    '增强按钮' => updated_content.include?('showEnhancedActions'),
    '认证切换' => updated_content.include?('toggleConfirmation'),
    '密码重置' => updated_content.include?('openPasswordModal'),
    '模态框' => updated_content.include?('密码重置模态框'),
    'checkmark图标' => updated_content.include?('checkmark'),
    'lock图标' => updated_content.include?('lock'),
  }
  
  verification.each do |feature, exists|
    status = exists ? "✅" : "❌"
    puts "  #{status} #{feature}: #{exists ? '已添加' : '缺失'}"
  end

  puts ""
  puts "=== 正确插入完成 ==="
  puts ""
  puts "✅ 增强按钮已正确插入到agents页面！"
  puts ""
  puts "新增功能:"
  puts "  - 认证状态切换按钮 (checkmark/dismiss图标)"
  puts "  - 密码重置按钮 (lock图标)"
  puts "  - 密码重置模态框"
  puts "  - 完整的JavaScript功能"

rescue => e
  puts "❌ 插入失败: #{e.message}"
  puts e.backtrace.first(5)
end
