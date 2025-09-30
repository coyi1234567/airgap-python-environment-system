# 批量更新脚本文件中的项目引用
# Batch update project references in script files

param(
    [string]$ScriptsPath = ".",
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

function Update-ScriptFile {
    param(
        [string]$FilePath,
        [switch]$DryRun
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Log "文件不存在: $FilePath" "ERROR"
        return $false
    }
    
    try {
        $content = Get-Content $FilePath -Raw -Encoding UTF8
        $originalContent = $content
        
        # 更新项目名称引用
        $content = $content -replace "内网机器离线Python环境全自动化管理系统", "内网机器离线Python环境全自动化管理系统"
        $content = $content -replace "offline-python-environment", "airgap-python-environment-system"
        $content = $content -replace "offline-repo", "python-airgap-repo"
        
        # 检查是否有变化
        if ($content -ne $originalContent) {
            if (-not $DryRun) {
                Set-Content -Path $FilePath -Value $content -Encoding UTF8
                Write-Log "更新完成: $FilePath" "SUCCESS"
            } else {
                Write-Log "[DRY RUN] 将更新: $FilePath" "INFO"
            }
            return $true
        } else {
            Write-Log "无需更新: $FilePath" "INFO"
            return $false
        }
    } catch {
        Write-Log "更新失败: $FilePath - $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Start-ScriptUpdate {
    Write-Log "=== 开始批量更新脚本文件 ===" "INFO"
    Write-Log "脚本路径: $ScriptsPath" "INFO"
    Write-Log "试运行模式: $DryRun" "INFO"
    
    $scriptFiles = Get-ChildItem -Path $ScriptsPath -Filter "*.ps1" -Recurse
    
    if ($scriptFiles.Count -eq 0) {
        Write-Log "未找到PowerShell脚本文件" "WARNING"
        return $false
    }
    
    Write-Log "找到 $($scriptFiles.Count) 个脚本文件" "SUCCESS"
    
    $updatedCount = 0
    $totalCount = $scriptFiles.Count
    
    foreach ($scriptFile in $scriptFiles) {
        Write-Log "处理文件: $($scriptFile.Name)" "INFO"
        $result = Update-ScriptFile -FilePath $scriptFile.FullName -DryRun:$DryRun
        if ($result) {
            $updatedCount++
        }
    }
    
    Write-Log "`n=== 更新完成 ===" "SUCCESS"
    Write-Log "总文件数: $totalCount" "INFO"
    Write-Log "更新文件数: $updatedCount" "SUCCESS"
    Write-Log "跳过文件数: $($totalCount - $updatedCount)" "INFO"
    
    return $true
}

# 主执行逻辑
if ($MyInvocation.InvocationName -ne '.') {
    Start-ScriptUpdate
}

