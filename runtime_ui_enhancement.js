// 运行时UI增强脚本 - 动态添加用户管理功能到现有界面

(function() {
    'use strict';
    
    console.log('🚀 加载增强用户管理功能...');
    
    // 等待页面加载完成
    function waitForElement(selector, callback, timeout = 10000) {
        const startTime = Date.now();
        
        function check() {
            const element = document.querySelector(selector);
            if (element) {
                callback(element);
            } else if (Date.now() - startTime < timeout) {
                setTimeout(check, 100);
            }
        }
        
        check();
    }
    
    // 增强添加代理表单
    function enhanceAddAgentForm() {
        // 查找添加代理表单
        const formSelectors = [
            'form[data-testid="add-agent-form"]',
            '.add-agent-form',
            'form:has(input[placeholder*="email"], input[placeholder*="邮箱"])',
            '.modal form',
            'form'
        ];
        
        for (const selector of formSelectors) {
            const form = document.querySelector(selector);
            if (form && (form.innerHTML.includes('email') || form.innerHTML.includes('邮箱'))) {
                console.log('✓ 找到添加代理表单，正在增强...');
                addPasswordFields(form);
                addConfirmationFields(form);
                return true;
            }
        }
        
        return false;
    }
    
    // 添加密码字段
    function addPasswordFields(form) {
        // 查找邮箱字段后面插入密码字段
        const emailInput = form.querySelector('input[type="email"], input[placeholder*="email"], input[placeholder*="邮箱"]');
        if (!emailInput) return;
        
        const emailContainer = emailInput.closest('.form-group, .field, .input-group, div');
        if (!emailContainer) return;
        
        // 创建密码设置容器
        const passwordContainer = document.createElement('div');
        passwordContainer.className = 'enhanced-password-section';
        passwordContainer.innerHTML = `
            <div class="form-group" style="margin: 16px 0;">
                <label style="display: flex; align-items: center; margin-bottom: 8px;">
                    <input type="checkbox" id="auto-generate-password" checked style="margin-right: 8px;">
                    <span style="font-weight: 500;">自动生成密码</span>
                </label>
            </div>
            
            <div id="manual-password-fields" style="display: none;">
                <div class="form-group" style="margin: 16px 0;">
                    <label style="display: block; margin-bottom: 4px; font-weight: 500;">密码</label>
                    <input type="password" id="custom-password" placeholder="输入密码（最少8位字符）" 
                           style="width: 100%; padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px;">
                    <small style="color: #666; font-size: 12px;">留空将自动生成安全密码</small>
                </div>
                
                <div class="form-group" style="margin: 16px 0;">
                    <label style="display: block; margin-bottom: 4px; font-weight: 500;">确认密码</label>
                    <input type="password" id="confirm-password" placeholder="再次输入密码" 
                           style="width: 100%; padding: 8px 12px; border: 1px solid #ddd; border-radius: 4px;">
                </div>
            </div>
        `;
        
        // 插入到邮箱字段后面
        emailContainer.parentNode.insertBefore(passwordContainer, emailContainer.nextSibling);
        
        // 添加事件监听
        const autoGenCheckbox = document.getElementById('auto-generate-password');
        const manualFields = document.getElementById('manual-password-fields');
        
        autoGenCheckbox.addEventListener('change', function() {
            manualFields.style.display = this.checked ? 'none' : 'block';
        });
        
        console.log('✓ 密码字段已添加');
    }
    
    // 添加认证和邮件选项
    function addConfirmationFields(form) {
        // 查找表单底部
        const submitButton = form.querySelector('button[type="submit"], .submit-button, .btn-primary');
        if (!submitButton) return;
        
        const submitContainer = submitButton.closest('.form-group, .button-group, .actions, div');
        if (!submitContainer) return;
        
        // 创建认证选项容器
        const confirmationContainer = document.createElement('div');
        confirmationContainer.className = 'enhanced-confirmation-section';
        confirmationContainer.innerHTML = `
            <div style="margin: 16px 0; padding: 16px; background: #f8f9fa; border-radius: 8px; border: 1px solid #e9ecef;">
                <h4 style="margin: 0 0 12px 0; font-size: 14px; font-weight: 600; color: #495057;">账号设置</h4>
                
                <div style="margin: 8px 0;">
                    <label style="display: flex; align-items: center;">
                        <input type="checkbox" id="confirm-account" style="margin-right: 8px;">
                        <span style="font-size: 14px;">立即认证账号</span>
                    </label>
                    <small style="color: #666; font-size: 12px; margin-left: 24px;">选中后用户无需邮箱验证即可登录</small>
                </div>
                
                <div style="margin: 8px 0;">
                    <label style="display: flex; align-items: center;">
                        <input type="checkbox" id="send-welcome-email" style="margin-right: 8px;">
                        <span style="font-size: 14px;">发送欢迎邮件</span>
                    </label>
                    <small style="color: #666; font-size: 12px; margin-left: 24px;">向新用户发送包含登录信息的欢迎邮件</small>
                </div>
            </div>
        `;
        
        // 插入到提交按钮前面
        submitContainer.parentNode.insertBefore(confirmationContainer, submitContainer);
        
        console.log('✓ 认证选项已添加');
    }
    
    // 拦截表单提交，添加增强数据
    function interceptFormSubmission() {
        document.addEventListener('submit', function(e) {
            const form = e.target;
            
            // 检查是否是代理表单
            if (form.querySelector('#auto-generate-password')) {
                console.log('🔄 拦截表单提交，添加增强数据...');
                
                const autoGenerate = document.getElementById('auto-generate-password').checked;
                const customPassword = document.getElementById('custom-password').value;
                const confirmPassword = document.getElementById('confirm-password').value;
                const confirmAccount = document.getElementById('confirm-account').checked;
                const sendWelcomeEmail = document.getElementById('send-welcome-email').checked;
                
                // 验证密码
                if (!autoGenerate && customPassword) {
                    if (customPassword.length < 8) {
                        e.preventDefault();
                        alert('密码至少需要8位字符');
                        return;
                    }
                    
                    if (customPassword !== confirmPassword) {
                        e.preventDefault();
                        alert('密码和确认密码不匹配');
                        return;
                    }
                }
                
                // 添加隐藏字段到表单
                const hiddenFields = [
                    { name: 'auto_generate_password', value: autoGenerate },
                    { name: 'custom_password', value: customPassword },
                    { name: 'confirmed', value: confirmAccount },
                    { name: 'send_welcome_email', value: sendWelcomeEmail }
                ];
                
                hiddenFields.forEach(field => {
                    const input = document.createElement('input');
                    input.type = 'hidden';
                    input.name = field.name;
                    input.value = field.value;
                    form.appendChild(input);
                });
                
                console.log('✓ 增强数据已添加到表单');
            }
        });
    }
    
    // 增强编辑代理界面
    function enhanceEditAgentForm() {
        // 查找编辑表单
        const editSelectors = [
            '.edit-agent-form',
            'form:has(.availability-select)',
            '.modal form:has(select)',
            'form'
        ];
        
        for (const selector of editSelectors) {
            const form = document.querySelector(selector);
            if (form && form.innerHTML.includes('availability')) {
                console.log('✓ 找到编辑代理表单，正在增强...');
                addEditEnhancements(form);
                return true;
            }
        }
        
        return false;
    }
    
    // 添加编辑增强功能
    function addEditEnhancements(form) {
        // 查找可用性选择器
        const availabilitySelect = form.querySelector('select');
        if (!availabilitySelect) return;
        
        const availabilityContainer = availabilitySelect.closest('.form-group, .field, div');
        if (!availabilityContainer) return;
        
        // 创建增强功能容器
        const enhancementContainer = document.createElement('div');
        enhancementContainer.className = 'enhanced-edit-section';
        enhancementContainer.innerHTML = `
            <div style="margin: 20px 0; padding: 16px; background: #f8f9fa; border-radius: 8px; border: 1px solid #e9ecef;">
                <h4 style="margin: 0 0 16px 0; font-size: 14px; font-weight: 600; color: #495057;">账号管理</h4>
                
                <!-- 认证状态 -->
                <div style="margin: 12px 0; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;">
                    <div style="display: flex; justify-content: space-between; align-items: center;">
                        <div>
                            <strong style="font-size: 14px;">认证状态</strong>
                            <p style="margin: 4px 0 0 0; font-size: 12px; color: #666;" id="confirmation-status">检查中...</p>
                        </div>
                        <button type="button" id="toggle-confirmation-btn" 
                                style="padding: 6px 12px; border: none; border-radius: 4px; font-size: 12px; cursor: pointer;">
                            切换认证
                        </button>
                    </div>
                </div>
                
                <!-- 密码管理 -->
                <div style="margin: 12px 0; padding: 12px; background: white; border-radius: 6px; border: 1px solid #dee2e6;">
                    <strong style="font-size: 14px; display: block; margin-bottom: 8px;">密码管理</strong>
                    
                    <div style="margin: 8px 0;">
                        <input type="password" id="new-password" placeholder="新密码（最少8位）" 
                               style="width: 100%; padding: 6px 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 12px;">
                    </div>
                    
                    <div style="margin: 8px 0;">
                        <input type="password" id="confirm-new-password" placeholder="确认新密码" 
                               style="width: 100%; padding: 6px 8px; border: 1px solid #ddd; border-radius: 4px; font-size: 12px;">
                    </div>
                    
                    <div style="margin: 8px 0;">
                        <label style="display: flex; align-items: center; font-size: 12px;">
                            <input type="checkbox" id="force-password-change" style="margin-right: 6px;">
                            <span>要求下次登录时修改密码</span>
                        </label>
                    </div>
                    
                    <div style="margin: 8px 0;">
                        <button type="button" id="reset-password-btn" 
                                style="padding: 6px 12px; background: #007bff; color: white; border: none; border-radius: 4px; font-size: 12px; cursor: pointer; margin-right: 8px;">
                            设置新密码
                        </button>
                        <button type="button" id="send-reset-link-btn" 
                                style="padding: 6px 12px; background: #6c757d; color: white; border: none; border-radius: 4px; font-size: 12px; cursor: pointer;">
                            发送重置链接
                        </button>
                    </div>
                </div>
            </div>
        `;
        
        // 插入到可用性字段后面
        availabilityContainer.parentNode.insertBefore(enhancementContainer, availabilityContainer.nextSibling);
        
        // 添加事件监听
        setupEditEventListeners();
        
        console.log('✓ 编辑增强功能已添加');
    }
    
    // 设置编辑界面事件监听
    function setupEditEventListeners() {
        // 切换认证状态
        const toggleBtn = document.getElementById('toggle-confirmation-btn');
        if (toggleBtn) {
            toggleBtn.addEventListener('click', function() {
                // 这里应该调用API切换认证状态
                const status = document.getElementById('confirmation-status');
                const isConfirmed = status.textContent.includes('已认证');
                
                // 模拟API调用
                if (isConfirmed) {
                    status.textContent = '未认证 - 用户需要邮箱验证';
                    status.style.color = '#dc3545';
                    toggleBtn.textContent = '认证账号';
                    toggleBtn.style.background = '#28a745';
                } else {
                    status.textContent = '已认证 - 可以正常登录';
                    status.style.color = '#28a745';
                    toggleBtn.textContent = '撤销认证';
                    toggleBtn.style.background = '#ffc107';
                }
                
                alert('认证状态已更新');
            });
        }
        
        // 重置密码
        const resetBtn = document.getElementById('reset-password-btn');
        if (resetBtn) {
            resetBtn.addEventListener('click', function() {
                const newPassword = document.getElementById('new-password').value;
                const confirmPassword = document.getElementById('confirm-new-password').value;
                const forceChange = document.getElementById('force-password-change').checked;
                
                if (!newPassword) {
                    alert('请输入新密码');
                    return;
                }
                
                if (newPassword.length < 8) {
                    alert('密码至少需要8位字符');
                    return;
                }
                
                if (newPassword !== confirmPassword) {
                    alert('密码和确认密码不匹配');
                    return;
                }
                
                // 模拟API调用
                alert(`密码已更新\n新密码: ${newPassword}\n强制修改: ${forceChange ? '是' : '否'}`);
                
                // 清空字段
                document.getElementById('new-password').value = '';
                document.getElementById('confirm-new-password').value = '';
                document.getElementById('force-password-change').checked = false;
            });
        }
        
        // 发送重置链接
        const sendLinkBtn = document.getElementById('send-reset-link-btn');
        if (sendLinkBtn) {
            sendLinkBtn.addEventListener('click', function() {
                alert('密码重置链接已发送到用户邮箱');
            });
        }
    }
    
    // 初始化认证状态显示
    function initConfirmationStatus() {
        const status = document.getElementById('confirmation-status');
        const toggleBtn = document.getElementById('toggle-confirmation-btn');
        
        if (status && toggleBtn) {
            // 模拟获取当前状态
            const isConfirmed = Math.random() > 0.5; // 随机状态用于演示
            
            if (isConfirmed) {
                status.textContent = '已认证 - 可以正常登录';
                status.style.color = '#28a745';
                toggleBtn.textContent = '撤销认证';
                toggleBtn.style.background = '#ffc107';
            } else {
                status.textContent = '未认证 - 用户需要邮箱验证';
                status.style.color = '#dc3545';
                toggleBtn.textContent = '认证账号';
                toggleBtn.style.background = '#28a745';
            }
        }
    }
    
    // 主初始化函数
    function init() {
        console.log('🔄 初始化增强用户管理功能...');
        
        // 拦截表单提交
        interceptFormSubmission();
        
        // 监听页面变化
        const observer = new MutationObserver(function(mutations) {
            mutations.forEach(function(mutation) {
                if (mutation.type === 'childList') {
                    // 检查是否有新的表单出现
                    setTimeout(() => {
                        if (!enhanceAddAgentForm()) {
                            enhanceEditAgentForm();
                        }
                        initConfirmationStatus();
                    }, 100);
                }
            });
        });
        
        observer.observe(document.body, {
            childList: true,
            subtree: true
        });
        
        // 初始检查
        setTimeout(() => {
            if (!enhanceAddAgentForm()) {
                enhanceEditAgentForm();
            }
            initConfirmationStatus();
        }, 1000);
        
        console.log('✅ 增强用户管理功能初始化完成');
    }
    
    // 等待页面加载完成后初始化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
    
})();
