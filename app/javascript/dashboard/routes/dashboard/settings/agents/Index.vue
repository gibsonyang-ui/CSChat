<script setup>
import { useAlert } from 'dashboard/composables';
import { computed, onMounted, ref } from 'vue';
import Thumbnail from 'dashboard/components/widgets/Thumbnail.vue';
import { useI18n } from 'vue-i18n';
import {
  useStoreGetters,
  useStore,
  useMapGetter,
} from 'dashboard/composables/store';

import AddAgent from './AddAgent.vue';
import EditAgent from './EditAgent.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Modal from 'dashboard/components/Modal.vue';
import Input from 'dashboard/components-next/input/Input.vue';

const getters = useStoreGetters();
const store = useStore();
const { t } = useI18n();

const loading = ref({});
const showAddPopup = ref(false);
const showDeletePopup = ref(false);
const showEditPopup = ref(false);
const agentAPI = ref({ message: '' });
const currentAgent = ref({});

const deleteConfirmText = computed(
  () => `${t('AGENT_MGMT.DELETE.CONFIRM.YES')} ${currentAgent.value.name}`
);
const deleteRejectText = computed(() => {
  return `${t('AGENT_MGMT.DELETE.CONFIRM.NO')} ${currentAgent.value.name}`;
});
const deleteMessage = computed(() => {
  return ` ${currentAgent.value.name}?`;
});

const agentList = computed(() => getters['agents/getAgents'].value);
const uiFlags = computed(() => getters['agents/getUIFlags'].value);
const currentUserId = computed(() => getters.getCurrentUserID.value);
const customRoles = useMapGetter('customRole/getCustomRoles');

onMounted(() => {
  store.dispatch('agents/get');
  store.dispatch('customRole/getCustomRole');
});

const findCustomRole = agent =>
  customRoles.value.find(role => role.id === agent.custom_role_id);

const getAgentRoleName = agent => {
  if (!agent.custom_role_id) {
    return t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`);
  }
  const customRole = findCustomRole(agent);
  return customRole ? customRole.name : '';
};

const getAgentRolePermissions = agent => {
  if (!agent.custom_role_id) {
    return [];
  }
  const customRole = findCustomRole(agent);
  return customRole?.permissions || [];
};

const verifiedAdministrators = computed(() => {
  return agentList.value.filter(
    agent => agent.role === 'administrator' && agent.confirmed
  );
});

const showEditAction = agent => {
  return currentUserId.value !== agent.id;
};

const showDeleteAction = agent => {
  if (currentUserId.value === agent.id) {
    return false;
  }

  if (!agent.confirmed) {
    return true;
  }

  if (agent.role === 'administrator') {
    return verifiedAdministrators.value.length !== 1;
  }
  return true;
};

const showAlertMessage = message => {
  loading.value[currentAgent.value.id] = false;
  currentAgent.value = {};
  agentAPI.value.message = message;
  useAlert(message);
};

const openAddPopup = () => {
  showAddPopup.value = true;
};
const hideAddPopup = () => {
  showAddPopup.value = false;
};

const openEditPopup = agent => {
  showEditPopup.value = true;
  currentAgent.value = agent;
};
const hideEditPopup = () => {
  showEditPopup.value = false;
};

const openDeletePopup = agent => {
  showDeletePopup.value = true;
  currentAgent.value = agent;
};
const closeDeletePopup = () => {
  showDeletePopup.value = false;
};

const deleteAgent = async id => {
  try {
    await store.dispatch('agents/delete', id);
    showAlertMessage(t('AGENT_MGMT.DELETE.API.SUCCESS_MESSAGE'));
  } catch (error) {
    showAlertMessage(t('AGENT_MGMT.DELETE.API.ERROR_MESSAGE'));
  }
};
const confirmDeletion = () => {
  loading.value[currentAgent.value.id] = true;
  closeDeletePopup();
  deleteAgent(currentAgent.value.id);
};

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

// ?áÊç¢ËÆ§Ë??∂ÊÄ?
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

    // ?¥Êñ∞?¨Âú∞?∂ÊÄ?
    store.dispatch('agents/get');

    showAlert({
      type: 'success',
      message: data.message || (agent.confirmed ? 'ËÆ§Ë?Â∑≤Êí§?Ä' : '?®Êà∑Â∑≤ËÆ§ËØ?),
    });
  } catch (error) {
    console.error('Toggle confirmation error:', error);
    showAlert({
      type: 'error',
      message: '?ç‰?Â§±Ë¥•: ' + error.message,
    });
  } finally {
    enhancedLoading.value = { ...enhancedLoading.value, [agent.id]: false };
  }
};

// ?ìÂ?ÂØÜÁ??çÁΩÆÊ®°ÊÄÅÊ?
const openPasswordModal = (agent) => {
  selectedAgentForPassword.value = agent;
  newPassword.value = '';
  confirmPassword.value = '';
  autoGeneratePassword.value = true;
  showPasswordModal.value = true;
};

// ?≥Èó≠ÂØÜÁ??çÁΩÆÊ®°ÊÄÅÊ?
const closePasswordModal = () => {
  showPasswordModal.value = false;
  selectedAgentForPassword.value = null;
  newPassword.value = '';
  confirmPassword.value = '';
};

// ?çÁΩÆÂØÜÁ?
const resetPassword = async () => {
  if (!selectedAgentForPassword.value) return;

  if (!autoGeneratePassword.value) {
    if (!newPassword.value || newPassword.value.length < 8) {
      showAlert({
        type: 'error',
        message: 'ÂØÜÁ??øÂ∫¶?≥Â?8‰Ω?,
      });
      return;
    }

    if (newPassword.value !== confirmPassword.value) {
      showAlert({
        type: 'error',
        message: 'ÂØÜÁ?Á°ÆËÆ§‰∏çÂåπ??,
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

    // ?¥Êñ∞?¨Âú∞?∂ÊÄ?
    store.dispatch('agents/get');

    showAlert({
      type: 'success',
      message: `ÂØÜÁ??çÁΩÆ?êÂ?ÔºÅÊñ∞ÂØÜÁ?: ${data.password}`,
      duration: 10000,
    });

    closePasswordModal();
  } catch (error) {
    console.error('Reset password error:', error);
    showAlert({
      type: 'error',
      message: 'ÂØÜÁ??çÁΩÆÂ§±Ë¥•: ' + error.message,
    });
  }
};

// ?üÊ??èÊú∫ÂØÜÁ?È¢ÑË?
const generatePasswordPreview = () => {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < 12; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
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
        <tbody class="divide-y divide-n-weak text-n-slate-11">
          <tr v-for="(agent, index) in agentList" :key="agent.email">
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <div class="flex flex-row items-center gap-4">
                <Thumbnail
                  :src="agent.thumbnail"
                  :username="agent.name"
                  size="40px"
                  :status="agent.availability_status"
                />
                <div>
                  <span class="block font-medium capitalize">
                    {{ agent.name }}
                  </span>
                  <span>{{ agent.email }}</span>
                </div>
              </div>
            </td>

            <td class="relative py-4 ltr:pr-4 rtl:pl-4">
              <span
                class="block font-medium w-fit"
                :class="{
                  'hover:text-gray-900 group cursor-pointer':
                    agent.custom_role_id,
                }"
              >
                {{ getAgentRoleName(agent) }}

                <div
                  class="absolute left-0 z-10 hidden max-w-[300px] w-auto bg-white rounded-xl border border-n-weak shadow-lg top-14 md:top-12 dark:bg-n-solid-2"
                  :class="{ 'group-hover:block': agent.custom_role_id }"
                >
                  <div class="flex flex-col gap-1 p-4">
                    <span class="font-semibold">
                      {{ $t('AGENT_MGMT.LIST.AVAILABLE_CUSTOM_ROLE') }}
                    </span>
                    <ul class="pl-4 mb-0 list-disc">
                      <li
                        v-for="permission in getAgentRolePermissions(agent)"
                        :key="permission"
                        class="font-normal"
                      >
                        {{
                          $t(
                            `CUSTOM_ROLE.PERMISSIONS.${permission.toUpperCase()}`
                          )
                        }}
                      </li>
                    </ul>
                  </div>
                </div>
              </span>
            </td>
            <td class="py-4 ltr:pr-4 rtl:pl-4">
              <span v-if="agent.confirmed">
                {{ $t('AGENT_MGMT.LIST.VERIFIED') }}
              </span>
              <span v-if="!agent.confirmed">
                {{ $t('AGENT_MGMT.LIST.VERIFICATION_PENDING') }}
              </span>
            </td>
            <td class="py-4">
              <div class="flex justify-end gap-1">
                <Button
                  v-if="showEditAction(agent)"
                  v-tooltip.top="$t('AGENT_MGMT.EDIT.BUTTON_TEXT')"
                  icon="i-lucide-pen"
                  slate
                  xs
                  faded
                  @click="openEditPopup(agent)"
                />
                <Button
                  v-if="showEnhancedActions(agent)"
                  v-tooltip.top="agent.confirmed ? '?§È?ËÆ§Ë?' : 'Á°ÆËÆ§ËÆ§Ë?'"
                  :icon="agent.confirmed ? 'i-lucide-user-x' : 'i-lucide-user-check'"
                  xs
                  :emerald="!agent.confirmed"
                  :ruby="agent.confirmed"
                  faded
                  :is-loading="enhancedLoading[agent.id]"
                  @click="toggleConfirmation(agent)"
                />
                <Button
                  v-if="showEnhancedActions(agent)"
                  v-tooltip.top="'?çÁΩÆÂØÜÁ?'"
                  icon="i-lucide-key"
                  xs
                  slate
                  faded
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

    <woot-modal v-model:show="showAddPopup" :on-close="hideAddPopup">
      <AddAgent @close="hideAddPopup" />
    </woot-modal>

    <woot-modal v-model:show="showEditPopup" :on-close="hideEditPopup">
      <EditAgent
        v-if="showEditPopup"
        :id="currentAgent.id"
        :name="currentAgent.name"
        :type="currentAgent.role"
        :email="currentAgent.email"
        :availability="currentAgent.availability_status"
        :custom-role-id="currentAgent.custom_role_id"
        @close="hideEditPopup"
      />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeletePopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('AGENT_MGMT.DELETE.CONFIRM.TITLE')"
      :message="$t('AGENT_MGMT.DELETE.CONFIRM.MESSAGE')"
      :message-value="deleteMessage"
      :confirm-text="deleteConfirmText"
      :reject-text="deleteRejectText"
    />

    <!-- ÂØÜÁ??çÁΩÆÊ®°ÊÄÅÊ? -->
    <Modal
      v-model:show="showPasswordModal"
      :on-close="closePasswordModal"
      size="medium"
    >
      <div class="p-6">
        <h3 class="text-lg font-medium text-slate-900 dark:text-slate-100 mb-4">
          ?çÁΩÆÂØÜÁ? - {{ selectedAgentForPassword?.name }}
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
              ?™Âä®?üÊ?ÂÆâÂÖ®ÂØÜÁ? (?®Ë?)
            </label>
          </div>

          <div v-if="!autoGeneratePassword" class="space-y-3">
            <Input
              v-model="newPassword"
              type="password"
              label="?∞Â???
              placeholder="ËØ∑Ë??•Êñ∞ÂØÜÁ? (?≥Â?8‰Ω?"
              required
            />
            <Input
              v-model="confirmPassword"
              type="password"
              label="Á°ÆËÆ§ÂØÜÁ?"
              placeholder="ËØ∑Â?Ê¨°Ë??•Â???
              required
            />
          </div>

          <div v-else class="p-3 bg-slate-50 dark:bg-slate-800 rounded-lg">
            <p class="text-sm text-slate-700 dark:text-slate-300">
              Â∞ÜÁ??ê‰?‰∏?2‰ΩçÁ?ÂÆâÂÖ®ÂØÜÁ?ÔºåÂ??´Â§ßÂ∞èÂ?Â≠óÊ??ÅÊï∞Â≠óÂ??πÊ?Â≠óÁ¨¶??
            </p>
            <p class="text-xs text-slate-500 dark:text-slate-400 mt-1">
              Á§∫‰?: {{ generatePasswordPreview() }}
            </p>
          </div>
        </div>

        <div class="flex justify-end gap-3 mt-6">
          <Button
            variant="clear"
            @click="closePasswordModal"
          >
            ?ñÊ?
          </Button>
          <Button
            @click="resetPassword"
          >
            ?çÁΩÆÂØÜÁ?
          </Button>
        </div>
      </div>
    </Modal>
  </SettingsLayout>
</template>
