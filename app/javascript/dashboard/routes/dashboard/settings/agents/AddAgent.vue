<script setup>
import { ref, computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useVuelidate } from '@vuelidate/core';
import { required, email, minLength } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const agentName = ref('');
const agentEmail = ref('');
const selectedRoleId = ref('agent');
const agentPassword = ref('');
const confirmPassword = ref('');
const autoGeneratePassword = ref(true);
const confirmAccount = ref(false);
const sendWelcomeEmail = ref(false);
const agentPassword = ref('');
const confirmPassword = ref('');
const autoGeneratePassword = ref(true);
const confirmAccount = ref(false);
const sendWelcomeEmail = ref(false);

const passwordValidation = computed(() => {
  if (autoGeneratePassword.value) return {};
  return {
    required,
    minLength: minLength(8),
  };
});

const confirmPasswordValidation = computed(() => {
  if (autoGeneratePassword.value) return {};
  return {
    required,
    sameAsPassword: (value) => value === agentPassword.value,
  };
});

const rules = computed(() => ({
  agentName: { required },
  agentEmail: { required, email },
  selectedRoleId: { required },
  agentPassword: passwordValidation.value,
  confirmPassword: confirmPasswordValidation.value,
}));

const v$ = useVuelidate(rules, {
  agentName,
  agentEmail,
  selectedRoleId,
  agentPassword,
  confirmPassword,
});

const uiFlags = useMapGetter('agents/getUIFlags');
const getCustomRoles = useMapGetter('customRole/getCustomRoles');

const roles = computed(() => {
  const defaultRoles = [
    {
      id: 'administrator',
      name: 'administrator',
      label: t('AGENT_MGMT.AGENT_TYPES.ADMINISTRATOR'),
    },
    {
      id: 'agent',
      name: 'agent',
      label: t('AGENT_MGMT.AGENT_TYPES.AGENT'),
    },
  ];

  const customRoles = getCustomRoles.value.map(role => ({
    id: role.id,
    name: `custom_${role.id}`,
    label: role.name,
  }));

  return [...defaultRoles, ...customRoles];
});

const selectedRole = computed(() =>
  roles.value.find(
    role =>
      role.id === selectedRoleId.value || role.name === selectedRoleId.value
  )
);

const addAgent = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  try {
    const payload = {
      name: agentName.value,
      email: agentEmail.value,
      confirmed: confirmAccount.value,
      send_welcome_email: sendWelcomeEmail.value,
    };

    // 添加密码（如果不是自动生成）
    if (!autoGeneratePassword.value && agentPassword.value) {
      payload.password = agentPassword.value;
      payload.password_confirmation = confirmPassword.value;
    }

    if (selectedRole.value.name.startsWith('custom_')) {
      payload.custom_role_id = selectedRole.value.id;
    } else {
      payload.role = selectedRole.value.name;
    }

    await store.dispatch('agents/create', payload);
    useAlert(t('AGENT_MGMT.ADD.API.SUCCESS_MESSAGE'));
    emit('close');
  } catch (error) {
    const {
      response: {
        data: {
          error: errorResponse = '',
          attributes: attributes = [],
          message: attrError = '',
        } = {},
      } = {},
    } = error;

    let errorMessage = '';
    if (error?.response?.status === 422 && !attributes.includes('base')) {
      errorMessage = t('AGENT_MGMT.ADD.API.EXIST_MESSAGE');
    } else {
      errorMessage = t('AGENT_MGMT.ADD.API.ERROR_MESSAGE');
    }
    useAlert(errorResponse || attrError || errorMessage);
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('AGENT_MGMT.ADD.TITLE')"
      :header-content="$t('AGENT_MGMT.ADD.DESC')"
    />
    <form class="flex flex-col items-start w-full" @submit.prevent="addAgent">
      <div class="w-full">
        <label :class="{ error: v$.agentName.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.NAME.LABEL') }}
          <input
            v-model="agentName"
            type="text"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.NAME.PLACEHOLDER')"
            @input="v$.agentName.$touch"
          />
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.selectedRoleId.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.LABEL') }}
          <select v-model="selectedRoleId" @change="v$.selectedRoleId.$touch">
            <option v-for="role in roles" :key="role.id" :value="role.id">
              {{ role.label }}
            </option>
          </select>
          <span v-if="v$.selectedRoleId.$error" class="message">
            {{ $t('AGENT_MGMT.ADD.FORM.AGENT_TYPE.ERROR') }}
          </span>
        </label>
      </div>

      <div class="w-full">
        <label :class="{ error: v$.agentEmail.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.EMAIL.LABEL') }}
          <input
            v-model="agentEmail"
            type="email"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.EMAIL.PLACEHOLDER')"
            @input="v$.agentEmail.$touch"
          />
        </label>
      </div>

      <!-- 密码设置 -->
      <div class="w-full">
        <label>
          <input
            v-model="autoGeneratePassword"
            type="checkbox"
            class="mr-2"
          />
          {{ $t('AGENT_MGMT.ADD.FORM.AUTO_GENERATE_PASSWORD') || 'Auto-generate password' }}
        </label>
      </div>

      <div v-if="!autoGeneratePassword" class="w-full">
        <label :class="{ error: v$.agentPassword.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.PASSWORD.LABEL') || 'Password' }}
          <input
            v-model="agentPassword"
            type="password"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.PASSWORD.PLACEHOLDER') || 'Enter password (min 8 characters)'"
            @input="v$.agentPassword.$touch"
          />
          <span v-if="v$.agentPassword.$error" class="message">
            {{ $t('AGENT_MGMT.ADD.FORM.PASSWORD.ERROR') || 'Password must be at least 8 characters' }}
          </span>
        </label>
      </div>

      <div v-if="!autoGeneratePassword" class="w-full">
        <label :class="{ error: v$.confirmPassword.$error }">
          {{ $t('AGENT_MGMT.ADD.FORM.CONFIRM_PASSWORD.LABEL') || 'Confirm Password' }}
          <input
            v-model="confirmPassword"
            type="password"
            :placeholder="$t('AGENT_MGMT.ADD.FORM.CONFIRM_PASSWORD.PLACEHOLDER') || 'Confirm password'"
            @input="v$.confirmPassword.$touch"
          />
          <span v-if="v$.confirmPassword.$error" class="message">
            {{ $t('AGENT_MGMT.ADD.FORM.CONFIRM_PASSWORD.ERROR') || 'Passwords do not match' }}
          </span>
        </label>
      </div>

      <!-- 认证设置 -->
      <div class="w-full">
        <label>
          <input
            v-model="confirmAccount"
            type="checkbox"
            class="mr-2"
          />
          {{ $t('AGENT_MGMT.ADD.FORM.CONFIRM_ACCOUNT') || 'Verify account immediately' }}
        </label>
      </div>

      <div class="w-full">
        <label>
          <input
            v-model="sendWelcomeEmail"
            type="checkbox"
            class="mr-2"
          />
          {{ $t('AGENT_MGMT.ADD.FORM.SEND_WELCOME_EMAIL') || 'Send welcome email' }}
        </label>
      </div>

      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <Button
          faded
          slate
          type="reset"
          :label="$t('AGENT_MGMT.ADD.CANCEL_BUTTON_TEXT')"
          @click.prevent="emit('close')"
        />
        <Button
          type="submit"
          :label="$t('AGENT_MGMT.ADD.FORM.SUBMIT')"
          :disabled="v$.$invalid || uiFlags.isCreating"
          :is-loading="uiFlags.isCreating"
        />
      </div>
    </form>
  </div>
</template>
