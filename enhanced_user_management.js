// 增强的用户管理前端功能
// 这个文件应该放在 app/javascript/dashboard/modules/enhanced_user_management.js

class EnhancedUserManagement {
  constructor() {
    this.apiBase = `/api/v1/accounts/${window.chatwootConfig.accountId}/enhanced_admin`;
    this.init();
  }

  init() {
    this.bindEvents();
    this.loadUsers();
  }

  bindEvents() {
    // 创建用户按钮
    document.addEventListener('click', (e) => {
      if (e.target.matches('[data-action="create-user"]')) {
        this.showCreateUserModal();
      }
      
      if (e.target.matches('[data-action="edit-user"]')) {
        const userId = e.target.dataset.userId;
        this.showEditUserModal(userId);
      }
      
      if (e.target.matches('[data-action="delete-user"]')) {
        const userId = e.target.dataset.userId;
        this.deleteUser(userId);
      }
      
      if (e.target.matches('[data-action="toggle-confirmation"]')) {
        const userId = e.target.dataset.userId;
        this.toggleUserConfirmation(userId);
      }
      
      if (e.target.matches('[data-action="reset-password"]')) {
        const userId = e.target.dataset.userId;
        this.resetUserPassword(userId);
      }
    });
  }

  async loadUsers() {
    try {
      const response = await fetch(`${this.apiBase}/users`, {
        headers: this.getHeaders()
      });
      
      if (response.ok) {
        const data = await response.json();
        this.renderUsersList(data.users);
        this.updateUserStats();
      }
    } catch (error) {
      this.showError('Failed to load users');
    }
  }

  renderUsersList(users) {
    const container = document.getElementById('enhanced-users-list');
    if (!container) return;

    const html = users.map(user => `
      <div class="user-card" data-user-id="${user.id}">
        <div class="user-info">
          <div class="user-avatar">
            <img src="/assets/default-avatar.png" alt="${user.name}" />
          </div>
          <div class="user-details">
            <h3>${user.name}</h3>
            <p class="email">${user.email}</p>
            <div class="user-meta">
              <span class="role role-${user.role}">${user.role}</span>
              <span class="status ${user.confirmed ? 'confirmed' : 'unconfirmed'}">
                ${user.confirmed ? 'Verified' : 'Unverified'}
              </span>
            </div>
          </div>
        </div>
        
        <div class="user-actions">
          <button class="btn btn-sm" data-action="edit-user" data-user-id="${user.id}">
            Edit
          </button>
          <button class="btn btn-sm" data-action="reset-password" data-user-id="${user.id}">
            Reset Password
          </button>
          <button class="btn btn-sm" data-action="toggle-confirmation" data-user-id="${user.id}">
            ${user.confirmed ? 'Revoke' : 'Verify'}
          </button>
          <button class="btn btn-sm btn-danger" data-action="delete-user" data-user-id="${user.id}">
            Delete
          </button>
        </div>
      </div>
    `).join('');

    container.innerHTML = html;
  }

  showCreateUserModal() {
    const modal = this.createModal('Create New User', `
      <form id="create-user-form">
        <div class="form-group">
          <label for="user-name">Name *</label>
          <input type="text" id="user-name" name="name" required />
        </div>
        
        <div class="form-group">
          <label for="user-email">Email *</label>
          <input type="email" id="user-email" name="email" required />
        </div>
        
        <div class="form-group">
          <label for="user-password">Password</label>
          <input type="password" id="user-password" name="password" />
          <small>Leave empty to auto-generate</small>
        </div>
        
        <div class="form-group">
          <label for="user-role">Role</label>
          <select id="user-role" name="role">
            <option value="agent">Agent</option>
            <option value="administrator">Administrator</option>
          </select>
        </div>
        
        <div class="form-group">
          <label>
            <input type="checkbox" id="user-confirmed" name="confirmed" />
            Verify account immediately
          </label>
        </div>
        
        <div class="form-group">
          <label>
            <input type="checkbox" id="send-welcome" name="send_welcome_email" />
            Send welcome email
          </label>
        </div>
        
        <div class="form-actions">
          <button type="button" class="btn btn-secondary" data-action="close-modal">
            Cancel
          </button>
          <button type="submit" class="btn btn-primary">
            Create User
          </button>
        </div>
      </form>
    `);

    document.getElementById('create-user-form').addEventListener('submit', (e) => {
      e.preventDefault();
      this.createUser(new FormData(e.target));
    });
  }

  async createUser(formData) {
    try {
      const data = Object.fromEntries(formData);
      data.confirmed = formData.has('confirmed');
      data.send_welcome_email = formData.has('send_welcome_email');

      const response = await fetch(`${this.apiBase}/users`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify(data)
      });

      if (response.ok) {
        const result = await response.json();
        this.showSuccess(`User created successfully. ${result.temporary_password ? `Temporary password: ${result.temporary_password}` : ''}`);
        this.closeModal();
        this.loadUsers();
      } else {
        const error = await response.json();
        this.showError(error.errors?.join(', ') || 'Failed to create user');
      }
    } catch (error) {
      this.showError('Failed to create user');
    }
  }

  async resetUserPassword(userId) {
    if (!confirm('Are you sure you want to reset this user\'s password?')) {
      return;
    }

    try {
      const response = await fetch(`${this.apiBase}/users/${userId}/reset_password`, {
        method: 'POST',
        headers: this.getHeaders(),
        body: JSON.stringify({
          force_password_change: true
        })
      });

      if (response.ok) {
        const result = await response.json();
        this.showSuccess(`Password reset successfully. New password: ${result.temporary_password}`);
      } else {
        this.showError('Failed to reset password');
      }
    } catch (error) {
      this.showError('Failed to reset password');
    }
  }

  async toggleUserConfirmation(userId) {
    try {
      const response = await fetch(`${this.apiBase}/users/${userId}/toggle_confirmation`, {
        method: 'POST',
        headers: this.getHeaders()
      });

      if (response.ok) {
        const result = await response.json();
        this.showSuccess(result.message);
        this.loadUsers();
      } else {
        this.showError('Failed to update confirmation status');
      }
    } catch (error) {
      this.showError('Failed to update confirmation status');
    }
  }

  async deleteUser(userId) {
    if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
      return;
    }

    try {
      const response = await fetch(`${this.apiBase}/users/${userId}`, {
        method: 'DELETE',
        headers: this.getHeaders()
      });

      if (response.ok) {
        const result = await response.json();
        this.showSuccess(result.message);
        this.loadUsers();
      } else {
        this.showError('Failed to delete user');
      }
    } catch (error) {
      this.showError('Failed to delete user');
    }
  }

  async updateUserStats() {
    try {
      const response = await fetch(`${this.apiBase}/user_stats`, {
        headers: this.getHeaders()
      });

      if (response.ok) {
        const stats = await response.json();
        this.renderUserStats(stats);
      }
    } catch (error) {
      console.error('Failed to load user stats');
    }
  }

  renderUserStats(stats) {
    const container = document.getElementById('user-stats');
    if (!container) return;

    container.innerHTML = `
      <div class="stats-grid">
        <div class="stat-card">
          <h3>${stats.total_users}</h3>
          <p>Total Users</p>
        </div>
        <div class="stat-card">
          <h3>${stats.confirmed_users}</h3>
          <p>Verified Users</p>
        </div>
        <div class="stat-card">
          <h3>${stats.administrators}</h3>
          <p>Administrators</p>
        </div>
        <div class="stat-card">
          <h3>${stats.agents}</h3>
          <p>Agents</p>
        </div>
      </div>
    `;
  }

  createModal(title, content) {
    const modal = document.createElement('div');
    modal.className = 'enhanced-modal-overlay';
    modal.innerHTML = `
      <div class="enhanced-modal">
        <div class="modal-header">
          <h2>${title}</h2>
          <button class="close-btn" data-action="close-modal">&times;</button>
        </div>
        <div class="modal-content">
          ${content}
        </div>
      </div>
    `;

    modal.addEventListener('click', (e) => {
      if (e.target.matches('[data-action="close-modal"]') || e.target === modal) {
        this.closeModal();
      }
    });

    document.body.appendChild(modal);
    return modal;
  }

  closeModal() {
    const modal = document.querySelector('.enhanced-modal-overlay');
    if (modal) {
      modal.remove();
    }
  }

  getHeaders() {
    return {
      'Content-Type': 'application/json',
      'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content || ''
    };
  }

  showSuccess(message) {
    this.showNotification(message, 'success');
  }

  showError(message) {
    this.showNotification(message, 'error');
  }

  showNotification(message, type) {
    // 使用现有的通知系统或创建简单的通知
    const notification = document.createElement('div');
    notification.className = `notification notification-${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => {
      notification.remove();
    }, 5000);
  }
}

// 初始化增强用户管理
document.addEventListener('DOMContentLoaded', () => {
  if (document.getElementById('enhanced-user-management')) {
    new EnhancedUserManagement();
  }
});

// 导出类以供其他模块使用
window.EnhancedUserManagement = EnhancedUserManagement;
