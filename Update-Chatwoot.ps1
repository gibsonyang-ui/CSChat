# Chatwoot 自动更新和维护 PowerShell 脚本
# 确保系统始终处于稳定状态，管理员账号始终可用

param(
    [switch]$QuickFix,
    [switch]$FullUpdate,
    [switch]$CheckStatus,
    [switch]$Force
)

# 颜色函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "HH:mm:ss"
    Write-Host "[$timestamp] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success { param([string]$Message) Write-ColorOutput $Message "Green" }
function Write-Warning { param([string]$Message) Write-ColorOutput $Message "Yellow" }
function Write-Error { param([string]$Message) Write-ColorOutput $Message "Red" }
function Write-Info { param([string]$Message) Write-ColorOutput $Message "Cyan" }

# 检查Docker服务状态
function Test-DockerStatus {
    Write-Info "检查Docker服务状态..."
    
    try {
        $containers = docker-compose -f docker-compose.clean.yaml ps 2>$null
        if ($containers -match "Up") {
            Write-Success "Docker服务正在运行"
            return $true
        } else {
            Write-Warning "Docker服务未运行，正在启动..."
            docker-compose -f docker-compose.clean.yaml up -d
            Start-Sleep -Seconds 30
            return $false
        }
    } catch {
        Write-Error "Docker检查失败: $($_.Exception.Message)"
        return $false
    }
}

# 从Git获取最新更改
function Update-FromGit {
    Write-Info "从Git获取最新更改..."
    
    try {
        # 检查是否是Git仓库
        if (Test-Path ".git") {
            # 暂存当前更改
            git add . 2>$null
            git stash push -m "Auto-stash before update $(Get-Date)" 2>$null
            
            # 获取远程更新
            $fetchResult = git fetch origin main 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "远程更新获取成功"
            } else {
                Write-Error "获取远程更新失败: $fetchResult"
                return $false
            }
            
            # 检查是否有新提交
            $newCommits = git rev-list HEAD..origin/main --count 2>$null
            if ($newCommits -gt 0) {
                Write-Info "发现 $newCommits 个新提交，开始合并..."
                
                # 合并更改
                $mergeResult = git merge origin/main 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "Git更新合并成功"
                } else {
                    Write-Warning "合并失败，尝试强制更新..."
                    git reset --hard origin/main 2>$null
                    Write-Success "强制更新完成"
                }
            } else {
                Write-Success "已是最新版本"
            }
        } else {
            Write-Warning "不是Git仓库，跳过Git更新"
        }
        return $true
    } catch {
        Write-Error "Git更新失败: $($_.Exception.Message)"
        return $false
    }
}

# 运行快速修复
function Invoke-QuickFix {
    Write-Info "运行快速修复..."
    
    try {
        # 复制快速修复脚本
        docker cp quick_fix_admin_login.rb cschat-chatwoot-1:/app/ 2>$null
        
        # 运行快速修复
        $result = docker exec cschat-chatwoot-1 bundle exec rails runner /app/quick_fix_admin_login.rb
        if ($LASTEXITCODE -eq 0) {
            Write-Success "快速修复执行成功"
            return $true
        } else {
            Write-Error "快速修复执行失败"
            return $false
        }
    } catch {
        Write-Error "快速修复失败: $($_.Exception.Message)"
        return $false
    }
}

# 运行完整更新
function Invoke-FullUpdate {
    Write-Info "运行完整更新..."
    
    try {
        # 复制稳定更新脚本
        docker cp stable_update_system.rb cschat-chatwoot-1:/app/ 2>$null
        
        # 运行稳定更新
        $result = docker exec cschat-chatwoot-1 bundle exec rails runner /app/stable_update_system.rb
        if ($LASTEXITCODE -eq 0) {
            Write-Success "完整更新执行成功"
        } else {
            Write-Warning "完整更新有警告，运行快速修复..."
            Invoke-QuickFix | Out-Null
        }
        
        # 部署增强功能
        Deploy-EnhancedFeatures
        
        return $true
    } catch {
        Write-Error "完整更新失败: $($_.Exception.Message)"
        return $false
    }
}

# 部署增强功能
function Deploy-EnhancedFeatures {
    Write-Info "部署增强功能..."
    
    $enhancedFiles = @(
        "chatwoot_ui_enhancer.js",
        "enhanced_features_demo.html",
        "create_enhanced_api.rb"
    )
    
    foreach ($file in $enhancedFiles) {
        if (Test-Path $file) {
            docker cp $file cschat-chatwoot-1:/app/public/ 2>$null
            Write-Success "已部署: $file"
        }
    }
    
    # 运行API创建脚本
    if (Test-Path "create_enhanced_api.rb") {
        docker cp create_enhanced_api.rb cschat-chatwoot-1:/app/ 2>$null
        docker exec cschat-chatwoot-1 bundle exec rails runner /app/create_enhanced_api.rb 2>$null
        Write-Success "增强API已创建"
    }
}

# 检查系统状态
function Test-SystemStatus {
    Write-Info "检查系统状态..."
    
    $status = @{
        Docker = $false
        HTTP = $false
        EnhancedAPI = $false
        UIEnhancer = $false
    }
    
    # 检查Docker
    try {
        $containers = docker-compose -f docker-compose.clean.yaml ps 2>$null
        $status.Docker = $containers -match "Up"
    } catch {
        $status.Docker = $false
    }
    
    # 检查HTTP服务
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
        $status.HTTP = $response.StatusCode -eq 200
    } catch {
        $status.HTTP = $false
    }
    
    # 检查增强API
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_api.js" -TimeoutSec 5 -UseBasicParsing
        $status.EnhancedAPI = $response.StatusCode -eq 200
    } catch {
        $status.EnhancedAPI = $false
    }
    
    # 检查UI增强器
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000/chatwoot_ui_enhancer.js" -TimeoutSec 5 -UseBasicParsing
        $status.UIEnhancer = $response.StatusCode -eq 200
    } catch {
        $status.UIEnhancer = $false
    }
    
    # 显示状态
    Write-Host ""
    Write-Host "=== 系统状态检查 ===" -ForegroundColor Magenta
    Write-Host "Docker服务: " -NoNewline
    if ($status.Docker) { Write-Host "✓ 正常" -ForegroundColor Green } else { Write-Host "✗ 异常" -ForegroundColor Red }
    
    Write-Host "HTTP服务: " -NoNewline
    if ($status.HTTP) { Write-Host "✓ 正常" -ForegroundColor Green } else { Write-Host "✗ 异常" -ForegroundColor Red }
    
    Write-Host "增强API: " -NoNewline
    if ($status.EnhancedAPI) { Write-Host "✓ 可用" -ForegroundColor Green } else { Write-Host "✗ 不可用" -ForegroundColor Yellow }
    
    Write-Host "UI增强器: " -NoNewline
    if ($status.UIEnhancer) { Write-Host "✓ 可用" -ForegroundColor Green } else { Write-Host "✗ 不可用" -ForegroundColor Yellow }
    
    Write-Host ""
    
    return $status
}

# 显示使用说明
function Show-Usage {
    Write-Host ""
    Write-Host "=== Chatwoot 自动更新和维护工具 ===" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "使用方法:" -ForegroundColor Yellow
    Write-Host "  .\Update-Chatwoot.ps1 -QuickFix     # 快速修复管理员登录问题"
    Write-Host "  .\Update-Chatwoot.ps1 -FullUpdate   # 完整更新（包含Git拉取）"
    Write-Host "  .\Update-Chatwoot.ps1 -CheckStatus  # 检查系统状态"
    Write-Host "  .\Update-Chatwoot.ps1 -Force        # 强制重启并更新"
    Write-Host ""
    Write-Host "管理员账号:" -ForegroundColor Yellow
    Write-Host "  gibson@localhost.com / Gibson888555!"
    Write-Host "  admin@localhost.com / BackupAdmin123!"
    Write-Host ""
    Write-Host "系统地址:" -ForegroundColor Yellow
    Write-Host "  主页: http://localhost:3000"
    Write-Host "  演示: http://localhost:3000/enhanced_features_demo.html"
    Write-Host ""
}

# 主执行流程
function Main {
    Write-Host ""
    Write-Host "=== Chatwoot 自动更新和维护系统 ===" -ForegroundColor Magenta
    Write-Host "开始时间: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
    
    # 检查参数
    if (-not ($QuickFix -or $FullUpdate -or $CheckStatus -or $Force)) {
        Show-Usage
        return
    }
    
    # 强制重启
    if ($Force) {
        Write-Info "强制重启Docker服务..."
        docker-compose -f docker-compose.clean.yaml down 2>$null
        docker-compose -f docker-compose.clean.yaml up -d 2>$null
        Start-Sleep -Seconds 60
    }
    
    # 检查Docker状态
    if (-not (Test-DockerStatus)) {
        Write-Error "Docker服务启动失败"
        return
    }
    
    # 执行相应操作
    if ($CheckStatus) {
        Test-SystemStatus | Out-Null
    }
    
    if ($QuickFix) {
        Write-Info "执行快速修复..."
        if (Invoke-QuickFix) {
            Write-Success "快速修复完成"
        } else {
            Write-Error "快速修复失败"
        }
    }
    
    if ($FullUpdate) {
        Write-Info "执行完整更新..."
        
        # 从Git更新
        Update-FromGit | Out-Null
        
        # 运行完整更新
        if (Invoke-FullUpdate) {
            Write-Success "完整更新完成"
        } else {
            Write-Error "完整更新失败"
        }
    }
    
    # 最终状态检查
    Write-Host ""
    $finalStatus = Test-SystemStatus
    
    # 显示结果
    Write-Host ""
    Write-Host "=== 更新完成 ===" -ForegroundColor Magenta
    Write-Host "完成时间: $(Get-Date)" -ForegroundColor Gray
    Write-Host ""
    
    if ($finalStatus.HTTP) {
        Write-Success "✅ 系统已就绪，可以正常使用！"
        Write-Host ""
        Write-Info "访问地址:"
        Write-Host "  - Chatwoot主页: http://localhost:3000"
        Write-Host "  - 增强功能演示: http://localhost:3000/enhanced_features_demo.html"
        Write-Host ""
        Write-Info "管理员账号:"
        Write-Host "  - gibson@localhost.com / Gibson888555!"
        Write-Host "  - admin@localhost.com / BackupAdmin123!"
    } else {
        Write-Error "❌ 系统仍有问题，请检查Docker服务状态"
    }
    
    Write-Host ""
}

# 错误处理
$ErrorActionPreference = "Continue"

# 执行主流程
Main
