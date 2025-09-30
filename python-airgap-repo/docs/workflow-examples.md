# 工作流程示例
# Workflow Examples

本文档提供了使用内网机器离线Python环境全自动化管理系统的完整工作流程示例。

## 🚀 快速开始

### 1. 创建新项目

```powershell
# 交互式创建ChatGLM项目
.\scripts\project-template-generator.ps1 -Interactive

# 或者直接创建
.\scripts\project-template-generator.ps1 -ProjectType "chatglm" -ProjectName "my-chatglm-app"
```

### 2. 分析项目依赖

```powershell
# 分析项目配置文件
.\scripts\project-analyzer.ps1 -ProjectPath "C:\my-chatglm-app"
```

### 3. 下载依赖包

```powershell
# 智能下载（自动分析+去重下载）
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\my-chatglm-app" -AnalyzeProject
```

### 4. 部署到内网机器

```powershell
# 一键部署
.\scripts\setup.ps1 -RepoPath "C:\python-airgap-repo"
```

## 📋 详细工作流程

### 场景1：开发ChatGLM应用

#### 步骤1：创建项目
```powershell
# 创建ChatGLM项目
.\scripts\project-template-generator.ps1 -ProjectType "chatglm" -ProjectName "chatglm-demo"
```

生成的文件：
- `requirements.txt` - Pip依赖
- `environment.yml` - Conda环境配置
- `README.md` - 项目说明

#### 步骤2：分析依赖
```powershell
# 分析项目依赖
.\scripts\project-analyzer.ps1 -ProjectPath "C:\chatglm-demo"
```

输出：
- `download-list.json` - 去重后的下载清单
- 分析报告显示包的数量和重复情况

#### 步骤3：下载包
```powershell
# 下载依赖包
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\chatglm-demo" -AnalyzeProject
```

#### 步骤4：部署到内网
```powershell
# 复制到U盘
Copy-Item -Path "C:\python-airgap-repo" -Destination "E:\" -Recurse

# 在内网机器上部署
.\scripts\setup.ps1 -RepoPath "E:\python-airgap-repo"
```

### 场景2：现有项目迁移

#### 步骤1：分析现有项目
```powershell
# 分析现有项目
.\scripts\project-analyzer.ps1 -ProjectPath "C:\existing-project"
```

#### 步骤2：生成下载清单
```powershell
# 生成下载清单
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\existing-project" -AnalyzeProject
```

#### 步骤3：增量下载
```powershell
# 只下载新包（跳过已存在的）
.\scripts\smart-download-v2.ps1 -DownloadListFile "download-list.json"
```

### 场景3：多项目环境管理

#### 步骤1：创建多个项目
```powershell
# 创建AI项目
.\scripts\project-template-generator.ps1 -ProjectType "ai-ml" -ProjectName "ai-project"

# 创建Web API项目
.\scripts\project-template-generator.ps1 -ProjectType "web-api" -ProjectName "api-project"

# 创建数据科学项目
.\scripts\project-template-generator.ps1 -ProjectType "data-science" -ProjectName "data-project"
```

#### 步骤2：批量分析
```powershell
# 分析所有项目
$projects = @("ai-project", "api-project", "data-project")
foreach ($project in $projects) {
    .\scripts\project-analyzer.ps1 -ProjectPath "C:\$project"
}
```

#### 步骤3：合并下载清单
```powershell
# 合并所有下载清单
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\" -AnalyzeAll
```

## 🔄 环境同步流程

### 内网到外网调试

#### 步骤1：导出内网环境
```powershell
# 导出环境配置
.\scripts\env-manager.ps1 -Action export -EnvName "my-env" -OutputPath "E:\env-backup"
```

#### 步骤2：外网调试
```powershell
# 在外网机器上导入环境
.\scripts\env-manager.ps1 -Action import -EnvPath "E:\env-backup"
```

#### 步骤3：分析差异
```powershell
# 分析环境差异
.\scripts\update-manager.ps1 -Action diff -OldEnv "E:\env-backup" -NewEnv "C:\current-env"
```

#### 步骤4：下载差异包
```powershell
# 下载差异包
.\scripts\update-manager.ps1 -Action download -DiffFile "env-diff.json"
```

#### 步骤5：同步到内网
```powershell
# 同步到内网仓库
.\scripts\update-manager.ps1 -Action sync -DiffPath "E:\diff-packages"
```

## 📊 监控和维护

### 仓库状态监控
```powershell
# 检查仓库状态
.\scripts\verify-deployment.ps1 -RepoPath "C:\python-airgap-repo"

# 生成状态报告
.\scripts\generate-report.ps1 -OutputPath "repo-status.html"
```

### 包版本管理
```powershell
# 检查包版本
.\scripts\package-manager.ps1 -Action list -RepoPath "C:\python-airgap-repo"

# 更新包版本
.\scripts\package-manager.ps1 -Action update -PackageName "torch" -Version "2.1.0"
```

## 🛠️ 故障排除

### 常见问题解决

#### 1. 包下载失败
```powershell
# 检查网络连接
Test-NetConnection -ComputerName "pypi.org" -Port 443

# 重试下载
.\scripts\smart-download-v2.ps1 -ProjectPath "C:\project" -Force
```

#### 2. 环境创建失败
```powershell
# 检查Conda安装
conda --version

# 重新安装Conda
.\scripts\setup.ps1 -RepoPath "C:\python-airgap-repo" -Force
```

#### 3. 包冲突
```powershell
# 检查包依赖
.\scripts\package-manager.ps1 -Action check -PackageName "torch"

# 解决冲突
.\scripts\package-manager.ps1 -Action resolve -ConflictFile "conflicts.json"
```

## 📈 最佳实践

### 1. 项目结构建议
```
my-project/
├── requirements.txt          # Pip依赖
├── environment.yml           # Conda环境
├── pyproject.toml           # 项目配置
├── README.md                # 项目说明
├── src/                     # 源代码
├── tests/                   # 测试代码
└── docs/                    # 文档
```

### 2. 版本管理建议
- 使用固定版本号（如 `torch==2.0.1`）
- 定期更新依赖包
- 使用虚拟环境隔离项目

### 3. 部署建议
- 先在外网测试环境
- 使用U盘传输大文件
- 定期备份环境配置

### 4. 监控建议
- 定期检查仓库状态
- 监控包版本更新
- 记录环境变更日志

## 🔗 相关脚本

| 脚本 | 功能 | 使用场景 |
|------|------|----------|
| `project-template-generator.ps1` | 生成项目模板 | 创建新项目 |
| `project-analyzer.ps1` | 分析项目依赖 | 分析现有项目 |
| `smart-download-v2.ps1` | 智能下载 | 下载依赖包 |
| `setup.ps1` | 环境部署 | 部署到内网 |
| `env-manager.ps1` | 环境管理 | 导出/导入环境 |
| `update-manager.ps1` | 更新管理 | 同步环境差异 |
| `package-manager.ps1` | 包管理 | 管理包版本 |
| `verify-deployment.ps1` | 验证部署 | 检查部署状态 |

## 📞 技术支持

如果遇到问题，请：
1. 查看日志文件
2. 检查配置文件
3. 运行验证脚本
4. 参考故障排除指南
