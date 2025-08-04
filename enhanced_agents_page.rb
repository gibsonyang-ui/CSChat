# 为settings/agents/list页面添加增强用户管理功能

puts "=== 为agents页面添加增强功能 ==="
puts ""

begin
  # 1. 创建增强的agents API服务
  puts "1. 创建增强agents API服务..."
  
  enhanced_agents_api_content = <<~JS
    /* Enhanced Agents API for user management */
    import ApiClient from './ApiClient';

    class EnhancedAgents extends ApiClient {
      constructor() {
        super('enhanced_agents', { accountScoped: true });
      }

      // 切换用户认证状态
      toggleConfirmation(agentId) {
        return this.axios.patch(`${this.url}/${agentId}/toggle_confirmation`);
      }

      // 重置用户密码
      resetPassword(agentId, passwordData = {}) {
        return this.axios.patch(`${this.url}/${agentId}/reset_password`, passwordData);
      }

      // 获取增强的代理信息
      getEnhancedAgents() {
        return this.axios.get(this.url);
      }

      // 创建带增强功能的代理
      createEnhanced(agentData) {
        return this.axios.post(this.url, agentData);
      }
    }

    export default new EnhancedAgents();
  JS
  
  enhanced_api_path = '/app/app/javascript/dashboard/api/enhancedAgents.js'
  File.write(enhanced_api_path, enhanced_agents_api_content)
  puts "✓ 增强agents API已创建"

  # 2. 创建增强agents store模块
  puts "2. 创建增强agents store模块..."
  
  enhanced_agents_store_content = <<~JS
    /* Enhanced Agents Store Module */
    import * as types from '../mutation-types';
    import EnhancedAgentsAPI from '../../api/enhancedAgents';

    export const state = {
      records: [],
      uiFlags: {
        isFetching: false,
        isCreating: false,
        isUpdating: false,
        isDeleting: false,
      },
    };

    export const getters = {
      getEnhancedAgents($state) {
        return $state.records;
      },
      getUIFlags($state) {
        return $state.uiFlags;
      },
      getEnhancedAgent: $state => id => {
        return $state.records.find(record => record.id === Number(id));
      },
    };

    export const actions = {
      // 获取增强代理列表
      getEnhanced: async ({ commit }) => {
        commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isFetching: true });
        try {
          const response = await EnhancedAgentsAPI.getEnhancedAgents();
          commit(types.default.SET_ENHANCED_AGENTS, response.data);
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isFetching: false });
        } catch (error) {
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isFetching: false });
          throw error;
        }
      },

      // 切换认证状态
      toggleConfirmation: async ({ commit }, agentId) => {
        commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: true });
        try {
          const response = await EnhancedAgentsAPI.toggleConfirmation(agentId);
          commit(types.default.UPDATE_ENHANCED_AGENT, response.data.agent);
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: false });
          return response.data;
        } catch (error) {
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: false });
          throw error;
        }
      },

      // 重置密码
      resetPassword: async ({ commit }, { agentId, passwordData }) => {
        commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: true });
        try {
          const response = await EnhancedAgentsAPI.resetPassword(agentId, passwordData);
          commit(types.default.UPDATE_ENHANCED_AGENT, response.data.agent);
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: false });
          return response.data;
        } catch (error) {
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isUpdating: false });
          throw error;
        }
      },

      // 创建增强代理
      createEnhanced: async ({ commit }, agentData) => {
        commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isCreating: true });
        try {
          const response = await EnhancedAgentsAPI.createEnhanced(agentData);
          commit(types.default.ADD_ENHANCED_AGENT, response.data.agent);
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isCreating: false });
          return response.data;
        } catch (error) {
          commit(types.default.SET_ENHANCED_AGENT_UI_FLAG, { isCreating: false });
          throw error;
        }
      },
    };

    export const mutations = {
      [types.default.SET_ENHANCED_AGENT_UI_FLAG]($state, data) {
        $state.uiFlags = {
          ...$state.uiFlags,
          ...data,
        };
      },
      [types.default.SET_ENHANCED_AGENTS]($state, data) {
        $state.records = data;
      },
      [types.default.ADD_ENHANCED_AGENT]($state, data) {
        $state.records.push(data);
      },
      [types.default.UPDATE_ENHANCED_AGENT]($state, data) {
        const index = $state.records.findIndex(record => record.id === data.id);
        if (index !== -1) {
          $state.records[index] = { ...$state.records[index], ...data };
        }
      },
      [types.default.DELETE_ENHANCED_AGENT]($state, id) {
        $state.records = $state.records.filter(record => record.id !== id);
      },
    };

    export default {
      namespaced: true,
      state,
      getters,
      actions,
      mutations,
    };
  JS
  
  enhanced_store_path = '/app/app/javascript/dashboard/store/modules/enhancedAgents.js'
  File.write(enhanced_store_path, enhanced_agents_store_content)
  puts "✓ 增强agents store已创建"

  # 3. 添加mutation types
  puts "3. 添加mutation types..."
  
  mutation_types_path = '/app/app/javascript/dashboard/store/mutation-types.js'
  if File.exist?(mutation_types_path)
    mutation_content = File.read(mutation_types_path)
    
    enhanced_mutations = <<~JS
      
      // Enhanced Agents mutations
      SET_ENHANCED_AGENT_UI_FLAG: 'SET_ENHANCED_AGENT_UI_FLAG',
      SET_ENHANCED_AGENTS: 'SET_ENHANCED_AGENTS',
      ADD_ENHANCED_AGENT: 'ADD_ENHANCED_AGENT',
      UPDATE_ENHANCED_AGENT: 'UPDATE_ENHANCED_AGENT',
      DELETE_ENHANCED_AGENT: 'DELETE_ENHANCED_AGENT',
    JS
    
    # 在文件末尾添加新的mutation types
    unless mutation_content.include?('SET_ENHANCED_AGENT_UI_FLAG')
      mutation_content = mutation_content.sub(/};?\s*$/, "#{enhanced_mutations}};")
      File.write(mutation_types_path, mutation_content)
      puts "✓ Mutation types已添加"
    else
      puts "✓ Mutation types已存在"
    end
  else
    puts "⚠ Mutation types文件不存在，跳过"
  end

  puts ""
  puts "=== 增强agents功能创建完成 ==="
  puts ""
  puts "✅ 创建的文件:"
  puts "  - #{enhanced_api_path}"
  puts "  - #{enhanced_store_path}"
  puts ""
  puts "✅ 功能特性:"
  puts "  - 切换用户认证状态"
  puts "  - 重置用户密码"
  puts "  - 增强的代理信息显示"
  puts "  - 完整的错误处理"
  puts ""
  puts "下一步: 修改agents页面组件以集成这些功能"

rescue => e
  puts "❌ 创建增强agents功能失败: #{e.message}"
  puts e.backtrace.first(5)
end
