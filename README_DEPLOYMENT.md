# Chatwoot 完整部署指南

本指南将帮助您在 Windows 系统上完整部署 Chatwoot 客服系统，并设置管理员账号。

## 📋 部署概览

- **管理员账号**: gibson@localhost.com
- **管理员密码**: Gibson888555
- **访问地址**: http://localhost:3000
- **部署方式**: Docker Compose (生产环境配置)

## 🚀 快速开始

### 前置要求
1. **Docker Desktop**: 从 https://www.docker.com/products/docker-desktop/ 下载并安装
2. **PowerShell**: Windows 10/11 自带

### 一键部署
```powershell
# 在项目根目录运行
.\quick-deploy.ps1
```

## 📁 部署文件说明

### 配置文件
- **`.env`**: 生产环境配置文件（已生成安全密钥）
- **`docker-compose.production.yaml`**: 生产环境 Docker 配置

### 部署脚本
- **`quick-deploy.ps1`**: 一键部署脚本
- **`deploy-chatwoot.ps1`**: 完整部署脚本（包含依赖安装）

### 管理脚本
- **`create_admin.rb`**: 创建管理员账号
- **`test_chatwoot.rb`**: 功能测试脚本
- **`manage_users.rb`**: 用户管理工具

## 🔧 手动部署步骤

### 1. 启动服务
```powershell
docker-compose -f docker-compose.production.yaml up -d --build
```

### 2. 初始化数据库
```powershell
# 创建数据库
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:create

# 运行迁移
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate

# 加载种子数据
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:seed
```

### 3. 创建管理员账号
```powershell
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner create_admin.rb
```

### 4. 运行功能测试
```powershell
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner test_chatwoot.rb
```

## 🎯 功能测试清单

### ✅ 基本功能测试
- [ ] 管理员登录 (gibson@localhost.com / Gibson888555)
- [ ] 创建新的收件箱 (Inbox)
- [ ] 创建新的代理 (Agent)
- [ ] 发送和接收消息
- [ ] 文件上传功能

### ✅ 用户管理功能
- [ ] 创建新用户
- [ ] 修改用户密码
- [ ] 删除用户
- [ ] 设置用户角色
- [ ] 用户权限管理

### ✅ 管理后台功能
- [ ] 账号设置
- [ ] 团队管理
- [ ] 收件箱配置
- [ ] 自动回复设置
- [ ] 标签管理

### ✅ 高级功能
- [ ] 报告和分析
- [ ] 集成设置
- [ ] 通知配置
- [ ] 自定义字段

## 🛠 管理命令

### 服务管理
```powershell
# 查看服务状态
docker-compose -f docker-compose.production.yaml ps

# 查看日志
docker-compose -f docker-compose.production.yaml logs -f

# 重启服务
docker-compose -f docker-compose.production.yaml restart

# 停止服务
docker-compose -f docker-compose.production.yaml down
```

### 用户管理
```powershell
# 交互式用户管理
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails runner manage_users.rb

# 直接修改密码（在 Rails 控制台中）
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails console
# 然后运行: User.find_by(email: 'user@example.com').update!(password: 'newpassword', password_confirmation: 'newpassword')
```

### 数据库管理
```powershell
# 进入数据库控制台
docker-compose -f docker-compose.production.yaml exec postgres psql -U postgres -d chatwoot

# 备份数据库
docker-compose -f docker-compose.production.yaml exec postgres pg_dump -U postgres chatwoot > backup.sql

# 恢复数据库
docker-compose -f docker-compose.production.yaml exec -T postgres psql -U postgres chatwoot < backup.sql
```

## 🔐 安全配置

### 已配置的安全特性
- ✅ 安全的 SECRET_KEY_BASE (128位随机密钥)
- ✅ Redis 密码保护
- ✅ PostgreSQL 密码保护
- ✅ 禁用公开注册 (ENABLE_ACCOUNT_SIGNUP=false)
- ✅ VAPID 密钥对 (推送通知)

### 生产环境建议
- 🔄 定期更新密码
- 🔄 启用 HTTPS (设置 FORCE_SSL=true)
- 🔄 配置防火墙规则
- 🔄 定期备份数据

## 🐛 故障排除

### 常见问题

1. **Docker 服务无法启动**
   ```powershell
   # 检查 Docker Desktop 是否运行
   docker version
   
   # 检查端口占用
   netstat -an | findstr ":3000"
   ```

2. **数据库连接失败**
   ```powershell
   # 检查 PostgreSQL 容器
   docker-compose -f docker-compose.production.yaml logs postgres
   ```

3. **Redis 连接失败**
   ```powershell
   # 检查 Redis 容器
   docker-compose -f docker-compose.production.yaml logs redis
   ```

### 完全重置
```powershell
# 停止并删除所有容器和数据
docker-compose -f docker-compose.production.yaml down -v

# 删除镜像
docker-compose -f docker-compose.production.yaml down --rmi all

# 重新部署
.\quick-deploy.ps1
```

## 📞 支持

如果遇到问题，请检查：
1. Docker Desktop 是否正常运行
2. 端口 3000, 5432, 6379 是否被占用
3. 系统资源是否充足 (至少 4GB RAM)

## 🎉 部署完成

部署成功后，您可以：
1. 访问 http://localhost:3000
2. 使用管理员账号登录 (gibson@localhost.com / Gibson888555)
3. 在管理后台创建和管理用户
4. 配置收件箱和集成
5. 开始使用 Chatwoot 客服系统！
