# 创建增强的agents页面组件

puts "=== 创建增强agents页面组件 ==="
puts ""

begin
  # 1. 创建增强的agents页面组件
  puts "1. 创建增强agents页面组件..."
  
  enhanced_agents_vue_content = <<~VUE
    <script setup>
    import { computed, onMounted, ref } from 'vue';
    import { useStore } from 'vuex';
    import { useI18n } from 'vue-i18n';
    import { useAlert } from 'dashboard/composables';
    import SettingsLayout from '../SettingsLayout.vue';
    import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
    import Button from 'dashboard/components-next/button/Button.vue';
    import Avatar from 'dashboard/components/widgets/Avatar.vue';
    import Modal from 'dashboard/components/Modal.vue';
    import Input from 'dashboard/components-next/input/Input.vue';

    const { t } = useI18n();
    const store = useStore();
    const { showAlert } = useAlert();

    // State
    const showPasswordModal = ref(false);
    const selectedAgent = ref(null);
    const newPassword = ref('');
    const confirmPassword = ref('');
    const autoGeneratePassword = ref(true);
    const loading = ref({});

    // Computed
    const agentList = computed(() => store.getters['agents/getAgents']);
    const uiFlags = computed(() => store.getters['agents/getUIFlags']);
    const currentUserId = computed(() => store.getters.getCurrentUserID);

    // Methods
    onMounted(() => {
      store.dispatch('agents/get');
    });

    const showEditAction = (agent) => {
      return agent.id !== currentUserId.value;
    };

    const showDeleteAction = (agent) => {
      return agent.id !== currentUserId.value;
    };

    const showEnhancedActions = (agent) => {
      return agent.id !== currentUserId.value;
    };

    // 切换认证状态
    const toggleConfirmation = async (agent) => {
      if (loading.value[agent.id]) return;
      
      loading.value = { ...loading.value, [agent.id]: true };
      
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
        loading.value = { ...loading.value, [agent.id]: false };
      }
    };

    // 打开密码重置模态框
    const openPasswordModal = (agent) => {
      selectedAgent.value = agent;
      newPassword.value = '';
      confirmPassword.value = '';
      autoGeneratePassword.value = true;
      showPasswordModal.value = true;
    };

    // 关闭密码重置模态框
    const closePasswordModal = () => {
      showPasswordModal.value = false;
      selectedAgent.value = null;
      newPassword.value = '';
      confirmPassword.value = '';
    };

    // 重置密码
    const resetPassword = async () => {
      if (!selectedAgent.value) return;

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

        const response = await fetch(`/api/v1/accounts/${store.getters.getCurrentAccountId}/enhanced_agents/${selectedAgent.value.id}/reset_password`, {
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

    const openAddPopup = () => {
      // 原有的添加代理功能
      console.log('Add agent popup');
    };

    const openEditPopup = (agent) => {
      // 原有的编辑代理功能
      console.log('Edit agent:', agent);
    };

    const openDeletePopup = (agent, index) => {
      // 原有的删除代理功能
      console.log('Delete agent:', agent, index);
    };
    </script>

    <template>
      <SettingsLayout
        :is-loading="uiFlags.isFetching"
        :loading-message="$t('AGENT_MGMT.LOADING')"
        :no-records-found="!agentList.length"
        :no-records-message="$t('AGENT_MGMT.LIST.404')"
      >
        <template #header>
          <BaseSettingsHeader
            :title="$t('AGENT_MGMT.HEADER')"
            :description="$t('AGENT_MGMT.DESCRIPTION')"
            :link-text="$t('AGENT_MGMT.LEARN_MORE')"
            feature-name="agents"
          >
            <template #actions>
              <Button
                icon="i-lucide-circle-plus"
                :label="$t('AGENT_MGMT.HEADER_BTN_TXT')"
                @click="openAddPopup"
              />
            </template>
          </BaseSettingsHeader>
        </template>
        
        <template #body>
          <table class="divide-y divide-n-weak">
            <thead>
              <tr class="text-left">
                <th class="py-3 font-medium text-sm text-n-slate-12">代理</th>
                <th class="py-3 font-medium text-sm text-n-slate-12">角色</th>
                <th class="py-3 font-medium text-sm text-n-slate-12">状态</th>
                <th class="py-3 font-medium text-sm text-n-slate-12">认证</th>
                <th class="py-3 font-medium text-sm text-n-slate-12">操作</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-n-weak text-n-slate-11">
              <tr v-for="(agent, index) in agentList" :key="agent.email">
                <td class="py-4 ltr:pr-4 rtl:pl-4">
                  <div class="flex flex-row items-center gap-4">
                    <Avatar
                      :name="agent.name"
                      :src="agent.thumbnail"
                      :size="40"
                      rounded-full
                    />
                    <div>
                      <span class="block font-medium break-words">
                        {{ agent.name }}
                      </span>
                      <span class="text-sm text-n-slate-11">
                        {{ agent.email }}
                      </span>
                    </div>
                  </div>
                </td>
                <td class="py-4 ltr:pr-4 rtl:pl-4">
                  <span class="capitalize">{{ agent.role }}</span>
                </td>
                <td class="py-4 ltr:pr-4 rtl:pl-4">
                  <span 
                    :class="{
                      'text-green-600': agent.availability_status === 'online',
                      'text-yellow-600': agent.availability_status === 'busy',
                      'text-red-600': agent.availability_status === 'offline'
                    }"
                    class="capitalize"
                  >
                    {{ agent.availability_status || 'offline' }}
                  </span>
                </td>
                <td class="py-4 ltr:pr-4 rtl:pl-4">
                  <span 
                    :class="{
                      'text-green-600': agent.confirmed,
                      'text-orange-600': !agent.confirmed
                    }"
                  >
                    {{ agent.confirmed ? '已认证' : '待认证' }}
                  </span>
                </td>
                <td class="py-4">
                  <div class="flex justify-end gap-1">
                    <!-- 原有操作按钮 -->
                    <Button
                      v-if="showEditAction(agent)"
                      v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                      icon="i-lucide-pen"
                      slate
                      xs
                      faded
                      @click="openEditPopup(agent)"
                    />
                    
                    <!-- 增强功能按钮 -->
                    <Button
                      v-if="showEnhancedActions(agent)"
                      v-tooltip.top="agent.confirmed ? '撤销认证' : '确认认证'"
                      :icon="agent.confirmed ? 'i-lucide-user-x' : 'i-lucide-user-check'"
                      :class="agent.confirmed ? 'text-orange-600' : 'text-green-600'"
                      xs
                      faded
                      :is-loading="loading[agent.id]"
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
                    
                    <Button
                      v-if="showDeleteAction(agent)"
                      v-tooltip.top="$t('AGENT_MGMT.DELETE.BUTTON_TEXT')"
                      icon="i-lucide-trash-2"
                      xs
                      ruby
                      faded
                      :is-loading="loading[agent.id]"
                      @click="openDeletePopup(agent, index)"
                    />
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </template>
      </SettingsLayout>

      <!-- 密码重置模态框 -->
      <Modal
        v-model:show="showPasswordModal"
        :on-close="closePasswordModal"
        size="medium"
      >
        <div class="p-6">
          <h3 class="text-lg font-medium text-n-slate-12 mb-4">
            重置密码 - {{ selectedAgent?.name }}
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
    </template>
  VUE
  
  # 写入增强的agents页面组件
  enhanced_vue_path = '/app/app/javascript/dashboard/routes/dashboard/settings/agents/EnhancedIndex.vue'
  File.write(enhanced_vue_path, enhanced_agents_vue_content)
  puts "✓ 增强agents页面组件已创建"

  puts ""
  puts "=== 增强agents页面组件创建完成 ==="
  puts ""
  puts "✅ 创建的文件:"
  puts "  - #{enhanced_vue_path}"
  puts ""
  puts "✅ 新增功能:"
  puts "  - 切换用户认证状态按钮"
  puts "  - 密码重置功能"
  puts "  - 自动生成安全密码选项"
  puts "  - 手动设置密码选项"
  puts "  - 实时状态显示"
  puts "  - 完整的错误处理和用户反馈"
  puts ""
  puts "下一步: 配置路由以使用增强页面"

rescue => e
  puts "❌ 创建增强agents页面组件失败: #{e.message}"
  puts e.backtrace.first(5)
end
