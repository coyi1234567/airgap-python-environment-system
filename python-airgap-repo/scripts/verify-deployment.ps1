# 部署验证脚本
# 内网机器离线Python环境全自动化管理系统
# AirGap Python Environment Management System
# 功能：验证离线Python环境部署是否成功

param(
    [string]$InstallPath = "C:\Miniconda3",
    [string]$RepoPath = "."
)

Write-Host "=== 离线Python环境部署验证 ===" -ForegroundColor Green

$verificationResults = @()
$overallSuccess = $true

# 1. 验证Miniconda安装
Write-Host "`n1. 验证Miniconda安装..." -ForegroundColor Yellow
$condaPath = "$InstallPath\Scripts\conda.exe"
if (Test-Path $condaPath) {
    $condaVersion = & $condaPath --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Miniconda安装成功: $condaVersion" -ForegroundColor Green
        $verificationResults += @{Test="Miniconda安装"; Status="通过"; Details=$condaVersion}
    } else {
        Write-Host "❌ Miniconda版本检查失败" -ForegroundColor Red
        $verificationResults += @{Test="Miniconda安装"; Status="失败"; Details="版本检查失败"}
        $overallSuccess = $false
    }
} else {
    Write-Host "❌ Miniconda未安装或路径错误" -ForegroundColor Red
    $verificationResults += @{Test="Miniconda安装"; Status="失败"; Details="文件不存在"}
    $overallSuccess = $false
}

# 2. 验证Python环境
Write-Host "`n2. 验证Python环境..." -ForegroundColor Yellow
if (Test-Path $condaPath) {
    $pythonVersion = & $condaPath run python --version 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Python环境正常: $pythonVersion" -ForegroundColor Green
        $verificationResults += @{Test="Python环境"; Status="通过"; Details=$pythonVersion}
    } else {
        Write-Host "❌ Python环境检查失败" -ForegroundColor Red
        $verificationResults += @{Test="Python环境"; Status="失败"; Details="环境检查失败"}
        $overallSuccess = $false
    }
}

# 3. 验证环境配置
Write-Host "`n3. 验证环境配置..." -ForegroundColor Yellow
if (Test-Path $condaPath) {
    $envList = & $condaPath env list 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 环境配置正常" -ForegroundColor Green
        Write-Host "已创建的环境:" -ForegroundColor White
        $envList | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
        $verificationResults += @{Test="环境配置"; Status="通过"; Details="环境列表正常"}
    } else {
        Write-Host "❌ 环境配置检查失败" -ForegroundColor Red
        $verificationResults += @{Test="环境配置"; Status="失败"; Details="环境列表获取失败"}
        $overallSuccess = $false
    }
}

# 4. 验证本地服务器
Write-Host "`n4. 验证本地服务器..." -ForegroundColor Yellow

# 检查conda服务器
try {
    $condaResponse = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Conda本地服务器运行正常 (端口8080)" -ForegroundColor Green
    $verificationResults += @{Test="Conda服务器"; Status="通过"; Details="端口8080正常"}
} catch {
    Write-Host "❌ Conda本地服务器未运行 (端口8080)" -ForegroundColor Red
    $verificationResults += @{Test="Conda服务器"; Status="失败"; Details="端口8080无响应"}
    $overallSuccess = $false
}

# 检查pip服务器
try {
    $pipResponse = Invoke-WebRequest -Uri "http://localhost:8081" -TimeoutSec 5 -ErrorAction Stop
    Write-Host "✅ Pip本地服务器运行正常 (端口8081)" -ForegroundColor Green
    $verificationResults += @{Test="Pip服务器"; Status="通过"; Details="端口8081正常"}
} catch {
    Write-Host "❌ Pip本地服务器未运行 (端口8081)" -ForegroundColor Red
    $verificationResults += @{Test="Pip服务器"; Status="失败"; Details="端口8081无响应"}
    $overallSuccess = $false
}

# 5. 验证包安装功能
Write-Host "`n5. 验证包安装功能..." -ForegroundColor Yellow
if (Test-Path $condaPath) {
    # 测试安装一个简单包
    Write-Host "测试安装requests包..." -ForegroundColor White
    $installResult = & $condaPath install requests -y 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ 包安装功能正常" -ForegroundColor Green
        $verificationResults += @{Test="包安装功能"; Status="通过"; Details="requests安装成功"}
    } else {
        Write-Host "❌ 包安装功能异常" -ForegroundColor Red
        $verificationResults += @{Test="包安装功能"; Status="失败"; Details="requests安装失败"}
        $overallSuccess = $false
    }
}

# 6. 验证仓库文件
Write-Host "`n6. 验证仓库文件..." -ForegroundColor Yellow
$requiredFiles = @(
    "manifest.json",
    "README.md",
    "scripts\setup.ps1",
    "scripts\env-manager.ps1",
    "scripts\download-packages.ps1",
    "environments\base-scientific.yml",
    "environments\base-ml.yml",
    "environments\base-dl.yml",
    "installers\Miniconda3-latest-Windows-x86_64.exe"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path "$RepoPath\$file")) {
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "✅ 所有仓库文件完整" -ForegroundColor Green
    $verificationResults += @{Test="仓库文件"; Status="通过"; Details="所有文件存在"}
} else {
    Write-Host "❌ 缺少仓库文件:" -ForegroundColor Red
    $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    $verificationResults += @{Test="仓库文件"; Status="失败"; Details="缺少$($missingFiles.Count)个文件"}
    $overallSuccess = $false
}

# 7. 生成验证报告
Write-Host "`n=== 验证报告 ===" -ForegroundColor Green
$verificationResults | ForEach-Object {
    $color = if($_.Status -eq "通过"){"Green"}else{"Red"}
    Write-Host "$($_.Test): $($_.Status) - $($_.Details)" -ForegroundColor $color
}

# 计算成功率
$passedTests = ($verificationResults | Where-Object {$_.Status -eq "通过"}).Count
$totalTests = $verificationResults.Count
$successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "`n验证成功率: $successRate% ($passedTests/$totalTests)" -ForegroundColor $(if($successRate -ge 90){"Green"}elseif($successRate -ge 70){"Yellow"}else{"Red"})

if ($overallSuccess -and $successRate -ge 90) {
    Write-Host "`n🎉 部署验证通过！离线Python环境部署成功！" -ForegroundColor Green
    Write-Host "`n使用说明:" -ForegroundColor Yellow
    Write-Host "1. 激活环境: conda activate base-scientific" -ForegroundColor White
    Write-Host "2. 安装包: conda install numpy pandas" -ForegroundColor White
    Write-Host "3. 查看环境: conda env list" -ForegroundColor White
    return $true
} else {
    Write-Host "`n❌ 部署验证失败！请检查上述问题并重新部署。" -ForegroundColor Red
    return $false
}


