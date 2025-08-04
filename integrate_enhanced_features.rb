# 将增强功能集成到现有的agents页面

puts "=== 集成增强功能到agents页面 ==="
puts ""

begin
  # 1. 读取现有的agents页面
  puts "1. 读取现有agents页面..."
  
  agents_index_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue'
  if File.exist?(agents_index_path)
    agents_content = File.read(agents_index_path)
    puts "✓ 现有agents页面已读取"
  else
    puts "❌ agents页面文件不存在"
    exit 1
  end

  # 2. 备份原文件
  puts "2. 备份原文件..."
  backup_path = "#{agents_index_path}.backup"
  File.write(backup_path, agents_content)
  puts "✓ 原文件已备份到: #{backup_path}"

  # 3. 在script部分添加增强功能
  puts "3. 添加增强功能到script部分..."
  
  # 在imports部分添加新的导入
  enhanced_imports = <<~JS
    import Modal from 'dashboard/components/Modal.vue';
    import Input from 'dashboard/components-next/input/Input.vue';
    import { useAlert } from 'dashboard/composables';
  JS
  
  # 在setup函数中添加增强功能的状态和方法
  enhanced_setup = <<~JS
    
    // Enhanced features
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
        const response = await fetch(`/api/v1/accounts/${store.getters.getCurrentAccountId}/enhanced_agents/${agent.id}/toggle_confirmation`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-Auth-Token': store.getters.getAuthData.authToken,
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

        const response = await fetch(`/api/v1/accounts/${store.getters.getCurrentAccountId}/enhanced_agents/${selectedAgentForPassword.value.id}/reset_password`, {
          method: 'PATCH',
          headers: {
            'Content-Type': 'application/json',
            'X-Auth-Token': store.getters.getAuthData.authToken,
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

  # 修改agents_content以添加增强功能
  # 首先添加导入
  agents_content = agents_content.sub(
    /(import.*?from.*?;)/m,
    "\\1\n#{enhanced_imports}"
  )

  # 在setup函数末尾添加增强功能
  agents_content = agents_content.sub(
    /(const deleteMessage.*?;)/m,
    "\\1#{enhanced_setup}"
  )

  puts "✓ Script部分增强功能已添加"

  # 4. 修改template部分，添加增强按钮
  puts "4. 修改template部分..."
  
  # 在操作按钮区域添加增强按钮
  enhanced_buttons = <<~HTML
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

  # 在现有按钮前添加增强按钮
  agents_content = agents_content.sub(
    /(<Button\s+v-if="showDeleteAction\(agent\))/m,
    "#{enhanced_buttons}\n                \\1"
  )

  # 5. 添加密码重置模态框
  puts "5. 添加密码重置模态框..."
  
  password_modal = <<~HTML
    
    <!-- 密码重置模态框 -->
    <Modal
      v-model:show="showPasswordModal"
      :on-close="closePasswordModal"
      size="medium"
    >
      <div class="p-6">
        <h3 class="text-lg font-medium text-n-slate-12 mb-4">
          重置密码 - {{ selectedAgentForPassword?.name }}
        </h3>
        
        <div class="space-y-4">
          <div class="flex items-center gap-3">
            <input
              id="auto-generate"
              v-model="autoGeneratePassword"
              type="checkbox"
              class="rounded border-n-weak"
            />
            <label for="auto-generate" class="text-sm text-n-slate-11">
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
          
          <div v-else class="p-3 bg-n-slate-2 rounded-lg">
            <p class="text-sm text-n-slate-11">
              将生成一个12位的安全密码，包含大小写字母、数字和特殊字符。
            </p>
            <p class="text-xs text-n-slate-10 mt-1">
              示例: {{ generatePasswordPreview() }}
            </p>
          </div>
        </div>
        
        <div class="flex justify-end gap-3 mt-6">
          <Button
            label="取消"
            slate
            @click="closePasswordModal"
          />
          <Button
            label="重置密码"
            @click="resetPassword"
          />
        </div>
      </div>
    </Modal>
  HTML

  # 在template末尾添加模态框
  agents_content = agents_content.sub(
    /(<\/template>\s*$)/m,
    "#{password_modal}\n\\1"
  )

  puts "✓ Template部分增强功能已添加"

  # 6. 写入修改后的文件
  puts "6. 写入修改后的文件..."
  File.write(agents_index_path, agents_content)
  puts "✓ agents页面已更新"

  puts ""
  puts "=== 增强功能集成完成 ==="
  puts ""
  puts "✅ 修改的文件:"
  puts "  - #{agents_index_path}"
  puts "  - 备份: #{backup_path}"
  puts ""
  puts "✅ 新增功能:"
  puts "  - 切换用户认证状态按钮 (用户图标)"
  puts "  - 密码重置按钮 (钥匙图标)"
  puts "  - 密码重置模态框"
  puts "  - 自动生成安全密码"
  puts "  - 手动设置密码"
  puts "  - 实时状态反馈"
  puts ""
  puts "现在需要热更新以使更改生效"

rescue => e
  puts "❌ 集成增强功能失败: #{e.message}"
  puts e.backtrace.first(5)
end
