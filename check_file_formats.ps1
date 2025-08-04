# Check file formats and line endings

Write-Host "=== Checking File Formats and Line Endings ===" -ForegroundColor Green
Write-Host ""

# 要检查的文件列表
$filesToCheck = @(
    "app/controllers/api/v1/accounts/enhanced_agents_controller.rb",
    "app/controllers/health_controller.rb",
    "app/javascript/dashboard/routes/dashboard/settings/agents/Index.vue",
    "config/routes.rb",
    "config/initializers/geocoder.rb",
    "public/enhanced_agents_test.html",
    "docker-compose.clean.yaml",
    ".env"
)

function Check-FileFormat($filePath) {
    if (Test-Path $filePath) {
        $content = Get-Content -Path $filePath -Raw
        $totalLength = $content.Length
        $crlfCount = ($content -split "`r`n").Count - 1
        $lfCount = ($content -split "`n").Count - 1
        $crCount = ($content -split "`r").Count - 1
        
        Write-Host "📁 $filePath" -ForegroundColor Cyan
        Write-Host "   文件大小: $totalLength 字符" -ForegroundColor White
        Write-Host "   CRLF (Windows): $crlfCount" -ForegroundColor White
        Write-Host "   LF (Unix): $($lfCount - $crlfCount)" -ForegroundColor White
        Write-Host "   CR (Mac): $($crCount - $crlfCount)" -ForegroundColor White
        
        # 判断文件格式
        if ($crlfCount -gt 0) {
            Write-Host "   格式: Windows (CRLF)" -ForegroundColor Yellow
            $needsConversion = $true
        } elseif ($lfCount -gt 0) {
            Write-Host "   格式: Unix (LF) ✅" -ForegroundColor Green
            $needsConversion = $false
        } else {
            Write-Host "   格式: 未知或空文件" -ForegroundColor Gray
            $needsConversion = $false
        }
        
        Write-Host ""
        return $needsConversion
    } else {
        Write-Host "❌ 文件不存在: $filePath" -ForegroundColor Red
        Write-Host ""
        return $false
    }
}

# 检查所有文件
$needsConversion = @()
foreach ($file in $filesToCheck) {
    if (Check-FileFormat $file) {
        $needsConversion += $file
    }
}

# 总结
Write-Host "=== 检查结果总结 ===" -ForegroundColor Green
Write-Host ""

if ($needsConversion.Count -eq 0) {
    Write-Host "✅ 所有文件都使用正确的Unix格式 (LF)" -ForegroundColor Green
} else {
    Write-Host "⚠️ 以下文件需要转换为Unix格式:" -ForegroundColor Yellow
    foreach ($file in $needsConversion) {
        Write-Host "   - $file" -ForegroundColor Yellow
    }
    
    Write-Host ""
    Write-Host "转换命令 (如果有dos2unix工具):" -ForegroundColor Cyan
    foreach ($file in $needsConversion) {
        Write-Host "   dos2unix `"$file`"" -ForegroundColor Gray
    }
    
    Write-Host ""
    Write-Host "PowerShell转换方法:" -ForegroundColor Cyan
    foreach ($file in $needsConversion) {
        Write-Host "   (Get-Content `"$file`" -Raw) -replace `"`r`n`", `"`n`" | Set-Content `"$file`" -NoNewline" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "=== 应用状态检查 ===" -ForegroundColor Green
Write-Host ""

# 检查应用状态
try {
    $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ 主应用可访问 (状态码: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ 主应用不可访问: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查测试页面
try {
    $testResponse = Invoke-WebRequest -Uri "http://localhost:3000/enhanced_agents_test.html" -TimeoutSec 5 -UseBasicParsing
    Write-Host "✅ 测试页面可访问 (状态码: $($testResponse.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "❌ 测试页面不可访问: $($_.Exception.Message)" -ForegroundColor Red
}

# 检查容器状态
Write-Host ""
Write-Host "📊 容器状态:" -ForegroundColor Cyan
docker-compose -f docker-compose.clean.yaml ps

Write-Host ""
Write-Host "🎯 登录信息:" -ForegroundColor Cyan
Write-Host "   URL: http://localhost:3000" -ForegroundColor White
Write-Host "   邮箱: gibson@localhost.com" -ForegroundColor White
Write-Host "   密码: Gibson888555!" -ForegroundColor White
Write-Host ""
Write-Host "🎉 检查完成！" -ForegroundColor Green
