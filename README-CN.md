# 自动化脚本集合

一个精心挑选的有用自动化脚本集合，用于简化您的日常工作流程。这些脚本涵盖从文件管理到系统自动化的各种任务，由30年经验的开发运维工程师精心设计。

## 功能特性

- **系统监控**：全面的系统信息收集、性能监控和网络监控
- **文件管理**：批量重命名、文件同步、备份恢复和磁盘清理
- **安全管理**：安全扫描、SSL证书监控和系统优化
- **服务管理**：Docker管理、包管理器、Cron任务管理
- **数据库管理**：数据库备份和恢复
- **通知系统**：邮件通知和日志分析
- **跨平台**：兼容 Linux、macOS 和 Windows 的脚本

## 可用脚本

### 系统监控类
- `system_info.sh`：收集系统基本信息用于故障排查
- `performance_monitor.sh`：监控系统性能指标（CPU、内存、磁盘）
- `network_monitor.sh`：监控网络连接状态和延迟
- `webserver_monitor.sh`：监控Web服务器状态和响应时间

### 文件管理类
- `backup_restore.sh`：创建和恢复文件备份，支持压缩和加密
- `file_sync.sh`：同步文件和目录，支持本地和远程同步
- `disk_cleanup.sh`：清理临时文件、缓存和日志文件
- `batch_file_rename.sh`：强大的批量文件重命名工具，支持多种模式和过滤

### 安全管理类
- `security_scan.sh`：扫描系统安全漏洞和配置问题
- `ssl_cert_monitor.sh`：监控SSL证书过期时间
- `system_optimizer.sh`：优化系统性能和安全设置

### 服务管理类
- `docker_manager.sh`：管理Docker容器和镜像
- `package_manager.sh`：统一管理不同Linux发行版的包
- `cron_manager.sh`：管理Cron定时任务
- `process_manager.sh`：监控和管理系统进程

### 数据库管理类
- `database_backup.sh`：自动备份MySQL/PostgreSQL数据库

### 通知分析类
- `email_notifier.sh`：发送邮件通知，支持HTML和附件
- `log_analyzer.sh`：分析系统日志文件，统计错误和警告

### 其他工具
- `git_commit.sh`：自动化 Git 添加、提交和推送

## 安装

1. 克隆仓库：
   ```bash
   git clone https://github.com/yourusername/automation-scripts.git
   cd automation-scripts
   ```

2. 使脚本可执行：
   ```bash
   chmod +x scripts/*.sh
   ```

## 使用方法

### 基本用法
导航到 `scripts/` 目录并运行所需的脚本：

```bash
# 查看系统信息
./scripts/system_info.sh

# 监控系统性能
./scripts/performance_monitor.sh --interval 10 --duration 600

# 清理磁盘空间
./scripts/disk_cleanup.sh --all --size

# 备份数据库
./scripts/database_backup.sh --type mysql --user root --database mydb
```

### 常用命令示例

#### 系统监控
```bash
# 收集系统信息并保存到文件
./scripts/system_info.sh system_report.txt

# 监控网络连接
./scripts/network_monitor.sh --target google.com --interval 5 --count 10

# 监控Web服务器
./scripts/webserver_monitor.sh --url https://example.com --ssl --alert admin@example.com
```

#### 文件管理
```bash
# 创建备份
./scripts/backup_restore.sh backup --source /home/user --dest /backup --compress

# 同步文件
./scripts/file_sync.sh --source /local/path --dest /remote/path --archive

# 清理磁盘
./scripts/disk_cleanup.sh --temp --logs --cache

# 批量重命名文件
./scripts/batch_file_rename.sh --prefix "IMG_" --extensions "jpg,png" --dry-run
./scripts/batch_file_rename.sh --replace "old" "new" --backup
./scripts/batch_file_rename.sh --case upper --exclude "*backup*"
```

#### 安全管理
```bash
# 安全扫描
./scripts/security_scan.sh --type full --output security_report.txt

# 检查SSL证书
./scripts/ssl_cert_monitor.sh --domain example.com --warning 30

# 系统优化
./scripts/system_optimizer.sh --type all --backup
```

#### 服务管理
```bash
# Docker管理
./scripts/docker_manager.sh ps --all
./scripts/docker_manager.sh run nginx --name web --ports 80:80

# 包管理
./scripts/package_manager.sh install nginx mysql --yes

# Cron任务管理
./scripts/cron_manager.sh add --cron "0 2 * * *" --script "/path/to/backup.sh"
```

### 查看帮助
每个脚本都包含详细的帮助信息：

```bash
./scripts/system_info.sh --help
./scripts/performance_monitor.sh --help
```

### 配置说明
- 所有脚本都支持详细输出模式（`--verbose`）
- 大部分脚本支持输出到文件（`--output`）
- 监控类脚本支持告警邮件通知（`--alert`）
- 备份类脚本支持压缩和加密选项

## 脚本特性

### 通用特性
- **详细注释**：每个脚本都包含完整的中英文注释
- **错误处理**：完善的错误检查和异常处理机制
- **日志记录**：支持详细日志输出和文件记录
- **参数验证**：严格的输入参数验证
- **跨平台兼容**：支持Linux、macOS和Windows

### 安全特性
- **权限检查**：需要root权限的操作会进行权限验证
- **备份机制**：重要操作前自动创建备份
- **加密支持**：敏感数据支持加密存储
- **安全扫描**：内置安全检查和漏洞检测

### 监控特性
- **实时监控**：支持实时系统状态监控
- **告警通知**：支持邮件告警和日志记录
- **性能统计**：详细的性能指标统计
- **报告生成**：自动生成监控和优化报告

## 系统要求

### 基本要求
- Bash 4.0+
- 基本的Unix工具（curl, wget, tar, gzip等）
- 适当的系统权限

### 可选依赖
- **数据库备份**：MySQL/PostgreSQL客户端
- **Docker管理**：Docker Engine
- **邮件通知**：mail/sendmail/mutt
- **SSL检查**：openssl
- **系统优化**：root权限

## 最佳实践

### 使用建议
1. **定期备份**：使用备份脚本定期备份重要数据
2. **监控系统**：设置系统监控和告警
3. **安全扫描**：定期进行安全扫描和漏洞检查
4. **日志分析**：定期分析系统日志
5. **性能优化**：根据监控结果进行系统优化

### 安全建议
1. **权限管理**：合理设置脚本执行权限
2. **敏感信息**：妥善保管密码和密钥文件
3. **网络安全**：注意网络连接的安全性
4. **定期更新**：保持系统和脚本的更新

## 故障排除

### 常见问题
1. **权限不足**：确保有足够的系统权限
2. **依赖缺失**：安装必要的系统工具
3. **网络问题**：检查网络连接和防火墙设置
4. **磁盘空间**：确保有足够的磁盘空间

### 获取帮助
- 查看脚本帮助：`./script_name.sh --help`
- 启用详细模式：`./script_name.sh --verbose`
- 检查日志文件：查看脚本生成的日志

## 贡献

欢迎贡献！请在提交拉取请求之前阅读 [贡献指南](CONTRIBUTING.md)。

1. Fork 此仓库
2. 创建功能分支：`git checkout -b feature/new-script`
3. 提交更改：`git commit -m '添加新的自动化脚本'`
4. 推送到分支：`git push origin feature/new-script`
5. 打开拉取请求

## 许可证

此项目根据 MIT 许可证授权 - 查看 [LICENSE](LICENSE) 文件以获取详情。

## 支持

如果您觉得此项目有帮助，请在 GitHub 上给它一个 ⭐！

## 更新日志

### v1.0.0 (2024-01-01)
- 初始版本发布
- 包含20个常用自动化脚本
- 支持系统监控、文件管理、安全管理等功能
- 完整的中英文文档
