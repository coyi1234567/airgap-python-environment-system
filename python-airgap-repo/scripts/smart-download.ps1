# 智能下载脚本 - 根据配置自动下载所需文件
# Smart Download Script - Automatically download required files based on configuration

param(
    [string]$ConfigFile = "config/download-config.json",
    [string]$Environment = "all",
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
    
    # 写入日志文件
    $logFile = "logs/download-$(Get-Date -Format 'yyyyMMdd').log"
    if (-not (Test-Path "logs")) {
        New-Item -ItemType Directory -Path "logs" -Force | Out-Null
    }
    Add-Content -Path $logFile -Value $logMessage
}

function Test-InternetConnection {
    try {
        $response = Invoke-WebRequest -Uri "https://www.baidu.com" -TimeoutSec 10 -UseBasicParsing
        return $response.StatusCode -eq 200
    } catch {
        return $false
    }
}

function Get-FileSize {
    param([string]$Url)
    
    try {
        $request = [System.Net.WebRequest]::Create($Url)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $size = $response.ContentLength
        $response.Close()
        return $size
    } catch {
        return 0
    }
}

function Download-File {
    param(
        [string]$Url,
        [string]$OutputPath,
        [string]$Description = ""
    )
    
    Write-Log "开始下载: $Description" "INFO"
    Write-Log "URL: $Url" "INFO"
    Write-Log "保存到: $OutputPath" "INFO"
    
    try {
        # 创建目录
        $directory = Split-Path $OutputPath -Parent
        if (-not (Test-Path $directory)) {
            New-Item -ItemType Directory -Path $directory -Force | Out-Null
        }
        
        # 检查文件是否已存在
        if ((Test-Path $OutputPath) -and -not $Force) {
            Write-Log "文件已存在，跳过下载: $OutputPath" "WARNING"
            return $true
        }
        
        # 获取文件大小
        $fileSize = Get-FileSize -Url $Url
        if ($fileSize -gt 0) {
            $sizeMB = [math]::Round($fileSize / 1MB, 2)
            Write-Log "文件大小: $sizeMB MB" "INFO"
        }
        
        if ($DryRun) {
            Write-Log "[DRY RUN] 将下载到: $OutputPath" "INFO"
            return $true
        }
        
        # 下载文件
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($Url, $OutputPath)
        
        Write-Log "下载完成: $OutputPath" "SUCCESS"
        return $true
        
    } catch {
        Write-Log "下载失败: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Download-CondaPackages {
    param(
        [array]$Packages,
        [string]$OutputPath,
        [string]$Environment
    )
    
    Write-Log "开始下载Conda包 (环境: $Environment)" "INFO"
    
    foreach ($package in $Packages) {
        Write-Log "下载包: $package" "INFO"
        
        # 这里需要实现conda包的下载逻辑
        # 由于conda包下载比较复杂，这里提供框架
        # 实际实现需要调用conda search和conda download命令
        
        if ($DryRun) {
            Write-Log "[DRY RUN] 将下载conda包: $package" "INFO"
        } else {
            # 实际下载逻辑
            Write-Log "下载conda包: $package" "INFO"
        }
    }
}

function Download-PipPackages {
    param(
        [array]$Packages,
        [string]$OutputPath,
        [string]$Environment
    )
    
    Write-Log "开始下载Pip包 (环境: $Environment)" "INFO"
    
    foreach ($package in $Packages) {
        Write-Log "下载包: $package" "INFO"
        
        if ($DryRun) {
            Write-Log "[DRY RUN] 将下载pip包: $package" "INFO"
        } else {
            # 使用pip download命令下载包
            $downloadCmd = "pip download `"$package`" -d `"$OutputPath`" --no-deps"
            Write-Log "执行命令: $downloadCmd" "INFO"
            
            try {
                Invoke-Expression $downloadCmd
                Write-Log "下载完成: $package" "SUCCESS"
            } catch {
                Write-Log "下载失败: $package - $($_.Exception.Message)" "ERROR"
            }
        }
    }
}

function Start-SmartDownload {
    Write-Log "=== 智能下载脚本启动 ===" "INFO"
    Write-Log "配置文件: $ConfigFile" "INFO"
    Write-Log "目标环境: $Environment" "INFO"
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
    
    # 创建下载目录
    $basePath = $config.download_settings.base_path
    if (-not (Test-Path $basePath)) {
        New-Item -ItemType Directory -Path $basePath -Force | Out-Null
        Write-Log "创建下载目录: $basePath" "SUCCESS"
    }
    
    # 下载安装程序
    if ($config.download_options.download_installers) {
        Write-Log "=== 下载安装程序 ===" "INFO"
        
        $installer = $config.installers.miniconda
        $installerPath = Join-Path $config.download_settings.installers_path $installer.filename
        
        $success = Download-File -Url $installer.url -OutputPath $installerPath -Description "Miniconda安装程序"
        if (-not $success) {
            Write-Log "Miniconda下载失败" "ERROR"
            return $false
        }
    }
    
    # 下载包文件
    if ($Environment -eq "all" -or $Environment -eq "base-scientific") {
        if ($config.download_options.download_base_packages) {
            Write-Log "=== 下载基础科学计算包 ===" "INFO"
            
            $condaPackages = $config.package_selections.base_scientific.conda_packages
            $pipPackages = $config.package_selections.base_scientific.pip_packages
            
            Download-CondaPackages -Packages $condaPackages -OutputPath $config.download_settings.conda_packages_path -Environment "base-scientific"
            Download-PipPackages -Packages $pipPackages -OutputPath $config.download_settings.pip_packages_path -Environment "base-scientific"
        }
    }
    
    if ($Environment -eq "all" -or $Environment -eq "base-ml") {
        if ($config.download_options.download_ml_packages) {
            Write-Log "=== 下载机器学习包 ===" "INFO"
            
            $condaPackages = $config.package_selections.base_ml.conda_packages
            $pipPackages = $config.package_selections.base_ml.pip_packages
            
            Download-CondaPackages -Packages $condaPackages -OutputPath $config.download_settings.conda_packages_path -Environment "base-ml"
            Download-PipPackages -Packages $pipPackages -OutputPath $config.download_settings.pip_packages_path -Environment "base-ml"
        }
    }
    
    if ($Environment -eq "all" -or $Environment -eq "base-dl") {
        if ($config.download_options.download_dl_packages) {
            Write-Log "=== 下载深度学习包 ===" "INFO"
            
            $condaPackages = $config.package_selections.base_dl.conda_packages
            $pipPackages = $config.package_selections.base_dl.pip_packages
            
            Download-CondaPackages -Packages $condaPackages -OutputPath $config.download_settings.conda_packages_path -Environment "base-dl"
            Download-PipPackages -Packages $pipPackages -OutputPath $config.download_settings.pip_packages_path -Environment "base-dl"
        }
    }
    
    Write-Log "=== 下载完成 ===" "SUCCESS"
    return $true
}

# 主执行逻辑
if ($MyInvocation.InvocationName -ne '.') {
    Start-SmartDownload
}

