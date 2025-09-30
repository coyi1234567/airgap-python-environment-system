# 内网机器离线Python环境全自动化管理系统
# AirGap Python Environment Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Python](https://img.shields.io/badge/Python-3.10-blue.svg)](https://www.python.org/)
[![Conda](https://img.shields.io/badge/Conda-Latest-green.svg)](https://conda.io/)
[![Windows](https://img.shields.io/badge/Platform-Windows-lightgrey.svg)](https://www.microsoft.com/windows/)

> 专为内网Windows 10机器设计的离线Python环境管理系统，支持一键部署、智能管理、无缝迁移

## 🎯 核心特性

- ✅ **一键部署**: 自动下载并安装Miniconda，配置本地镜像源
- ✅ **完全离线**: 无需网络连接，所有操作都在本地完成
- ✅ **多环境支持**: 科学计算、机器学习、深度学习环境
- ✅ **智能包管理**: 支持conda和pip两种包管理方式
- ✅ **环境迁移**: 导出/导入环境配置，支持U盘传输
- ✅ **版本管理**: 多版本包共存，按需选择
- ✅ **自动下载**: 根据配置自动下载所需包文件

## 🚀 快速开始

### 1. 下载项目
```bash
git clone https://github.com/coyi1234567/airgap-python-environment-system.git
cd airgap-python-environment-system/python-airgap-repo
```

### 2. 一键部署
```powershell
# 以管理员身份运行PowerShell
.\scripts\setup.ps1
```

### 3. 验证安装
```powershell
.\scripts\verify-deployment.ps1
```

## 📁 项目结构

```
airgap-python-environment-system/
├── python-airgap-repo/        # 主要项目目录
│   ├── scripts/               # 自动化脚本
│   │   ├── setup.ps1         # 一键部署脚本
│   │   ├── env-manager.ps1   # 环境管理脚本
│   │   ├── verify-deployment.ps1 # 验证部署脚本
│   │   └── progress-tracker.ps1 # 进度跟踪脚本
│   ├── environments/          # 环境配置文件
│   │   ├── base-scientific.yml # 科学计算环境
│   │   ├── base-ml.yml       # 机器学习环境
│   │   ├── base-dl.yml       # 深度学习环境
│   │   ├── ai-models.yml     # AI模型环境
│   │   ├── chatglm.yml       # ChatGLM环境
│   │   ├── deepseek.yml      # DeepSeek环境
│   │   ├── bert.yml          # BERT环境
│   │   ├── qwen.yml          # Qwen环境
│   │   └── openai-compatible.yml # OpenAI兼容环境
│   ├── config/               # 配置文件
│   │   ├── download-config.json # 下载配置
│   │   ├── environment-config.json # 环境配置
│   │   └── model-config.json # 模型配置
│   ├── templates/            # 模板文件
│   │   ├── conda-channel-template.txt # Conda源模板
│   │   └── pip-index-template.txt     # Pip源模板
│   ├── installers/           # 安装包目录
│   ├── conda-packages/       # Conda包目录
│   ├── pip-packages/         # Pip包目录
│   ├── docs/                 # 文档目录
│   ├── manifest.json         # 项目清单
│   └── README.md            # 详细项目说明
├── GIT_SETUP_GUIDE.md        # Git安装配置指南
├── GITHUB_SETUP_GUIDE.md     # GitHub设置指南
├── PROJECT_COMPLETION_REPORT.md # 项目完成报告
├── 完整实施方案.md            # 完整实施方案
├── 项目重命名和GitHub同步方案.md # 项目重命名方案
└── README.md                # 项目总览（本文件）
```

## 🔧 环境管理

### 创建环境
```powershell
# 进入项目目录
cd python-airgap-repo

# 创建科学计算环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "scientific" -ConfigFile "environments\base-scientific.yml"

# 创建机器学习环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "ml" -ConfigFile "environments\base-ml.yml"

# 创建深度学习环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "dl" -ConfigFile "environments\base-dl.yml"
```

### 管理环境
```powershell
# 列出所有环境
.\scripts\env-manager.ps1 -Action List

# 激活环境
.\scripts\env-manager.ps1 -Action Activate -EnvironmentName "scientific"

# 删除环境
.\scripts\env-manager.ps1 -Action Remove -EnvironmentName "scientific"
```

## 🤖 AI模型环境支持

### ChatGLM环境
```powershell
# 创建ChatGLM环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "chatglm" -ConfigFile "environments\chatglm.yml"
```

### DeepSeek环境
```powershell
# 创建DeepSeek环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "deepseek" -ConfigFile "environments\deepseek.yml"
```

### BERT环境
```powershell
# 创建BERT环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "bert" -ConfigFile "environments\bert.yml"
```

### Qwen环境
```powershell
# 创建Qwen环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "qwen" -ConfigFile "environments\qwen.yml"
```

### OpenAI兼容环境
```powershell
# 创建OpenAI兼容环境
.\scripts\env-manager.ps1 -Action Create -EnvironmentName "openai" -ConfigFile "environments\openai-compatible.yml"
```

## 📦 智能下载管理

### 项目配置文件分析
系统支持分析多种项目配置文件：
- `requirements.txt` - Python包依赖
- `environment.yml` - Conda环境配置
- `pyproject.toml` - 现代Python项目配置
- `Pipfile` - Pipenv项目配置
- `poetry.lock` - Poetry项目配置

### 智能去重下载
```powershell
# 分析项目依赖并去重下载
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\your-project" -DownloadPath ".\packages"
```

### 项目模板生成
```powershell
# 生成AI/ML项目模板
.\scripts\project-template-generator.ps1 -ProjectType "ai-ml" -ProjectName "my-ai-project"

# 生成ChatGLM项目模板
.\scripts\project-template-generator.ps1 -ProjectType "chatglm" -ProjectName "my-chatglm-project"
```

## 🔄 环境迁移

### 导出环境
```powershell
# 导出环境配置
.\scripts\env-manager.ps1 -Action Export -EnvironmentName "scientific" -OutputPath ".\exports\scientific.yml"
```

### 导入环境
```powershell
# 导入环境配置
.\scripts\env-manager.ps1 -Action Import -ConfigFile ".\exports\scientific.yml" -EnvironmentName "scientific-new"
```

## 📊 进度跟踪

### 实时进度监控
```powershell
# 启动进度跟踪
.\scripts\progress-tracker.ps1 -ProjectPath ".\" -UpdateInterval 5
```

### 最终验证
```powershell
# 执行最终验证
.\scripts\final-validation.ps1 -ProjectPath ".\"
```

## 🛠️ 配置说明

### 下载配置 (config/download-config.json)
```json
{
  "download_sources": {
    "conda_channels": ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/"],
    "pip_indexes": ["https://pypi.tuna.tsinghua.edu.cn/simple/"]
  },
  "download_ai_models": true,
  "download_chatglm": true,
  "download_deepseek": true,
  "download_bert": true,
  "download_qwen": true,
  "download_openai_compatible": true
}
```

### 环境配置 (config/environment-config.json)
```json
{
  "default_python_version": "3.10",
  "default_conda_channel": "conda-forge",
  "default_pip_index": "https://pypi.org/simple/",
  "environment_prefix": "airgap_"
}
```

### 模型配置 (config/model-config.json)
```json
{
  "models": {
    "chatglm": {
      "name": "ChatGLM",
      "description": "ChatGLM系列大语言模型",
      "quantization": ["int4", "int8", "fp16"],
      "inference_engines": ["transformers", "vllm", "tgi"]
    }
  }
}
```

## 🔍 故障排除

### 常见问题

1. **PowerShell执行策略问题**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

2. **网络连接问题**
   - 确保所有下载源配置正确
   - 检查防火墙设置

3. **环境创建失败**
   - 检查磁盘空间
   - 验证环境配置文件格式

4. **包下载失败**
   - 检查下载源可用性
   - 验证网络连接

### 日志查看
```powershell
# 查看部署日志
Get-Content ".\logs\deployment.log" -Tail 50

# 查看错误日志
Get-Content ".\logs\error.log" -Tail 50
```

## 📚 文档

- [部署指南](python-airgap-repo/docs/deployment-guide.md)
- [环境管理](python-airgap-repo/docs/environment-management.md)
- [故障排除](python-airgap-repo/docs/troubleshooting.md)
- [API参考](python-airgap-repo/docs/api-reference.md)
- [Git安装指南](GIT_SETUP_GUIDE.md)
- [GitHub设置指南](GITHUB_SETUP_GUIDE.md)
- [完整实施方案](完整实施方案.md)

## 🤝 贡献

欢迎提交Issue和Pull Request！

## 📄 许可证

本项目采用MIT许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

感谢所有开源项目的贡献者！

---

**注意**: 本项目专为内网环境设计，确保在离线状态下也能正常工作。

## 📞 联系方式

- GitHub: [coyi1234567/airgap-python-environment-system](https://github.com/coyi1234567/airgap-python-environment-system)
- 项目主页: [https://github.com/coyi1234567/airgap-python-environment-system](https://github.com/coyi1234567/airgap-python-environment-system)
