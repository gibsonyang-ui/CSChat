# Chatwoot 部署指南

## 前置要求

在开始部署之前，请确保您的系统已安装以下软件：

### 1. 安装 Docker Desktop
1. 访问 https://www.docker.com/products/docker-desktop/
2. 下载并安装 Docker Desktop for Windows
3. 安装完成后重启计算机
4. 启动 Docker Desktop 并等待其完全启动

### 2. 验证安装
打开 PowerShell 或命令提示符，运行以下命令验证安装：
```bash
docker --version
docker-compose --version
```

## 部署步骤

### 步骤 1: 准备环境文件
环境文件 `.env` 已经创建，包含以下关键配置：
- SECRET_KEY_BASE: 已生成安全密钥
- 数据库配置: PostgreSQL
- Redis 配置
- SMTP 配置 (使用 MailHog 进行测试)

### 步骤 2: 启动服务
在项目根目录运行：
```bash
docker-compose -f docker-compose.production.yaml up -d --build
```

### 步骤 3: 初始化数据库
```bash
# 创建数据库
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:create

# 运行迁移
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:migrate

# 加载种子数据
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails db:seed
```

### 步骤 4: 创建管理员账号
```bash
# 进入 Rails 控制台
docker-compose -f docker-compose.production.yaml exec rails bundle exec rails console

# 在控制台中创建管理员用户
User.create!(
  name: 'Gibson',
  email: 'gibson@localhost.com',
  password: 'Gibson888555',
  password_confirmation: 'Gibson888555',
  confirmed_at: Time.current
)

# 创建账号并设为超级管理员
account = Account.create!(name: 'Gibson Admin Account')
AccountUser.create!(
  account: account,
  user: User.find_by(email: 'gibson@localhost.com'),
  role: 'administrator'
)

# 退出控制台
exit
```

## 访问应用

- **主应用**: http://localhost:3000
- **管理员登录**: 
  - 用户名: gibson@localhost.com
  - 密码: Gibson888555

## 服务管理

### 查看服务状态
```bash
docker-compose -f docker-compose.production.yaml ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose -f docker-compose.production.yaml logs

# 查看特定服务日志
docker-compose -f docker-compose.production.yaml logs rails
docker-compose -f docker-compose.production.yaml logs sidekiq
```

### 停止服务
```bash
docker-compose -f docker-compose.production.yaml down
```

### 重启服务
```bash
docker-compose -f docker-compose.production.yaml restart
```

## 功能测试清单

部署完成后，请测试以下功能：

### 基本功能
- [ ] 管理员登录
- [ ] 创建新的收件箱 (Inbox)
- [ ] 创建新的代理 (Agent)
- [ ] 发送和接收消息
- [ ] 文件上传功能

### 管理功能
- [ ] 用户管理 (创建、编辑、删除用户)
- [ ] 密码重置功能
- [ ] 账号设置
- [ ] 团队管理

### 高级功能
- [ ] 自动回复设置
- [ ] 标签管理
- [ ] 报告和分析
- [ ] 集成设置

## 故障排除

### 常见问题

1. **Docker 服务无法启动**
   - 确保 Docker Desktop 正在运行
   - 检查端口 3000, 5432, 6379 是否被占用

2. **数据库连接失败**
   - 检查 PostgreSQL 容器是否正常运行
   - 验证 .env 文件中的数据库配置

3. **Redis 连接失败**
   - 检查 Redis 容器是否正常运行
   - 验证 Redis 密码配置

### 重置部署
如果需要完全重置：
```bash
# 停止并删除所有容器和卷
docker-compose -f docker-compose.production.yaml down -v

# 删除所有镜像
docker-compose -f docker-compose.production.yaml down --rmi all

# 重新构建和启动
docker-compose -f docker-compose.production.yaml up -d --build
```
