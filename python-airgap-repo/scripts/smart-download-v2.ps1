# 智能下载脚本 V2 - 基于项目分析结果的去重下载
# Smart Download Script V2 - Deduplicated download based on project analysis

param(
    [string]$ProjectPath = "",
    [string]$DownloadListFile = "download-list.json",
    [string]$ConfigFile = "config/download-config.json",
    [switch]$AnalyzeProject = $false,
    [switch]$Force = $false,
    [switch]$DryRun = $false
)

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    switch ($Level) {
        "ERROR" { Write-Host $logMessage -ForegroundColor Red }
        "WARNING" { Write-Host $logMessage -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $logMessage -ForegroundColor Green }
        default { Write-Host $logMessage -ForegroundColor White }
    }
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-ExistingPackages {
    param(
        [string]$CondaPath,
        [string]$PipPath
    )
    
    $existingPackages = @{
        conda = @()
        pip = @()
    }
    
    # 检查已存在的conda包
    if (Test-Path $CondaPath) {
        $condaFiles = Get-ChildItem -Path $CondaPath -Recurse -Filter "*.tar.bz2" -ErrorAction SilentlyContinue
        foreach ($file in $condaFiles) {
            $packageName = $file.BaseName -replace "-\d+.*", ""
            $existingPackages.conda += $packageName
        }
    }
    
    # 检查已存在的pip包
    if (Test-Path $PipPath) {
        $pipFiles = Get-ChildItem -Path $PipPath -Recurse -Filter "*.whl" -ErrorAction SilentlyContinue
        foreach ($file in $pipFiles) {
            $packageName = $file.BaseName -replace "-\d+.*", ""
            $existingPackages.pip += $packageName
        }
    }
    
    return $existingPackages
}

function Download-CondaPackage {
    param(
        [string]$PackageName,
        [string]$OutputPath,
        [string]$MirrorUrl
    )
    
    Write-Log "下载Conda包: $PackageName" "INFO"
    
    try {
        # 创建目录
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        if ($DryRun) {
            Write-Log "[DRY RUN] 将下载conda包: $PackageName" "INFO"
            return $true
        }
        
        # 使用conda search查找包
        $searchCmd = "conda search $PackageName --json"
        $searchResult = Invoke-Expression $searchCmd 2>$null
        
        if ($searchResult) {
            $searchData = $searchResult | ConvertFrom-Json
            if ($searchData.$PackageName) {
                $latestVersion = $searchData.$PackageName | Sort-Object version -Descending | Select-Object -First 1
                
                # 使用conda download下载包
                $downloadCmd = "conda download $PackageName=$($latestVersion.version) -c $MirrorUrl -o $OutputPath --no-deps"
                Write-Log "执行命令: $downloadCmd" "INFO"
                
                Invoke-Expression $downloadCmd
                Write-Log "Conda包下载完成: $PackageName" "SUCCESS"
                return $true
            }
        }
        
        Write-Log "未找到Conda包: $PackageName" "WARNING"
        return $false
        
    } catch {
        Write-Log "下载Conda包失败: $PackageName - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Download-PipPackage {
    param(
        [string]$PackageName,
        [string]$OutputPath,
        [string]$MirrorUrl
    )
    
    Write-Log "下载Pip包: $PackageName" "INFO"
    
    try {
        # 创建目录
        if (-not (Test-Path $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }
        
        if ($DryRun) {
            Write-Log "[DRY RUN] 将下载pip包: $PackageName" "INFO"
            return $true
        }
        
        # 使用pip download下载包
        $downloadCmd = "pip download `"$PackageName`" -d `"$OutputPath`" -i `"$MirrorUrl`" --no-deps"
        Write-Log "执行命令: $downloadCmd" "INFO"
        
        Invoke-Expression $downloadCmd
        Write-Log "Pip包下载完成: $PackageName" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "下载Pip包失败: $PackageName - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-SmartDownloadV2 {
    Write-Log "=== 智能下载脚本 V2 ===" "INFO"
    Write-Log "项目路径: $ProjectPath" "INFO"
    Write-Log "下载清单文件: $DownloadListFile" "INFO"
    Write-Log "配置文件: $ConfigFile" "INFO"
    Write-Log "分析项目: $AnalyzeProject" "INFO"
    Write-Log "强制下载: $Force" "INFO"
    Write-Log "试运行模式: $DryRun" "INFO"
    
    # 检查网络连接
    if (-not (Test-InternetConnection)) {
        Write-Log "网络连接失败，无法下载文件" "ERROR"
        return $false
    }
    
    # 读取配置文件
    if (-not (Test-Path $ConfigFile)) {
        Write-Log "配置文件不存在: $ConfigFile" "ERROR"
        return $false
    }
    
    try {
        $config = Get-Content $ConfigFile | ConvertFrom-Json
        Write-Log "配置文件加载成功" "SUCCESS"
    } catch {
        Write-Log "配置文件格式错误: $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # 分析项目（如果需要）
    if ($AnalyzeProject -or -not (Test-Path $DownloadListFile)) {
        Write-Log "`n=== 分析项目配置文件 ===" "INFO"
        
        if (-not $ProjectPath) {
            $ProjectPath = Get-Location
        }
        
        $analyzeCmd = ".\scripts\project-analyzer.ps1 -ProjectPath `"$ProjectPath`" -OutputPath `"$DownloadListFile`""
        if ($DryRun) {
            $analyzeCmd += " -DryRun"
        }
        
        Write-Log "执行项目分析: $analyzeCmd" "INFO"
        Invoke-Expression $analyzeCmd
        
        if (-not (Test-Path $DownloadListFile)) {
            Write-Log "项目分析失败，无法生成下载清单" "ERROR"
            return $false
        }
    }
    
    # 读取下载清单
    try {
        $downloadList = Get-Content $DownloadListFile | ConvertFrom-Json
        Write-Log "下载清单加载成功" "SUCCESS"
    } catch {
        Write-Log "下载清单格式错误: $($_.Exception.Message)" "ERROR"
        return $false
    }
    
    # 获取已存在的包
    Write-Log "`n=== 检查已存在的包 ===" "INFO"
    $existingPackages = Get-ExistingPackages -CondaPath $config.download_settings.conda_packages_path -PipPath $config.download_settings.pip_packages_path
    
    Write-Log "已存在Conda包: $($existingPackages.conda.Count) 个" "INFO"
    Write-Log "已存在Pip包: $($existingPackages.pip.Count) 个" "INFO"
    
    # 过滤需要下载的包
    $condaToDownload = @()
    $pipToDownload = @()
    
    foreach ($package in $downloadList.conda_packages) {
        if ($Force -or $existingPackages.conda -notcontains $package.ToLower()) {
            $condaToDownload += $package
        } else {
            Write-Log "跳过已存在的Conda包: $package" "INFO"
        }
    }
    
    foreach ($package in $downloadList.pip_packages) {
        if ($Force -or $existingPackages.pip -notcontains $package.ToLower()) {
            $pipToDownload += $package
        } else {
            Write-Log "跳过已存在的Pip包: $package" "INFO"
        }
    }
    
    Write-Log "`n=== 下载统计 ===" "INFO"
    Write-Host "📊 下载计划:" -ForegroundColor Cyan
    Write-Host "  需要下载的Conda包: $($condaToDownload.Count)" -ForegroundColor White
    Write-Host "  需要下载的Pip包: $($pipToDownload.Count)" -ForegroundColor White
    Write-Host "  跳过的Conda包: $($downloadList.conda_packages.Count - $condaToDownload.Count)" -ForegroundColor Gray
    Write-Host "  跳过的Pip包: $($downloadList.pip_packages.Count - $pipToDownload.Count)" -ForegroundColor Gray
    
    # 下载Conda包
    if ($condaToDownload.Count -gt 0) {
        Write-Log "`n=== 下载Conda包 ===" "INFO"
        $condaSuccess = 0
        $condaFailed = 0
        
        foreach ($package in $condaToDownload) {
            $success = Download-CondaPackage -PackageName $package -OutputPath $config.download_settings.conda_packages_path -MirrorUrl $config.mirror_settings.conda_mirror
            if ($success) {
                $condaSuccess++
            } else {
                $condaFailed++
            }
        }
        
        Write-Log "Conda包下载完成: 成功 $condaSuccess, 失败 $condaFailed" "INFO"
    }
    
    # 下载Pip包
    if ($pipToDownload.Count -gt 0) {
        Write-Log "`n=== 下载Pip包 ===" "INFO"
        $pipSuccess = 0
        $pipFailed = 0
        
        foreach ($package in $pipToDownload) {
            $success = Download-PipPackage -PackageName $package -OutputPath $config.download_settings.pip_packages_path -MirrorUrl $config.mirror_settings.pip_mirror
            if ($success) {
                $pipSuccess++
            } else {
                $pipFailed++
            }
        }
        
        Write-Log "Pip包下载完成: 成功 $pipSuccess, 失败 $pipFailed" "INFO"
    }
    
    # 生成下载报告
    $report = @{
        download_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        project_path = $ProjectPath
        total_conda_packages = $downloadList.conda_packages.Count
        total_pip_packages = $downloadList.pip_packages.Count
        downloaded_conda = $condaToDownload.Count
        downloaded_pip = $pipToDownload.Count
        skipped_conda = $downloadList.conda_packages.Count - $condaToDownload.Count
        skipped_pip = $downloadList.pip_packages.Count - $pipToDownload.Count
        success_rate = if (($condaToDownload.Count + $pipToDownload.Count) -gt 0) { 
            [math]::Round((($condaSuccess + $pipSuccess) / ($condaToDownload.Count + $pipToDownload.Count)) * 100, 1) 
        } else { 100 }
    }
    
    $reportPath = "download-report-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $report | ConvertTo-Json -Depth 10 | Set-Content $reportPath -Encoding UTF8
    Write-Log "下载报告已生成: $reportPath" "SUCCESS"
    
    Write-Log "`n=== 下载完成 ===" "SUCCESS"
    Write-Host "📊 最终统计:" -ForegroundColor Cyan
    Write-Host "  成功率: $($report.success_rate)%" -ForegroundColor White
    Write-Host "  总包数: $($report.total_conda_packages + $report.total_pip_packages)" -ForegroundColor White
    Write-Host "  已下载: $($report.downloaded_conda + $report.downloaded_pip)" -ForegroundColor White
    Write-Host "  已跳过: $($report.skipped_conda + $report.skipped_pip)" -ForegroundColor White
    
    return $true
}

# 主执行逻辑
if ($MyInvocation.InvocationName -ne '.') {
    Start-SmartDownloadV2
}
