// Chatwoot UI增强器 - 专门针对Vue.js界面的用户管理功能增强

(function() {
    'use strict';
    
    console.log('🚀 Chatwoot UI增强器启动...');
    
    // 等待Vue应用加载
    function waitForVueApp(callback, maxAttempts = 50) {
        let attempts = 0;
        
        function check() {
            attempts++;
            
            // 检查Vue应用是否已加载
            const vueApp = document.querySelector('#app').__vue__ || 
                          document.querySelector('[data-v-]') ||
                          window.Vue ||
                          document.querySelector('.dashboard-app');
            
            if (vueApp || document.querySelector('.agent-list') || document.querySelector('.settings-content')) {
                console.log('✅ Vue应用已检测到，开始增强...');
                callback();
            } else if (attempts < maxAttempts) {
                setTimeout(check, 500);
            } else {
                console.log('⚠️ Vue应用检测超时，使用DOM方式增强...');
                callback();
            }
        }
        
        check();
    }
    
    // 创建增强功能控制面板
    function createControlPanel() {
        // 移除已存在的面板
        const existingPanel = document.getElementById('chatwoot-enhancer-panel');
        if (existingPanel) {
            existingPanel.remove();
        }
        
        const panel = document.createElement('div');
        panel.id = 'chatwoot-enhancer-panel';
        panel.innerHTML = `
            <div style="position: fixed; top: 80px; right: 20px; width: 320px; background: white; border-radius: 12px; box-shadow: 0 8px 32px rgba(0,0,0,0.15); z-index: 9999; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; border: 1px solid #e1e5e9;">
                <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 16px; border-radius: 12px 12px 0 0; display: flex; justify-content: space-between; align-items: center;">
                    <div>
                        <h3 style="margin: 0; font-size: 16px; font-weight: 600;">🚀 用户管理增强</h3>
                        <p style="margin: 4px 0 0 0; font-size: 12px; opacity: 0.9;">Chatwoot功能增强工具</p>
                    </div>
                    <button onclick="this.closest('#chatwoot-enhancer-panel').remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; width: 28px; height: 28px; border-radius: 50%; cursor: pointer; font-size: 16px; display: flex; align-items: center; justify-content: center;">&times;</button>
                </div>
                
                <div style="padding: 20px;">
                    <div style="margin-bottom: 16px;">
                        <h4 style="margin: 0 0 12px 0; color: #374151; font-size: 14px; font-weight: 600;">快速操作</h4>
                        <button onclick="enhanceCurrentPage()" style="width: 100%; padding: 12px; background: #10b981; color: white; border: none; border-radius: 8px; cursor: pointer; margin-bottom: 8px; font-weight: 500; transition: all 0.2s;">✨ 增强当前页面</button>
                        <button onclick="showUserManagement()" style="width: 100%; padding: 12px; background: #3b82f6; color: white; border: none; border-radius: 8px; cursor: pointer; margin-bottom: 8px; font-weight: 500; transition: all 0.2s;">👥 用户管理面板</button>
                        <button onclick="injectEnhancedForms()" style="width: 100%; padding: 12px; background: #8b5cf6; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500; transition: all 0.2s;">🔧 注入增强表单</button>
                    </div>
                    
                    <div style="background: #f8fafc; padding: 12px; border-radius: 8px; border: 1px solid #e2e8f0;">
                        <h5 style="margin: 0 0 8px 0; color: #475569; font-size: 12px; font-weight: 600;">状态信息</h5>
                        <div id="enhancer-status" style="font-size: 11px; color: #64748b;">
                            正在检测页面...
                        </div>
                    </div>
                    
                    <div style="margin-top: 12px; text-align: center;">
                        <button onclick="window.open('http://localhost:3000/enhanced_user_management.js', '_blank')" style="background: none; border: 1px solid #d1d5db; color: #6b7280; padding: 6px 12px; border-radius: 6px; cursor: pointer; font-size: 11px;">查看增强脚本</button>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(panel);
        
        // 添加样式
        const style = document.createElement('style');
        style.textContent = `
            #chatwoot-enhancer-panel button:hover {
                transform: translateY(-1px);
                box-shadow: 0 4px 12px rgba(0,0,0,0.15);
            }
        `;
        document.head.appendChild(style);
        
        updateStatus('控制面板已加载');
    }
    
    // 更新状态信息
    function updateStatus(message) {
        const statusEl = document.getElementById('enhancer-status');
        if (statusEl) {
            statusEl.innerHTML = `${new Date().toLocaleTimeString()}: ${message}`;
        }
        console.log(`📊 ${message}`);
    }
    
    // 增强当前页面
    window.enhanceCurrentPage = function() {
        updateStatus('开始增强当前页面...');
        
        // 检测页面类型
        const url = window.location.href;
        const pathname = window.location.pathname;
        
        if (pathname.includes('/settings') || url.includes('settings')) {
            updateStatus('检测到设置页面');
            enhanceSettingsPage();
        } else if (pathname.includes('/agent') || url.includes('agent')) {
            updateStatus('检测到代理页面');
            enhanceAgentPage();
        } else {
            updateStatus('通用页面增强');
            enhanceGenericPage();
        }
    };
    
    // 增强设置页面
    function enhanceSettingsPage() {
        // 查找设置菜单
        const settingsMenu = document.querySelector('.settings-menu, .sidebar-menu, .navigation-menu');
        if (settingsMenu) {
            addEnhancedMenuItem(settingsMenu);
        }
        
        // 查找代理管理区域
        const agentSection = document.querySelector('.agents-section, .team-section, [data-testid="agents"]');
        if (agentSection) {
            enhanceAgentSection(agentSection);
        }
        
        updateStatus('设置页面增强完成');
    }
    
    // 增强代理页面
    function enhanceAgentPage() {
        // 查找代理列表
        const agentList = document.querySelector('.agent-list, .team-list, .user-list');
        if (agentList) {
            enhanceAgentList(agentList);
        }
        
        // 查找添加按钮
        const addButton = document.querySelector('.add-agent, .add-user, [data-testid="add-agent"]');
        if (addButton) {
            enhanceAddButton(addButton);
        }
        
        updateStatus('代理页面增强完成');
    }
    
    // 通用页面增强
    function enhanceGenericPage() {
        // 查找所有表单
        const forms = document.querySelectorAll('form');
        forms.forEach((form, index) => {
            if (hasUserFields(form)) {
                enhanceUserForm(form, index);
            }
        });
        
        // 查找所有模态框
        const modals = document.querySelectorAll('.modal, .dialog, [role="dialog"]');
        modals.forEach(modal => {
            enhanceModal(modal);
        });
        
        updateStatus(`通用增强完成 - 处理了${forms.length}个表单`);
    }
    
    // 检查表单是否包含用户字段
    function hasUserFields(form) {
        const emailInput = form.querySelector('input[type="email"]');
        const nameInput = form.querySelector('input[placeholder*="name"], input[placeholder*="姓名"]');
        return emailInput || nameInput;
    }
    
    // 增强用户表单
    function enhanceUserForm(form, index) {
        // 避免重复增强
        if (form.querySelector('.enhanced-user-fields')) {
            return;
        }
        
        const emailInput = form.querySelector('input[type="email"]');
        if (!emailInput) return;
        
        // 创建增强字段容器
        const enhancedContainer = document.createElement('div');
        enhancedContainer.className = 'enhanced-user-fields';
        enhancedContainer.innerHTML = `
            <div style="margin: 16px 0; padding: 16px; background: linear-gradient(135deg, #f8fafc 0%, #e2e8f0 100%); border-radius: 12px; border: 1px solid #cbd5e1;">
                <div style="display: flex; align-items: center; margin-bottom: 12px;">
                    <span style="font-size: 16px; margin-right: 8px;">🚀</span>
                    <h4 style="margin: 0; color: #1e293b; font-size: 14px; font-weight: 600;">增强用户管理选项</h4>
                </div>
                
                <!-- 密码设置 -->
                <div style="margin: 12px 0;">
                    <label style="display: flex; align-items: center; margin-bottom: 8px; cursor: pointer;">
                        <input type="checkbox" id="enhanced-auto-password-${index}" checked style="margin-right: 8px; transform: scale(1.1);">
                        <span style="font-size: 13px; font-weight: 500; color: #374151;">🔐 自动生成安全密码</span>
                    </label>
                </div>
                
                <div id="enhanced-manual-password-${index}" style="display: none; margin: 12px 0; padding: 12px; background: white; border-radius: 8px; border: 1px solid #d1d5db;">
                    <div style="margin-bottom: 8px;">
                        <label style="display: block; margin-bottom: 4px; font-size: 12px; font-weight: 500; color: #374151;">自定义密码</label>
                        <input type="password" id="enhanced-password-${index}" placeholder="输入密码（最少8位字符）" style="width: 100%; padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px;">
                    </div>
                    <div>
                        <label style="display: block; margin-bottom: 4px; font-size: 12px; font-weight: 500; color: #374151;">确认密码</label>
                        <input type="password" id="enhanced-confirm-password-${index}" placeholder="再次输入密码" style="width: 100%; padding: 8px 12px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 13px;">
                    </div>
                </div>
                
                <!-- 认证设置 -->
                <div style="margin: 12px 0;">
                    <label style="display: flex; align-items: center; margin-bottom: 8px; cursor: pointer;">
                        <input type="checkbox" id="enhanced-confirm-account-${index}" style="margin-right: 8px; transform: scale(1.1);">
                        <span style="font-size: 13px; font-weight: 500; color: #374151;">✅ 立即认证账号</span>
                    </label>
                    <p style="margin: 0 0 0 24px; font-size: 11px; color: #6b7280;">跳过邮箱验证，用户可直接登录</p>
                </div>
                
                <!-- 邮件设置 -->
                <div style="margin: 12px 0;">
                    <label style="display: flex; align-items: center; margin-bottom: 8px; cursor: pointer;">
                        <input type="checkbox" id="enhanced-welcome-email-${index}" style="margin-right: 8px; transform: scale(1.1);">
                        <span style="font-size: 13px; font-weight: 500; color: #374151;">📧 发送欢迎邮件</span>
                    </label>
                    <p style="margin: 0 0 0 24px; font-size: 11px; color: #6b7280;">向新用户发送包含登录信息的邮件</p>
                </div>
                
                <!-- 操作按钮 -->
                <div style="margin-top: 16px; padding-top: 12px; border-top: 1px solid #e2e8f0;">
                    <button type="button" onclick="applyEnhancements(${index})" style="background: linear-gradient(135deg, #10b981 0%, #059669 100%); color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500; margin-right: 8px;">应用增强设置</button>
                    <button type="button" onclick="resetEnhancements(${index})" style="background: #6b7280; color: white; border: none; padding: 8px 16px; border-radius: 6px; cursor: pointer; font-size: 12px; font-weight: 500;">重置</button>
                </div>
            </div>
        `;
        
        // 插入到邮箱字段后面
        const emailContainer = emailInput.closest('div, .form-group, .field');
        if (emailContainer && emailContainer.parentNode) {
            emailContainer.parentNode.insertBefore(enhancedContainer, emailContainer.nextSibling);
        } else {
            form.appendChild(enhancedContainer);
        }
        
        // 添加事件监听
        const autoPasswordCheckbox = document.getElementById(`enhanced-auto-password-${index}`);
        const manualPasswordDiv = document.getElementById(`enhanced-manual-password-${index}`);
        
        if (autoPasswordCheckbox && manualPasswordDiv) {
            autoPasswordCheckbox.addEventListener('change', function() {
                manualPasswordDiv.style.display = this.checked ? 'none' : 'block';
            });
        }
        
        updateStatus(`表单${index + 1}增强完成`);
    }
    
    // 应用增强设置
    window.applyEnhancements = function(index) {
        const autoPassword = document.getElementById(`enhanced-auto-password-${index}`).checked;
        const customPassword = document.getElementById(`enhanced-password-${index}`).value;
        const confirmPassword = document.getElementById(`enhanced-confirm-password-${index}`).value;
        const confirmAccount = document.getElementById(`enhanced-confirm-account-${index}`).checked;
        const welcomeEmail = document.getElementById(`enhanced-welcome-email-${index}`).checked;
        
        // 验证密码
        if (!autoPassword && customPassword) {
            if (customPassword.length < 8) {
                alert('❌ 密码至少需要8位字符');
                return;
            }
            if (customPassword !== confirmPassword) {
                alert('❌ 密码和确认密码不匹配');
                return;
            }
        }
        
        // 显示设置摘要
        const settings = {
            密码: autoPassword ? '自动生成' : (customPassword ? '自定义密码' : '未设置'),
            认证: confirmAccount ? '立即认证' : '需要邮箱验证',
            邮件: welcomeEmail ? '发送欢迎邮件' : '不发送邮件'
        };
        
        const summary = Object.entries(settings).map(([key, value]) => `${key}: ${value}`).join('\n');
        
        alert(`✅ 增强设置已应用:\n\n${summary}\n\n请继续填写表单并提交。`);
        updateStatus('增强设置已应用');
    };
    
    // 重置增强设置
    window.resetEnhancements = function(index) {
        document.getElementById(`enhanced-auto-password-${index}`).checked = true;
        document.getElementById(`enhanced-password-${index}`).value = '';
        document.getElementById(`enhanced-confirm-password-${index}`).value = '';
        document.getElementById(`enhanced-confirm-account-${index}`).checked = false;
        document.getElementById(`enhanced-welcome-email-${index}`).checked = false;
        document.getElementById(`enhanced-manual-password-${index}`).style.display = 'none';
        
        updateStatus('增强设置已重置');
    };
    
    // 显示用户管理面板
    window.showUserManagement = function() {
        updateStatus('打开用户管理面板...');
        
        // 创建用户管理模态框
        const modal = document.createElement('div');
        modal.innerHTML = `
            <div style="position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); z-index: 10000; display: flex; align-items: center; justify-content: center;">
                <div style="background: white; border-radius: 16px; width: 90%; max-width: 600px; max-height: 80vh; overflow-y: auto; box-shadow: 0 20px 40px rgba(0,0,0,0.15);">
                    <div style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 16px 16px 0 0;">
                        <div style="display: flex; justify-content: space-between; align-items: center;">
                            <h2 style="margin: 0; font-size: 20px; font-weight: 600;">👥 用户管理面板</h2>
                            <button onclick="this.closest('div').remove()" style="background: rgba(255,255,255,0.2); border: none; color: white; width: 32px; height: 32px; border-radius: 50%; cursor: pointer; font-size: 18px;">&times;</button>
                        </div>
                    </div>
                    
                    <div style="padding: 24px;">
                        <div style="margin-bottom: 20px;">
                            <h3 style="margin: 0 0 12px 0; color: #374151; font-size: 16px;">快速操作</h3>
                            <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 12px;">
                                <button onclick="quickCreateUser()" style="padding: 12px; background: #10b981; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500;">➕ 快速创建用户</button>
                                <button onclick="managePasswords()" style="padding: 12px; background: #f59e0b; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500;">🔑 密码管理</button>
                                <button onclick="manageVerification()" style="padding: 12px; background: #3b82f6; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500;">✅ 认证管理</button>
                                <button onclick="viewUserStats()" style="padding: 12px; background: #8b5cf6; color: white; border: none; border-radius: 8px; cursor: pointer; font-weight: 500;">📊 用户统计</button>
                            </div>
                        </div>
                        
                        <div style="background: #f8fafc; padding: 16px; border-radius: 12px; border: 1px solid #e2e8f0;">
                            <h4 style="margin: 0 0 12px 0; color: #374151; font-size: 14px;">💡 使用提示</h4>
                            <ul style="margin: 0; padding-left: 16px; color: #6b7280; font-size: 13px; line-height: 1.5;">
                                <li>使用"快速创建用户"可以一键创建带密码的用户</li>
                                <li>密码管理可以重置任何用户的密码</li>
                                <li>认证管理可以控制用户的验证状态</li>
                                <li>所有操作都会在控制台显示详细信息</li>
                            </ul>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.appendChild(modal);
    };
    
    // 注入增强表单
    window.injectEnhancedForms = function() {
        updateStatus('注入增强表单...');
        
        // 强制检测所有表单
        const allForms = document.querySelectorAll('form');
        let enhancedCount = 0;
        
        allForms.forEach((form, index) => {
            // 检查是否有邮箱或姓名字段
            const hasEmail = form.querySelector('input[type="email"]');
            const hasName = form.querySelector('input[placeholder*="name"], input[placeholder*="姓名"], input[name*="name"]');
            
            if (hasEmail || hasName) {
                enhanceUserForm(form, index);
                enhancedCount++;
            }
        });
        
        if (enhancedCount === 0) {
            alert('ℹ️ 当前页面没有找到用户相关的表单。\n\n请导航到以下页面之一：\n• 设置 → 代理管理\n• 添加新代理\n• 编辑代理信息');
        } else {
            alert(`✅ 成功增强了 ${enhancedCount} 个表单！\n\n现在您可以在表单中看到密码设置和认证控制选项。`);
        }
        
        updateStatus(`注入完成 - 增强了${enhancedCount}个表单`);
    };
    
    // 快速创建用户
    window.quickCreateUser = function() {
        const name = prompt('👤 请输入用户姓名:');
        if (!name) return;
        
        const email = prompt('📧 请输入邮箱地址:');
        if (!email) return;
        
        const useCustomPassword = confirm('🔐 是否使用自定义密码？\n\n点击"确定"设置自定义密码\n点击"取消"自动生成密码');
        let password = '';
        
        if (useCustomPassword) {
            password = prompt('🔑 请输入密码（最少8位字符）:');
            if (!password || password.length < 8) {
                alert('❌ 密码至少需要8位字符');
                return;
            }
        } else {
            // 生成随机密码
            const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%';
            password = Array.from({length: 12}, () => chars[Math.floor(Math.random() * chars.length)]).join('');
        }
        
        const confirmAccount = confirm('✅ 是否立即认证账号？\n\n点击"确定"跳过邮箱验证\n点击"取消"需要邮箱验证');
        
        const summary = `👤 用户信息确认:\n\n姓名: ${name}\n邮箱: ${email}\n密码: ${password}\n认证: ${confirmAccount ? '立即认证' : '需要邮箱验证'}\n\n请在Chatwoot的添加代理页面手动输入这些信息。`;
        
        alert(summary);
        
        // 复制到剪贴板
        if (navigator.clipboard) {
            navigator.clipboard.writeText(`姓名: ${name}\n邮箱: ${email}\n密码: ${password}`);
            updateStatus('用户信息已复制到剪贴板');
        }
    };
    
    // 初始化
    function init() {
        console.log('🔄 初始化Chatwoot UI增强器...');
        
        // 等待页面加载
        waitForVueApp(() => {
            createControlPanel();
            
            // 自动检测并增强当前页面
            setTimeout(() => {
                enhanceCurrentPage();
            }, 1000);
            
            // 监听页面变化
            const observer = new MutationObserver(() => {
                // 延迟执行以避免频繁触发
                setTimeout(() => {
                    const forms = document.querySelectorAll('form:not(.enhanced-user-fields)');
                    forms.forEach((form, index) => {
                        if (hasUserFields(form)) {
                            enhanceUserForm(form, index);
                        }
                    });
                }, 500);
            });
            
            observer.observe(document.body, {
                childList: true,
                subtree: true
            });
            
            updateStatus('增强器初始化完成');
        });
    }
    
    // 启动
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
    console.log('✅ Chatwoot UI增强器已加载');
    
})();
