# 内网机器离线Python环境全自动化管理系统 - 一键部署脚本
# AirGap Python Environment Management System
# 功能：自动安装Miniconda，配置本地镜像源，安装基础环境

param(
    [string]$InstallPath = "C:\Miniconda3",
    [string]$RepoPath = ".\python-airgap-repo"
)

Write-Host "=== 内网机器离线Python环境一键部署 ===" -ForegroundColor Green
Write-Host "安装路径: $InstallPath" -ForegroundColor White
Write-Host "仓库路径: $RepoPath" -ForegroundColor White

# 1. 检查系统要求
Write-Host "`n1. 检查系统要求..." -ForegroundColor Yellow
$osVersion = [System.Environment]::OSVersion.Version
if ($osVersion.Major -lt 10) {
    Write-Host "错误: 需要Windows 10或更高版本" -ForegroundColor Red
    exit 1
}
Write-Host "系统版本检查通过" -ForegroundColor Green

# 检查磁盘空间
$drive = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'"
$freeSpaceGB = [math]::Round($drive.FreeSpace / 1GB, 2)
if ($freeSpaceGB -lt 5) {
    Write-Host "警告: C盘可用空间不足5GB，当前可用: $freeSpaceGB GB" -ForegroundColor Yellow
}
Write-Host "磁盘空间检查完成，可用空间: $freeSpaceGB GB" -ForegroundColor Green

# 2. 安装Miniconda
Write-Host "`n2. 安装Miniconda..." -ForegroundColor Yellow
$installerPath = "$RepoPath\installers\Miniconda3-latest-Windows-x86_64.exe"
if (-not (Test-Path $installerPath)) {
    Write-Host "错误: 找不到Miniconda安装包: $installerPath" -ForegroundColor Red
    exit 1
}

Write-Host "开始安装Miniconda..." -ForegroundColor White
$installArgs = "/InstallationType=JustMe /AddToPath=1 /RegisterPython=1 /S /D=$InstallPath"
Start-Process -FilePath $installerPath -ArgumentList $installArgs -Wait

# 3. 配置conda环境
Write-Host "`n3. 配置conda环境..." -ForegroundColor Yellow
$condaPath = "$InstallPath\Scripts\conda.exe"
if (-not (Test-Path $condaPath)) {
    Write-Host "错误: conda安装失败" -ForegroundColor Red
    exit 1
}

# 初始化conda
& $condaPath init powershell

# 4. 配置本地镜像源
Write-Host "`n4. 配置本地镜像源..." -ForegroundColor Yellow

# 启动本地HTTP服务器
Write-Host "启动本地HTTP服务器..." -ForegroundColor White
$condaServerJob = Start-Job -ScriptBlock {
    Set-Location $using:RepoPath\conda-packages
    python -m http.server 8080
}

$pipServerJob = Start-Job -ScriptBlock {
    Set-Location $using:RepoPath\pip-packages  
    python -m http.server 8081
}

# 等待服务器启动
Start-Sleep -Seconds 3

# 配置conda镜像源
Write-Host "配置conda镜像源..." -ForegroundColor White
& $condaPath config --add channels http://localhost:8080
& $condaPath config --set show_channel_urls yes

# 配置pip镜像源
Write-Host "配置pip镜像源..." -ForegroundColor White
& $condaPath run pip config set global.index-url http://localhost:8081

# 5. 创建基础环境
Write-Host "`n5. 创建基础环境..." -ForegroundColor Yellow

# 创建科学计算环境
Write-Host "创建科学计算环境..." -ForegroundColor White
$envFile = "$RepoPath\environments\base-scientific.yml"
if (Test-Path $envFile) {
    & $condaPath env create -f $envFile
    Write-Host "科学计算环境创建成功" -ForegroundColor Green
}

# 创建机器学习环境
Write-Host "创建机器学习环境..." -ForegroundColor White
$envFile = "$RepoPath\environments\base-ml.yml"
if (Test-Path $envFile) {
    & $condaPath env create -f $envFile
    Write-Host "机器学习环境创建成功" -ForegroundColor Green
}

# 创建深度学习环境
Write-Host "创建深度学习环境..." -ForegroundColor White
$envFile = "$RepoPath\environments\base-dl.yml"
if (Test-Path $envFile) {
    & $condaPath env create -f $envFile
    Write-Host "深度学习环境创建成功" -ForegroundColor Green
}

# 6. 验证安装
Write-Host "`n6. 验证安装..." -ForegroundColor Yellow

# 检查conda版本
$condaVersion = & $condaPath --version
Write-Host "Conda版本: $condaVersion" -ForegroundColor Green

# 检查Python版本
$pythonVersion = & $condaPath run python --version
Write-Host "Python版本: $pythonVersion" -ForegroundColor Green

# 检查环境列表
Write-Host "`n已创建的环境:" -ForegroundColor White
& $condaPath env list

# 7. 清理和完成
Write-Host "`n7. 部署完成!" -ForegroundColor Green
Write-Host "本地HTTP服务器已启动:" -ForegroundColor White
Write-Host "  - Conda包服务器: http://localhost:8080" -ForegroundColor Cyan
Write-Host "  - Pip包服务器: http://localhost:8081" -ForegroundColor Cyan

Write-Host "`n使用说明:" -ForegroundColor Yellow
Write-Host "1. 激活环境: conda activate base-scientific" -ForegroundColor White
Write-Host "2. 安装包: conda install numpy" -ForegroundColor White
Write-Host "3. 查看环境: conda env list" -ForegroundColor White

Write-Host "`n=== 部署成功完成 ===" -ForegroundColor Green


