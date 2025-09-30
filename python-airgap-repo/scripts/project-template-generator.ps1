# 项目模板生成器 - 为不同类型的项目生成标准配置文件
# Project Template Generator - Generate standard config files for different project types

param(
    [string]$ProjectName = "",
    [string]$ProjectType = "",
    [string]$OutputPath = "",
    [switch]$Interactive = $false
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

function Get-ProjectTemplates {
    return @{
        "ai-ml" = @{
            Name = "AI/机器学习项目"
            Description = "包含深度学习、机器学习常用包的完整环境"
            Files = @("requirements.txt", "environment.yml", "pyproject.toml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0",
                    "matplotlib>=3.6.0",
                    "seaborn>=0.12.0",
                    "jupyter>=1.0.0",
                    "scikit-learn>=1.3.0"
                )
                pip = @(
                    "torch>=2.0.0",
                    "torchvision>=0.15.0",
                    "tensorflow>=2.13.0",
                    "transformers>=4.30.0",
                    "datasets>=2.12.0",
                    "accelerate>=0.20.0",
                    "wandb>=0.15.0",
                    "optuna>=3.0.0",
                    "mlflow>=2.5.0"
                )
            }
        }
        "web-api" = @{
            Name = "Web API项目"
            Description = "FastAPI、Flask等Web框架的完整环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0"
                )
                pip = @(
                    "fastapi>=0.100.0",
                    "uvicorn>=0.20.0",
                    "pydantic>=2.0.0",
                    "sqlalchemy>=2.0.0",
                    "alembic>=1.11.0",
                    "redis>=4.5.0",
                    "celery>=5.3.0",
                    "pytest>=7.0.0",
                    "httpx>=0.24.0"
                )
            }
        }
        "data-science" = @{
            Name = "数据科学项目"
            Description = "数据分析、可视化的完整环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0",
                    "matplotlib>=3.6.0",
                    "seaborn>=0.12.0",
                    "jupyter>=1.0.0",
                    "scipy>=1.10.0",
                    "scikit-learn>=1.3.0"
                )
                pip = @(
                    "plotly>=5.15.0",
                    "bokeh>=3.2.0",
                    "dash>=2.11.0",
                    "streamlit>=1.25.0",
                    "jupyter-dash>=0.4.0",
                    "altair>=5.0.0",
                    "statsmodels>=0.14.0"
                )
            }
        }
        "nlp" = @{
            Name = "自然语言处理项目"
            Description = "NLP、文本处理的完整环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0"
                )
                pip = @(
                    "transformers>=4.30.0",
                    "tokenizers>=0.13.0",
                    "datasets>=2.12.0",
                    "nltk>=3.8.0",
                    "spacy>=3.6.0",
                    "jieba>=0.42.1",
                    "sentencepiece>=0.1.99",
                    "protobuf>=3.20.0",
                    "torch>=2.0.0",
                    "accelerate>=0.20.0"
                )
            }
        }
        "computer-vision" = @{
            Name = "计算机视觉项目"
            Description = "图像处理、计算机视觉的完整环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0"
                )
                pip = @(
                    "torch>=2.0.0",
                    "torchvision>=0.15.0",
                    "opencv-python>=4.8.0",
                    "pillow>=10.0.0",
                    "scikit-image>=0.21.0",
                    "albumentations>=1.3.0",
                    "timm>=0.9.0",
                    "transformers>=4.30.0",
                    "accelerate>=0.20.0"
                )
            }
        }
        "chatglm" = @{
            Name = "ChatGLM项目"
            Description = "ChatGLM模型开发和部署环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0"
                )
                pip = @(
                    "torch>=2.0.0",
                    "transformers>=4.30.0",
                    "tokenizers>=0.13.0",
                    "accelerate>=0.20.0",
                    "cpm-kernels>=1.0.11",
                    "chatglm-cpp>=0.2.0",
                    "sentencepiece>=0.1.99",
                    "protobuf>=3.20.0",
                    "vllm>=0.2.0",
                    "fastapi>=0.100.0",
                    "uvicorn>=0.20.0",
                    "gradio>=3.40.0"
                )
            }
        }
        "deepseek" = @{
            Name = "DeepSeek项目"
            Description = "DeepSeek模型开发和部署环境"
            Files = @("requirements.txt", "environment.yml")
            Packages = @{
                conda = @(
                    "python=3.10",
                    "numpy>=1.24.0",
                    "pandas>=2.0.0"
                )
                pip = @(
                    "torch>=2.0.0",
                    "transformers>=4.30.0",
                    "tokenizers>=0.13.0",
                    "accelerate>=0.20.0",
                    "flash-attn>=2.3.0",
                    "deepseek-ai>=0.1.0",
                    "sentencepiece>=0.1.99",
                    "protobuf>=3.20.0",
                    "vllm>=0.2.0",
                    "fastapi>=0.100.0",
                    "uvicorn>=0.20.0",
                    "gradio>=3.40.0",
                    "streamlit>=1.25.0"
                )
            }
        }
    }
}

function Show-ProjectTemplates {
    param([hashtable]$Templates)
    
    Write-Log "=== 可用项目模板 ===" "INFO"
    
    foreach ($template in $Templates.GetEnumerator()) {
        Write-Host "`n🔹 $($template.Key)" -ForegroundColor Yellow
        Write-Host "   名称: $($template.Value.Name)" -ForegroundColor White
        Write-Host "   描述: $($template.Value.Description)" -ForegroundColor Gray
        Write-Host "   文件: $($template.Value.Files -join ', ')" -ForegroundColor Gray
    }
}

function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$DefaultValue = "",
        [string[]]$ValidOptions = @()
    )
    
    do {
        if ($DefaultValue) {
            $input = Read-Host "$Prompt [$DefaultValue]"
            if (-not $input) {
                $input = $DefaultValue
            }
        } else {
            $input = Read-Host $Prompt
        }
        
        if ($ValidOptions.Count -eq 0 -or $ValidOptions -contains $input) {
            return $input
        } else {
            Write-Host "无效选项，请从以下选项中选择: $($ValidOptions -join ', ')" -ForegroundColor Red
        }
    } while ($true)
}

function Generate-RequirementsTxt {
    param(
        [string]$OutputPath,
        [array]$Packages
    )
    
    $content = @"
# 项目依赖包
# Generated by Project Template Generator
# $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

"@
    
    foreach ($package in $Packages) {
        $content += "`n$package"
    }
    
    $content += "`n`n# 开发依赖`n"
    $content += "pytest>=7.0.0`n"
    $content += "black>=22.0.0`n"
    $content += "flake8>=6.0.0`n"
    $content += "mypy>=1.0.0`n"
    
    Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    Write-Log "生成文件: $OutputPath" "SUCCESS"
}

function Generate-EnvironmentYml {
    param(
        [string]$OutputPath,
        [string]$ProjectName,
        [array]$CondaPackages,
        [array]$PipPackages
    )
    
    $content = @"
name: $ProjectName
channels:
  - conda-forge
  - defaults
dependencies:
"@
    
    foreach ($package in $CondaPackages) {
        $content += "`n  - $package"
    }
    
    $content += "`n  - pip"
    $content += "`n  - pip:"
    
    foreach ($package in $PipPackages) {
        $content += "`n    - $package"
    }
    
    Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    Write-Log "生成文件: $OutputPath" "SUCCESS"
}

function Generate-PyProjectToml {
    param(
        [string]$OutputPath,
        [string]$ProjectName,
        [array]$PipPackages
    )
    
    $content = @"
[build-system]
requires = ["setuptools>=61.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "$ProjectName"
version = "0.1.0"
description = "Generated by Project Template Generator"
authors = [{name = "Your Name", email = "your.email@example.com"}]
license = {text = "MIT"}
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
"@
    
    foreach ($package in $PipPackages) {
        $content += "`n    `"$package`","
    }
    
    $content += @"
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "black>=22.0.0",
    "flake8>=6.0.0",
    "mypy>=1.0.0",
]

[tool.setuptools.packages.find]
where = ["src"]

[tool.black]
line-length = 88
target-version = ['py310']

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_classes = ["Test*"]
python_functions = ["test_*"]
"@
    
    Set-Content -Path $OutputPath -Value $content -Encoding UTF8
    Write-Log "生成文件: $OutputPath" "SUCCESS"
}

function Start-TemplateGenerator {
    Write-Log "=== 项目模板生成器 ===" "INFO"
    
    $templates = Get-ProjectTemplates
    
    if ($Interactive) {
        # 交互式模式
        Show-ProjectTemplates -Templates $templates
        
        $templateKeys = $templates.Keys | Sort-Object
        $ProjectType = Get-UserInput -Prompt "请选择项目类型" -ValidOptions $templateKeys
        
        if (-not $ProjectName) {
            $ProjectName = Get-UserInput -Prompt "请输入项目名称" -DefaultValue "my-project"
        }
        
        if (-not $OutputPath) {
            $OutputPath = Get-UserInput -Prompt "请输入输出路径" -DefaultValue (Join-Path (Get-Location) $ProjectName)
        }
    } else {
        # 命令行模式
        if (-not $ProjectType) {
            Write-Log "请指定项目类型，使用 -Interactive 参数进入交互模式" "ERROR"
            return $false
        }
        
        if (-not $ProjectName) {
            $ProjectName = "my-project"
        }
        
        if (-not $OutputPath) {
            $OutputPath = Join-Path (Get-Location) $ProjectName
        }
    }
    
    # 验证项目类型
    if (-not $templates.ContainsKey($ProjectType)) {
        Write-Log "不支持的项目类型: $ProjectType" "ERROR"
        Write-Log "支持的类型: $($templates.Keys -join ', ')" "INFO"
        return $false
    }
    
    $template = $templates[$ProjectType]
    
    Write-Log "`n=== 生成项目配置 ===" "INFO"
    Write-Log "项目名称: $ProjectName" "INFO"
    Write-Log "项目类型: $ProjectType" "INFO"
    Write-Log "输出路径: $OutputPath" "INFO"
    Write-Log "模板: $($template.Name)" "INFO"
    
    # 创建输出目录
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-Log "创建项目目录: $OutputPath" "SUCCESS"
    }
    
    # 生成配置文件
    foreach ($file in $template.Files) {
        $filePath = Join-Path $OutputPath $file
        
        switch ($file) {
            "requirements.txt" {
                Generate-RequirementsTxt -OutputPath $filePath -Packages $template.Packages.pip
            }
            "environment.yml" {
                Generate-EnvironmentYml -OutputPath $filePath -ProjectName $ProjectName -CondaPackages $template.Packages.conda -PipPackages $template.Packages.pip
            }
            "pyproject.toml" {
                Generate-PyProjectToml -OutputPath $filePath -ProjectName $ProjectName -PipPackages $template.Packages.pip
            }
        }
    }
    
    # 生成README.md
    $readmePath = Join-Path $OutputPath "README.md"
    $readmeContent = @"
# $ProjectName

$($template.Description)

## 环境配置

### 使用Conda环境
```bash
conda env create -f environment.yml
conda activate $ProjectName
```

### 使用Pip
```bash
pip install -r requirements.txt
```

## 项目结构
```
$ProjectName/
├── README.md
├── requirements.txt
├── environment.yml
└── src/
    └── main.py
```

## 开发指南

1. 克隆项目
2. 创建虚拟环境
3. 安装依赖
4. 开始开发

## 许可证
MIT
"@
    
    Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    Write-Log "生成文件: $readmePath" "SUCCESS"
    
    Write-Log "`n=== 项目配置生成完成 ===" "SUCCESS"
    Write-Host "📁 项目目录: $OutputPath" -ForegroundColor Cyan
    Write-Host "📄 生成的文件:" -ForegroundColor Cyan
    foreach ($file in $template.Files) {
        Write-Host "  - $file" -ForegroundColor White
    }
    Write-Host "  - README.md" -ForegroundColor White
    
    Write-Log "`n下一步操作:" "INFO"
    Write-Host "1. 进入项目目录: cd `"$OutputPath`"" -ForegroundColor White
    Write-Host "2. 分析项目依赖: .\scripts\project-analyzer.ps1 -ProjectPath `"$OutputPath`"" -ForegroundColor White
    Write-Host "3. 下载依赖包: .\scripts\smart-download-v2.ps1 -ProjectPath `"$OutputPath`" -AnalyzeProject" -ForegroundColor White
    
    return $true
}

# 主执行逻辑
if ($MyInvocation.InvocationName -ne '.') {
    Start-TemplateGenerator
}
