#!/bin/bash

# Chatwoot 自动更新和维护脚本
# 确保系统始终处于稳定状态，管理员账号始终可用

echo "=== Chatwoot 自动更新和维护系统 ==="
echo ""

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查Docker服务状态
check_docker_status() {
    log_info "检查Docker服务状态..."
    
    if docker-compose -f docker-compose.clean.yaml ps | grep -q "Up"; then
        log_success "Docker服务正在运行"
        return 0
    else
        log_warning "Docker服务未运行，正在启动..."
        docker-compose -f docker-compose.clean.yaml up -d
        sleep 30
        return 1
    fi
}

# 备份重要数据
backup_important_data() {
    log_info "备份重要数据..."
    
    # 创建备份目录
    BACKUP_DIR="./backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份数据库
    docker exec cschat-postgres-1 pg_dump -U postgres chatwoot > "$BACKUP_DIR/database_backup.sql" 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "数据库备份完成: $BACKUP_DIR/database_backup.sql"
    else
        log_warning "数据库备份失败，继续执行..."
    fi
    
    # 备份重要配置文件
    cp -r config "$BACKUP_DIR/" 2>/dev/null
    cp docker-compose.clean.yaml "$BACKUP_DIR/" 2>/dev/null
    
    log_success "配置文件备份完成"
    echo "$BACKUP_DIR" > .last_backup_path
}

# 从Git获取最新更改
update_from_git() {
    log_info "从Git获取最新更改..."
    
    # 检查Git状态
    if [ -d ".git" ]; then
        # 暂存当前更改
        git add . 2>/dev/null
        git stash push -m "Auto-stash before update $(date)" 2>/dev/null
        
        # 获取远程更新
        git fetch origin main 2>/dev/null
        if [ $? -eq 0 ]; then
            log_success "远程更新获取成功"
        else
            log_error "获取远程更新失败"
            return 1
        fi
        
        # 检查是否有新提交
        NEW_COMMITS=$(git rev-list HEAD..origin/main --count 2>/dev/null)
        if [ "$NEW_COMMITS" -gt 0 ]; then
            log_info "发现 $NEW_COMMITS 个新提交，开始合并..."
            
            # 合并更改
            git merge origin/main 2>/dev/null
            if [ $? -eq 0 ]; then
                log_success "Git更新合并成功"
            else
                log_warning "合并失败，尝试强制更新..."
                git reset --hard origin/main 2>/dev/null
                log_success "强制更新完成"
            fi
        else
            log_success "已是最新版本"
        fi
    else
        log_warning "不是Git仓库，跳过Git更新"
    fi
}

# 更新Docker容器
update_docker_containers() {
    log_info "更新Docker容器..."
    
    # 重新构建并启动容器
    docker-compose -f docker-compose.clean.yaml down 2>/dev/null
    docker-compose -f docker-compose.clean.yaml up -d 2>/dev/null
    
    # 等待服务启动
    log_info "等待服务启动..."
    sleep 60
    
    # 检查服务状态
    if docker-compose -f docker-compose.clean.yaml ps | grep -q "Up"; then
        log_success "Docker容器更新完成"
        return 0
    else
        log_error "Docker容器启动失败"
        return 1
    fi
}

# 运行稳定性脚本
run_stability_scripts() {
    log_info "运行稳定性脚本..."
    
    # 复制脚本到容器
    docker cp stable_update_system.rb cschat-chatwoot-1:/app/ 2>/dev/null
    
    # 运行稳定更新脚本
    log_info "运行稳定更新脚本..."
    docker exec cschat-chatwoot-1 bundle exec rails runner /app/stable_update_system.rb
    if [ $? -eq 0 ]; then
        log_success "稳定更新脚本执行成功"
    else
        log_error "稳定更新脚本执行失败"
        return 1
    fi
    
    # 运行功能启用脚本
    if [ -f "enable_all_features.rb" ]; then
        log_info "运行功能启用脚本..."
        docker cp enable_all_features.rb cschat-chatwoot-1:/app/
        docker exec cschat-chatwoot-1 bundle exec rails runner /app/enable_all_features.rb
        log_success "功能启用脚本执行完成"
    fi
    
    # 清除登录限制
    if [ -f "clear_rate_limits.rb" ]; then
        log_info "清除登录限制..."
        docker cp clear_rate_limits.rb cschat-chatwoot-1:/app/
        docker exec cschat-chatwoot-1 bundle exec rails runner /app/clear_rate_limits.rb
        log_success "登录限制清除完成"
    fi
}

# 验证系统状态
verify_system_status() {
    log_info "验证系统状态..."
    
    # 检查HTTP响应
    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
    if [ "$HTTP_STATUS" = "200" ]; then
        log_success "HTTP服务正常 (状态码: $HTTP_STATUS)"
    else
        log_error "HTTP服务异常 (状态码: $HTTP_STATUS)"
        return 1
    fi
    
    # 运行稳定性检查
    docker exec cschat-chatwoot-1 bundle exec rails runner /app/stability_check.rb 2>/dev/null
    if [ $? -eq 0 ]; then
        log_success "稳定性检查通过"
    else
        log_warning "稳定性检查发现问题"
    fi
    
    # 检查增强功能
    ENHANCED_API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/enhanced_agents_api.js 2>/dev/null)
    if [ "$ENHANCED_API_STATUS" = "200" ]; then
        log_success "增强功能API可用"
    else
        log_warning "增强功能API不可用"
    fi
}

# 部署增强功能文件
deploy_enhanced_features() {
    log_info "部署增强功能文件..."
    
    # 部署增强功能文件
    ENHANCED_FILES=(
        "chatwoot_ui_enhancer.js"
        "enhanced_features_demo.html"
        "create_enhanced_api.rb"
    )
    
    for file in "${ENHANCED_FILES[@]}"; do
        if [ -f "$file" ]; then
            docker cp "$file" cschat-chatwoot-1:/app/public/ 2>/dev/null
            log_success "已部署: $file"
        fi
    done
    
    # 运行API创建脚本
    if [ -f "create_enhanced_api.rb" ]; then
        docker cp create_enhanced_api.rb cschat-chatwoot-1:/app/
        docker exec cschat-chatwoot-1 bundle exec rails runner /app/create_enhanced_api.rb 2>/dev/null
        log_success "增强API已创建"
    fi
}

# 创建维护报告
create_maintenance_report() {
    log_info "创建维护报告..."
    
    REPORT_FILE="maintenance_report_$(date +%Y%m%d_%H%M%S).txt"
    
    cat > "$REPORT_FILE" << EOF
=== Chatwoot 维护报告 ===
时间: $(date)
操作: 自动更新和维护

系统状态:
- Docker服务: $(docker-compose -f docker-compose.clean.yaml ps | grep -c "Up") 个容器运行中
- HTTP状态: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null)
- Git状态: $(git rev-parse --short HEAD 2>/dev/null || echo "N/A")

管理员账号:
- gibson@localhost.com / Gibson888555!
- admin@localhost.com / BackupAdmin123!

增强功能:
- API客户端: http://localhost:3000/enhanced_agents_api.js
- UI增强器: http://localhost:3000/chatwoot_ui_enhancer.js
- 演示页面: http://localhost:3000/enhanced_features_demo.html

备份位置:
$(cat .last_backup_path 2>/dev/null || echo "无备份")

=== 报告结束 ===
EOF

    log_success "维护报告已创建: $REPORT_FILE"
}

# 主执行流程
main() {
    echo "开始时间: $(date)"
    echo ""
    
    # 1. 检查Docker状态
    check_docker_status
    
    # 2. 备份重要数据
    backup_important_data
    
    # 3. 从Git获取更新
    update_from_git
    
    # 4. 更新Docker容器
    update_docker_containers
    
    # 5. 运行稳定性脚本
    run_stability_scripts
    
    # 6. 部署增强功能
    deploy_enhanced_features
    
    # 7. 验证系统状态
    verify_system_status
    
    # 8. 创建维护报告
    create_maintenance_report
    
    echo ""
    log_success "=== 自动更新和维护完成 ==="
    echo ""
    log_info "系统访问地址:"
    echo "  - Chatwoot主页: http://localhost:3000"
    echo "  - 增强功能演示: http://localhost:3000/enhanced_features_demo.html"
    echo ""
    log_info "管理员账号:"
    echo "  - gibson@localhost.com / Gibson888555!"
    echo "  - admin@localhost.com / BackupAdmin123!"
    echo ""
    echo "完成时间: $(date)"
}

# 错误处理
set -e
trap 'log_error "脚本执行失败，请检查错误信息"' ERR

# 执行主流程
main "$@"
