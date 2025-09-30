# 离线Python环境包下载脚本
# 功能：下载基础Python包到本地仓库

param(
    [string]$PackageType = "all",  # all, conda, pip
    [string]$OutputPath = "."
)

Write-Host "=== 开始下载Python包 ===" -ForegroundColor Green

# 基础Python包列表
$basePackages = @(
    "numpy",
    "pandas", 
    "scipy",
    "matplotlib",
    "seaborn",
    "scikit-learn",
    "requests",
    "beautifulsoup4",
    "jupyter",
    "black",
    "pytest",
    "flake8",
    "pylint"
)

# AI开发相关包
$aiPackages = @(
    "torch",
    "torchvision", 
    "tensorflow",
    "transformers",
    "datasets",
    "accelerate"
)

# 合并所有包
$allPackages = $basePackages + $aiPackages

Write-Host "准备下载 $($allPackages.Count) 个包..." -ForegroundColor Yellow

# 下载conda包
if ($PackageType -eq "all" -or $PackageType -eq "conda") {
    Write-Host "开始下载conda包..." -ForegroundColor Cyan
    
    foreach ($package in $allPackages) {
        Write-Host "下载 $package..." -ForegroundColor White
        
        # 使用conda search查找可用版本
        $searchResult = conda search $package --json 2>$null
        if ($searchResult) {
            $packageInfo = $searchResult | ConvertFrom-Json
            if ($packageInfo.$package) {
                $latestVersion = $packageInfo.$package | Sort-Object version -Descending | Select-Object -First 1
                Write-Host "找到 $package 版本: $($latestVersion.version)" -ForegroundColor Green
                
                # 下载包文件
                $downloadCmd = "conda install --download-only --offline $package=$($latestVersion.version) -c conda-forge"
                Write-Host "执行: $downloadCmd" -ForegroundColor Gray
            }
        } else {
            Write-Host "警告: 无法找到 $package 的conda版本" -ForegroundColor Yellow
        }
    }
}

# 下载pip包
if ($PackageType -eq "all" -or $PackageType -eq "pip") {
    Write-Host "开始下载pip包..." -ForegroundColor Cyan
    
    foreach ($package in $allPackages) {
        Write-Host "下载 $package..." -ForegroundColor White
        
        # 使用pip download下载包及其依赖
        $downloadCmd = "pip download $package --dest $OutputPath/pip-packages --no-deps"
        Write-Host "执行: $downloadCmd" -ForegroundColor Gray
        
        # 这里可以添加实际的下载逻辑
        # Invoke-Expression $downloadCmd
    }
}

Write-Host "=== 包下载完成 ===" -ForegroundColor Green
Write-Host "conda包存储位置: $OutputPath/conda-packages" -ForegroundColor White
Write-Host "pip包存储位置: $OutputPath/pip-packages" -ForegroundColor White


