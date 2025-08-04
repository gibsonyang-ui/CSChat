@echo off
chcp 65001 >nul
title Chatwoot 自动更新和维护工具

echo.
echo ========================================
echo    Chatwoot 自动更新和维护工具
echo ========================================
echo.

:menu
echo 请选择操作:
echo.
echo [1] 快速修复管理员登录问题
echo [2] 检查系统状态
echo [3] 从Git获取最新更新
echo [4] 重启Docker服务
echo [5] 完整系统维护
echo [6] 打开Chatwoot主页
echo [7] 打开增强功能演示
echo [0] 退出
echo.
set /p choice="请输入选项 (0-7): "

if "%choice%"=="1" goto quickfix
if "%choice%"=="2" goto checkstatus
if "%choice%"=="3" goto gitupdate
if "%choice%"=="4" goto restart
if "%choice%"=="5" goto fullmaintenance
if "%choice%"=="6" goto openapp
if "%choice%"=="7" goto opendemo
if "%choice%"=="0" goto exit
goto menu

:quickfix
echo.
echo [INFO] 执行快速修复管理员登录问题...
echo.
docker exec cschat-chatwoot-1 bundle exec rails runner /app/quick_fix_admin_login.rb
if %errorlevel% equ 0 (
    echo.
    echo [SUCCESS] ✅ 快速修复完成！
    echo.
    echo 管理员账号:
    echo   gibson@localhost.com / Gibson888555!
    echo   admin@localhost.com / BackupAdmin123!
    echo.
) else (
    echo.
    echo [ERROR] ❌ 快速修复失败，请检查Docker服务状态
    echo.
)
pause
goto menu

:checkstatus
echo.
echo [INFO] 检查系统状态...
echo.

echo 检查Docker服务...
docker-compose -f docker-compose.clean.yaml ps | findstr "Up" >nul
if %errorlevel% equ 0 (
    echo ✅ Docker服务: 正常运行
) else (
    echo ❌ Docker服务: 未运行
)

echo.
echo 检查HTTP服务...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000' -TimeoutSec 5 -UseBasicParsing; Write-Host '✅ HTTP服务: 正常 (状态码:' $r.StatusCode ')' } catch { Write-Host '❌ HTTP服务: 异常' }"

echo.
echo 检查增强功能...
powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000/enhanced_agents_api.js' -TimeoutSec 5 -UseBasicParsing; Write-Host '✅ 增强API: 可用' } catch { Write-Host '⚠ 增强API: 不可用' }"

powershell -Command "try { $r = Invoke-WebRequest -Uri 'http://localhost:3000/enhanced_features_demo.html' -TimeoutSec 5 -UseBasicParsing; Write-Host '✅ 演示页面: 可用' } catch { Write-Host '⚠ 演示页面: 不可用' }"

echo.
pause
goto menu

:gitupdate
echo.
echo [INFO] 从Git获取最新更新...
echo.

if exist ".git" (
    echo 暂存当前更改...
    git add . 2>nul
    git stash push -m "Auto-stash before update" 2>nul
    
    echo 获取远程更新...
    git fetch origin main 2>nul
    if %errorlevel% equ 0 (
        echo ✅ 远程更新获取成功
        
        echo 检查新提交...
        for /f %%i in ('git rev-list HEAD..origin/main --count 2^>nul') do set newcommits=%%i
        if !newcommits! gtr 0 (
            echo 发现 !newcommits! 个新提交，开始合并...
            git merge origin/main 2>nul
            if %errorlevel% equ 0 (
                echo ✅ 更新合并成功
            ) else (
                echo ⚠ 合并失败，尝试强制更新...
                git reset --hard origin/main 2>nul
                echo ✅ 强制更新完成
            )
        ) else (
            echo ✅ 已是最新版本
        )
    ) else (
        echo ❌ 获取远程更新失败
    )
) else (
    echo ⚠ 不是Git仓库，跳过Git更新
)

echo.
pause
goto menu

:restart
echo.
echo [INFO] 重启Docker服务...
echo.
echo 停止服务...
docker-compose -f docker-compose.clean.yaml down
echo.
echo 启动服务...
docker-compose -f docker-compose.clean.yaml up -d
echo.
echo 等待服务启动 (60秒)...
timeout /t 60 /nobreak >nul
echo.
echo ✅ Docker服务重启完成
echo.
pause
goto menu

:fullmaintenance
echo.
echo [INFO] 执行完整系统维护...
echo.

echo 步骤 1/4: 从Git获取更新...
call :gitupdate_silent

echo.
echo 步骤 2/4: 重启Docker服务...
docker-compose -f docker-compose.clean.yaml restart
timeout /t 30 /nobreak >nul

echo.
echo 步骤 3/4: 运行稳定更新脚本...
docker exec cschat-chatwoot-1 bundle exec rails runner /app/stable_update_system.rb

echo.
echo 步骤 4/4: 快速修复管理员账号...
docker exec cschat-chatwoot-1 bundle exec rails runner /app/quick_fix_admin_login.rb

echo.
echo ✅ 完整系统维护完成！
echo.
echo 系统地址:
echo   主页: http://localhost:3000
echo   演示: http://localhost:3000/enhanced_features_demo.html
echo.
echo 管理员账号:
echo   gibson@localhost.com / Gibson888555!
echo   admin@localhost.com / BackupAdmin123!
echo.
pause
goto menu

:gitupdate_silent
if exist ".git" (
    git add . 2>nul
    git stash push -m "Auto-stash before update" 2>nul
    git fetch origin main 2>nul
    git merge origin/main 2>nul || git reset --hard origin/main 2>nul
)
goto :eof

:openapp
echo.
echo [INFO] 打开Chatwoot主页...
start http://localhost:3000
goto menu

:opendemo
echo.
echo [INFO] 打开增强功能演示页面...
start http://localhost:3000/enhanced_features_demo.html
goto menu

:exit
echo.
echo 感谢使用 Chatwoot 自动更新和维护工具！
echo.
pause
exit /b 0
