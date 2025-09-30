# 环境管理脚本
# 内网机器离线Python环境全自动化管理系统
# AirGap Python Environment Management System
# 功能：导出、导入、对比环境配置

param(
    [string]$Action = "help",  # export, import, compare, list
    [string]$EnvName = "",
    [string]$OutputPath = ".\environments",
    [string]$InputPath = ""
)

function Show-Help {
    Write-Host "=== 环境管理脚本使用说明 ===" -ForegroundColor Green
    Write-Host "用法: .\env-manager.ps1 -Action <action> [参数]" -ForegroundColor White
    Write-Host ""
    Write-Host "操作类型:" -ForegroundColor Yellow
    Write-Host "  export  - 导出环境配置" -ForegroundColor White
    Write-Host "  import  - 导入环境配置" -ForegroundColor White
    Write-Host "  compare - 对比环境配置" -ForegroundColor White
    Write-Host "  list    - 列出所有环境" -ForegroundColor White
    Write-Host ""
    Write-Host "示例:" -ForegroundColor Yellow
    Write-Host "  .\env-manager.ps1 -Action export -EnvName myenv -OutputPath .\exports" -ForegroundColor White
    Write-Host "  .\env-manager.ps1 -Action import -InputPath .\exports\myenv.yml" -ForegroundColor White
    Write-Host "  .\env-manager.ps1 -Action compare -InputPath .\exports\old.yml .\exports\new.yml" -ForegroundColor White
}

function Export-Environment {
    param([string]$EnvName, [string]$OutputPath)
    
    Write-Host "=== 导出环境配置 ===" -ForegroundColor Green
    Write-Host "环境名称: $EnvName" -ForegroundColor White
    Write-Host "输出路径: $OutputPath" -ForegroundColor White
    
    # 创建输出目录
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force
    }
    
    # 生成时间戳
    $timestamp = Get-Date -Format "yyyyMMddHHmm"
    $outputFile = "$OutputPath\$EnvName-$timestamp.yml"
    
    # 导出环境配置
    Write-Host "导出环境配置到: $outputFile" -ForegroundColor Yellow
    conda env export -n $EnvName > $outputFile
    
    if (Test-Path $outputFile) {
        Write-Host "环境配置导出成功!" -ForegroundColor Green
        
        # 创建环境包列表
        $packagesFile = "$OutputPath\$EnvName-$timestamp-packages.txt"
        conda list -n $EnvName > $packagesFile
        Write-Host "包列表导出到: $packagesFile" -ForegroundColor Green
        
        # 创建环境压缩包
        $archiveFile = "$OutputPath\$EnvName-$timestamp.zip"
        Compress-Archive -Path "$outputFile", "$packagesFile" -DestinationPath $archiveFile
        Write-Host "环境压缩包创建: $archiveFile" -ForegroundColor Green
        
        return $outputFile
    } else {
        Write-Host "环境配置导出失败!" -ForegroundColor Red
        return $null
    }
}

function Import-Environment {
    param([string]$InputPath)
    
    Write-Host "=== 导入环境配置 ===" -ForegroundColor Green
    Write-Host "输入文件: $InputPath" -ForegroundColor White
    
    if (-not (Test-Path $InputPath)) {
        Write-Host "错误: 找不到输入文件 $InputPath" -ForegroundColor Red
        return $false
    }
    
    # 从文件名提取环境名
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
    $envName = $fileName -replace '-\d{12}$', ''  # 移除时间戳
    
    Write-Host "环境名称: $envName" -ForegroundColor White
    
    # 导入环境
    Write-Host "导入环境配置..." -ForegroundColor Yellow
    conda env create -f $InputPath
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "环境导入成功!" -ForegroundColor Green
        return $true
    } else {
        Write-Host "环境导入失败!" -ForegroundColor Red
        return $false
    }
}

function Compare-Environments {
    param([string]$OldPath, [string]$NewPath)
    
    Write-Host "=== 对比环境配置 ===" -ForegroundColor Green
    Write-Host "旧环境: $OldPath" -ForegroundColor White
    Write-Host "新环境: $NewPath" -ForegroundColor White
    
    if (-not (Test-Path $OldPath) -or -not (Test-Path $NewPath)) {
        Write-Host "错误: 找不到环境配置文件" -ForegroundColor Red
        return
    }
    
    # 解析环境配置
    $oldConfig = Get-Content $OldPath | ConvertFrom-Yaml
    $newConfig = Get-Content $NewPath | ConvertFrom-Yaml
    
    Write-Host "`n=== 环境差异分析 ===" -ForegroundColor Yellow
    
    # 对比依赖包
    $oldDeps = $oldConfig.dependencies
    $newDeps = $newConfig.dependencies
    
    Write-Host "`n新增的包:" -ForegroundColor Green
    $newPackages = $newDeps | Where-Object { $_ -notin $oldDeps }
    foreach ($pkg in $newPackages) {
        Write-Host "  + $pkg" -ForegroundColor Green
    }
    
    Write-Host "`n移除的包:" -ForegroundColor Red
    $removedPackages = $oldDeps | Where-Object { $_ -notin $newDeps }
    foreach ($pkg in $removedPackages) {
        Write-Host "  - $pkg" -ForegroundColor Red
    }
    
    Write-Host "`n=== 差异分析完成 ===" -ForegroundColor Green
}

function List-Environments {
    Write-Host "=== 环境列表 ===" -ForegroundColor Green
    conda env list
}

# 主逻辑
switch ($Action.ToLower()) {
    "export" {
        if (-not $EnvName) {
            Write-Host "错误: 导出环境需要指定环境名称" -ForegroundColor Red
            Show-Help
            exit 1
        }
        Export-Environment -EnvName $EnvName -OutputPath $OutputPath
    }
    "import" {
        if (-not $InputPath) {
            Write-Host "错误: 导入环境需要指定输入文件路径" -ForegroundColor Red
            Show-Help
            exit 1
        }
        Import-Environment -InputPath $InputPath
    }
    "compare" {
        if (-not $InputPath) {
            Write-Host "错误: 对比环境需要指定两个配置文件路径" -ForegroundColor Red
            Show-Help
            exit 1
        }
        $paths = $InputPath -split ' '
        if ($paths.Count -ne 2) {
            Write-Host "错误: 对比需要两个文件路径" -ForegroundColor Red
            exit 1
        }
        Compare-Environments -OldPath $paths[0] -NewPath $paths[1]
    }
    "list" {
        List-Environments
    }
    default {
        Show-Help
    }
}


