# 项目分析脚本 - 分析项目配置文件，生成去重下载清单
# Project Analyzer Script - Analyze project config files and generate deduplicated download list

param(
    [string]$ProjectPath = "",
    [string]$OutputPath = "download-list.json",
    [switch]$AnalyzeAll = $false,
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

function Find-ProjectConfigFiles {
    param([string]$ProjectPath)
    
    $configFiles = @()
    
    # 常见的项目配置文件
    $configPatterns = @(
        "requirements.txt",
        "environment.yml",
        "conda-environment.yml",
        "pyproject.toml",
        "setup.py",
        "Pipfile",
        "poetry.lock",
        "environment.yaml",
        "*.yml",
        "*.yaml"
    )
    
    foreach ($pattern in $configPatterns) {
        $files = Get-ChildItem -Path $ProjectPath -Filter $pattern -Recurse -ErrorAction SilentlyContinue
        $configFiles += $files
    }
    
    return $configFiles
}

function Parse-RequirementsTxt {
    param([string]$FilePath)
    
    $packages = @()
    
    try {
        $content = Get-Content $FilePath -ErrorAction Stop
        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -and -not $line.StartsWith("#") -and -not $line.StartsWith("-")) {
                # 处理各种格式的包名
                $package = $line -replace "==.*", "" -replace ">=.*", "" -replace "<=.*", "" -replace "~=.*", "" -replace "!=.*", ""
                $package = $package.Trim()
                if ($package) {
                    $packages += @{
                        Name = $package
                        Source = "pip"
                        File = $FilePath
                        OriginalLine = $line
                    }
                }
            }
        }
    } catch {
        Write-Log "解析requirements.txt失败: $($_.Exception.Message)" "ERROR"
    }
    
    return $packages
}

function Parse-CondaEnvironment {
    param([string]$FilePath)
    
    $packages = @()
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        $yaml = $content | ConvertFrom-Yaml
        
        # 解析conda包
        if ($yaml.dependencies) {
            foreach ($dep in $yaml.dependencies) {
                if ($dep -is [string]) {
                    $package = $dep -replace "==.*", "" -replace ">=.*", "" -replace "<=.*", "" -replace "~=.*", ""
                    $package = $package.Trim()
                    if ($package) {
                        $packages += @{
                            Name = $package
                            Source = "conda"
                            File = $FilePath
                            OriginalLine = $dep
                        }
                    }
                }
            }
        }
        
        # 解析pip包
        if ($yaml.dependencies) {
            foreach ($dep in $yaml.dependencies) {
                if ($dep -is [hashtable] -and $dep.pip) {
                    foreach ($pipDep in $dep.pip) {
                        $package = $pipDep -replace "==.*", "" -replace ">=.*", "" -replace "<=.*", "" -replace "~=.*", ""
                        $package = $package.Trim()
                        if ($package) {
                            $packages += @{
                                Name = $package
                                Source = "pip"
                                File = $FilePath
                                OriginalLine = $pipDep
                            }
                        }
                    }
                }
            }
        }
    } catch {
        Write-Log "解析conda环境文件失败: $($_.Exception.Message)" "ERROR"
    }
    
    return $packages
}

function Parse-PyProjectToml {
    param([string]$FilePath)
    
    $packages = @()
    
    try {
        $content = Get-Content $FilePath -Raw -ErrorAction Stop
        
        # 简单的TOML解析（这里可以改进为更完整的解析）
        if ($content -match '\[tool\.poetry\.dependencies\]') {
            $depsSection = $content -split '\[tool\.poetry\.dependencies\]' | Select-Object -Last 1
            $depsSection = $depsSection -split '\[.*\]' | Select-Object -First 1
            
            $lines = $depsSection -split "`n"
            foreach ($line in $lines) {
                if ($line -match '^(\w+)\s*=') {
                    $package = $matches[1].Trim()
                    $packages += @{
                        Name = $package
                        Source = "pip"
                        File = $FilePath
                        OriginalLine = $line
                    }
                }
            }
        }
    } catch {
        Write-Log "解析pyproject.toml失败: $($_.Exception.Message)" "ERROR"
    }
    
    return $packages
}

function Analyze-ProjectConfig {
    param([string]$FilePath)
    
    $packages = @()
    $fileName = Split-Path $FilePath -Leaf
    
    switch ($fileName.ToLower()) {
        "requirements.txt" {
            $packages = Parse-RequirementsTxt -FilePath $FilePath
        }
        { $_ -match "environment\.ya?ml$" } {
            $packages = Parse-CondaEnvironment -FilePath $FilePath
        }
        "pyproject.toml" {
            $packages = Parse-PyProjectToml -FilePath $FilePath
        }
        default {
            Write-Log "不支持的文件类型: $fileName" "WARNING"
        }
    }
    
    return $packages
}

function Merge-PackageLists {
    param([array]$AllPackages)
    
    $mergedPackages = @{}
    $duplicates = @()
    
    foreach ($package in $AllPackages) {
        $key = $package.Name.ToLower()
        
        if ($mergedPackages.ContainsKey($key)) {
            # 发现重复包
            $existing = $mergedPackages[$key]
            $duplicates += @{
                Package = $package.Name
                Sources = @($existing.Source, $package.Source)
                Files = @($existing.File, $package.File)
                OriginalLines = @($existing.OriginalLine, $package.OriginalLine)
            }
            
            # 优先选择conda包（如果存在）
            if ($package.Source -eq "conda" -and $existing.Source -eq "pip") {
                $mergedPackages[$key] = $package
            }
        } else {
            $mergedPackages[$key] = $package
        }
    }
    
    return @{
        UniquePackages = $mergedPackages.Values
        Duplicates = $duplicates
    }
}

function Generate-DownloadList {
    param(
        [array]$Packages,
        [string]$OutputPath
    )
    
    $downloadList = @{
        generated_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        total_packages = $Packages.Count
        conda_packages = @()
        pip_packages = @()
        summary = @{
            conda_count = 0
            pip_count = 0
        }
    }
    
    foreach ($package in $Packages) {
        if ($package.Source -eq "conda") {
            $downloadList.conda_packages += $package.Name
            $downloadList.summary.conda_count++
        } else {
            $downloadList.pip_packages += $package.Name
            $downloadList.summary.pip_count++
        }
    }
    
    # 去重
    $downloadList.conda_packages = $downloadList.conda_packages | Sort-Object | Get-Unique
    $downloadList.pip_packages = $downloadList.pip_packages | Sort-Object | Get-Unique
    
    # 更新计数
    $downloadList.summary.conda_count = $downloadList.conda_packages.Count
    $downloadList.summary.pip_count = $downloadList.pip_packages.Count
    $downloadList.total_packages = $downloadList.summary.conda_count + $downloadList.summary.pip_count
    
    if (-not $DryRun) {
        $downloadList | ConvertTo-Json -Depth 10 | Set-Content $OutputPath -Encoding UTF8
        Write-Log "下载清单已生成: $OutputPath" "SUCCESS"
    } else {
        Write-Log "[DRY RUN] 下载清单将生成到: $OutputPath" "INFO"
    }
    
    return $downloadList
}

function Start-ProjectAnalysis {
    Write-Log "=== 项目配置文件分析器 ===" "INFO"
    Write-Log "项目路径: $ProjectPath" "INFO"
    Write-Log "输出路径: $OutputPath" "INFO"
    Write-Log "分析所有文件: $AnalyzeAll" "INFO"
    Write-Log "试运行模式: $DryRun" "INFO"
    
    if (-not $ProjectPath) {
        $ProjectPath = Get-Location
        Write-Log "未指定项目路径，使用当前目录: $ProjectPath" "INFO"
    }
    
    if (-not (Test-Path $ProjectPath)) {
        Write-Log "项目路径不存在: $ProjectPath" "ERROR"
        return $false
    }
    
    # 查找配置文件
    Write-Log "`n=== 查找项目配置文件 ===" "INFO"
    $configFiles = Find-ProjectConfigFiles -ProjectPath $ProjectPath
    
    if ($configFiles.Count -eq 0) {
        Write-Log "未找到项目配置文件" "WARNING"
        return $false
    }
    
    Write-Log "找到 $($configFiles.Count) 个配置文件:" "SUCCESS"
    foreach ($file in $configFiles) {
        Write-Host "  📄 $($file.FullName)" -ForegroundColor Cyan
    }
    
    # 分析配置文件
    Write-Log "`n=== 分析配置文件 ===" "INFO"
    $allPackages = @()
    
    foreach ($file in $configFiles) {
        Write-Log "分析文件: $($file.Name)" "INFO"
        $packages = Analyze-ProjectConfig -FilePath $file.FullName
        
        if ($packages.Count -gt 0) {
            Write-Log "  找到 $($packages.Count) 个包" "SUCCESS"
            $allPackages += $packages
        } else {
            Write-Log "  未找到包信息" "WARNING"
        }
    }
    
    if ($allPackages.Count -eq 0) {
        Write-Log "未找到任何包信息" "ERROR"
        return $false
    }
    
    # 合并和去重
    Write-Log "`n=== 合并和去重 ===" "INFO"
    $merged = Merge-PackageLists -AllPackages $allPackages
    
    Write-Log "总包数: $($allPackages.Count)" "INFO"
    Write-Log "去重后: $($merged.UniquePackages.Count)" "SUCCESS"
    
    if ($merged.Duplicates.Count -gt 0) {
        Write-Log "发现 $($merged.Duplicates.Count) 个重复包:" "WARNING"
        foreach ($dup in $merged.Duplicates) {
            Write-Host "  🔄 $($dup.Package) (来源: $($dup.Sources -join ', '))" -ForegroundColor Yellow
        }
    }
    
    # 生成下载清单
    Write-Log "`n=== 生成下载清单 ===" "INFO"
    $downloadList = Generate-DownloadList -Packages $merged.UniquePackages -OutputPath $OutputPath
    
    # 显示摘要
    Write-Log "`n=== 分析摘要 ===" "INFO"
    Write-Host "📊 包统计:" -ForegroundColor Cyan
    Write-Host "  总包数: $($downloadList.total_packages)" -ForegroundColor White
    Write-Host "  Conda包: $($downloadList.summary.conda_count)" -ForegroundColor White
    Write-Host "  Pip包: $($downloadList.summary.pip_count)" -ForegroundColor White
    
    if ($merged.Duplicates.Count -gt 0) {
        Write-Host "  重复包: $($merged.Duplicates.Count)" -ForegroundColor Yellow
    }
    
    Write-Log "`n=== 分析完成 ===" "SUCCESS"
    return $true
}

# 主执行逻辑
if ($MyInvocation.InvocationName -ne '.') {
    Start-ProjectAnalysis
}
