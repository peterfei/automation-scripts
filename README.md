# Automation Scripts Collection

A curated collection of useful automation scripts to streamline your workflow. These scripts cover a variety of tasks from file management to system automation, designed by experienced DevOps engineers with 30 years of experience.

## Features

- **System Monitoring**: Comprehensive system information collection, performance monitoring, and network monitoring
- **File Management**: Batch renaming, file synchronization, backup/restore, and disk cleanup
- **Security Management**: Security scanning, SSL certificate monitoring, and system optimization
- **Service Management**: Docker management, package manager, and Cron job management
- **Database Management**: Database backup and restore
- **Notification System**: Email notifications and log analysis
- **Cross-Platform**: Scripts compatible with Linux, macOS, and Windows

## Available Scripts

### System Monitoring
- `system_info.sh`: Collect system information for troubleshooting
- `performance_monitor.sh`: Monitor system performance metrics (CPU, memory, disk)
- `network_monitor.sh`: Monitor network connection status and latency
- `webserver_monitor.sh`: Monitor web server status and response time

### File Management
- `backup_restore.sh`: Create and restore file backups with compression and encryption support
- `file_sync.sh`: Synchronize files and directories with local and remote support
- `disk_cleanup.sh`: Clean temporary files, cache, and log files
- `batch_file_rename.sh`: Powerful batch file renaming tool with multiple patterns and filtering

### Security Management
- `security_scan.sh`: Scan system security vulnerabilities and configuration issues
- `ssl_cert_monitor.sh`: Monitor SSL certificate expiration
- `system_optimizer.sh`: Optimize system performance and security settings

### Service Management
- `docker_manager.sh`: Manage Docker containers and images
- `package_manager.sh`: Unified package management for different Linux distributions
- `cron_manager.sh`: Manage Cron scheduled tasks
- `process_manager.sh`: Monitor and manage system processes

### Database Management
- `database_backup.sh`: Automatically backup MySQL/PostgreSQL databases

### Notification & Analysis
- `email_notifier.sh`: Send email notifications with HTML and attachment support
- `log_analyzer.sh`: Analyze system log files and statistics for errors and warnings

### Other Tools
- `git_commit.sh`: Automated Git add, commit, and push

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/automation-scripts.git
   cd automation-scripts
   ```

2. Make scripts executable:
   ```bash
   chmod +x scripts/*.sh
   ```

## Usage

### Basic Usage
Navigate to the `scripts/` directory and run the desired script:

```bash
# View system information
./scripts/system_info.sh

# Monitor system performance
./scripts/performance_monitor.sh --interval 10 --duration 600

# Clean up disk space
./scripts/disk_cleanup.sh --all --size

# Backup database
./scripts/database_backup.sh --type mysql --user root --database mydb
```

### Common Command Examples

#### System Monitoring
```bash
# Collect system information and save to file
./scripts/system_info.sh system_report.txt

# Monitor network connections
./scripts/network_monitor.sh --target google.com --interval 5 --count 10

# Monitor web server
./scripts/webserver_monitor.sh --url https://example.com --ssl --alert admin@example.com
```

#### File Management
```bash
# Create backup
./scripts/backup_restore.sh backup --source /home/user --dest /backup --compress

# Sync files
./scripts/file_sync.sh --source /local/path --dest /remote/path --archive

# Clean disk
./scripts/disk_cleanup.sh --temp --logs --cache

# Batch rename files
./scripts/batch_file_rename.sh --prefix "IMG_" --extensions "jpg,png" --dry-run
./scripts/batch_file_rename.sh --replace "old" "new" --backup
./scripts/batch_file_rename.sh --case upper --exclude "*backup*"
```

#### Security Management
```bash
# Security scan
./scripts/security_scan.sh --type full --output security_report.txt

# Check SSL certificate
./scripts/ssl_cert_monitor.sh --domain example.com --warning 30

# System optimization
./scripts/system_optimizer.sh --type all --backup
```

#### Service Management
```bash
# Docker management
./scripts/docker_manager.sh ps --all
./scripts/docker_manager.sh run nginx --name web --ports 80:80

# Package management
./scripts/package_manager.sh install nginx mysql --yes

# Cron job management
./scripts/cron_manager.sh add --cron "0 2 * * *" --script "/path/to/backup.sh"
```

### View Help
Each script contains detailed help information:

```bash
./scripts/system_info.sh --help
./scripts/performance_monitor.sh --help
```

### Configuration Notes
- All scripts support verbose output mode (`--verbose`)
- Most scripts support output to file (`--output`)
- Monitoring scripts support email alerts (`--alert`)
- Backup scripts support compression and encryption options

## Script Features

### General Features
- **Detailed Comments**: Each script contains complete Chinese and English comments
- **Error Handling**: Comprehensive error checking and exception handling mechanisms
- **Logging**: Support for detailed log output and file recording
- **Parameter Validation**: Strict input parameter validation
- **Cross-Platform Compatibility**: Support for Linux, macOS, and Windows

### Security Features
- **Permission Checks**: Permission verification for operations requiring root access
- **Backup Mechanisms**: Automatic backup creation before important operations
- **Encryption Support**: Encrypted storage for sensitive data
- **Security Scanning**: Built-in security checks and vulnerability detection

### Monitoring Features
- **Real-time Monitoring**: Support for real-time system status monitoring
- **Alert Notifications**: Support for email alerts and log recording
- **Performance Statistics**: Detailed performance metrics statistics
- **Report Generation**: Automatic generation of monitoring and optimization reports

## System Requirements

### Basic Requirements
- Bash 4.0+
- Basic Unix tools (curl, wget, tar, gzip, etc.)
- Appropriate system permissions

### Optional Dependencies
- **Database Backup**: MySQL/PostgreSQL clients
- **Docker Management**: Docker Engine
- **Email Notifications**: mail/sendmail/mutt
- **SSL Checking**: openssl
- **System Optimization**: root privileges

## Best Practices

### Usage Recommendations
1. **Regular Backups**: Use backup scripts to regularly backup important data
2. **System Monitoring**: Set up system monitoring and alerts
3. **Security Scanning**: Regularly perform security scans and vulnerability checks
4. **Log Analysis**: Regularly analyze system logs
5. **Performance Optimization**: Optimize system based on monitoring results

### Security Recommendations
1. **Permission Management**: Set appropriate script execution permissions
2. **Sensitive Information**: Properly secure passwords and key files
3. **Network Security**: Pay attention to network connection security
4. **Regular Updates**: Keep systems and scripts updated

## Troubleshooting

### Common Issues
1. **Insufficient Permissions**: Ensure adequate system permissions
2. **Missing Dependencies**: Install necessary system tools
3. **Network Issues**: Check network connections and firewall settings
4. **Disk Space**: Ensure sufficient disk space

### Getting Help
- View script help: `./script_name.sh --help`
- Enable verbose mode: `./script_name.sh --verbose`
- Check log files: Review logs generated by scripts

## Contributing

Contributions are welcome! Please read the [contributing guidelines](CONTRIBUTING.md) before submitting a pull request.

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/new-script`
3. Commit your changes: `git commit -m 'Add new automation script'`
4. Push to the branch: `git push origin feature/new-script`
5. Open a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this project helpful, please give it a ⭐ on GitHub!

## Changelog

### v1.0.0 (2024-01-01)
- Initial release
- Includes 20 common automation scripts
- Supports system monitoring, file management, security management, and more
- Complete Chinese and English documentation
