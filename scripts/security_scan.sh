#!/bin/bash

# =============================================================================
# 安全扫描脚本
# Security Scan Script
# =============================================================================
# 
# 用途/Use Case:
# - 扫描系统安全漏洞
# - 检查文件权限
# - 检测可疑进程
# - 分析网络连接
# - 生成安全报告
# 
# 使用方法/Usage:
# ./security_scan.sh [options]
# 
# 选项/Options:
# -t, --type TYPE         扫描类型 (full|quick|network|files|processes)
# -o, --output FILE       输出文件
# -e, --exclude PATTERN   排除模式
# -c, --config FILE       配置文件
# -r, --report           生成详细报告
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./security_scan.sh --type full --output security_report.txt
# ./security_scan.sh --type quick --verbose
# 
# 作者/Author: Automation Scripts Collection
# 版本/Version: 1.0
# 日期/Date: $(date +%Y-%m-%d)
# =============================================================================

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 默认配置
SCAN_TYPE="full"
OUTPUT_FILE=""
EXCLUDE_PATTERN=""
CONFIG_FILE=""
GENERATE_REPORT=false
VERBOSE=false

# 统计变量
TOTAL_ISSUES=0
HIGH_RISK=0
MEDIUM_RISK=0
LOW_RISK=0
INFO=0

# 显示帮助信息
show_help() {
    echo "安全扫描脚本 / Security Scan Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -t, --type TYPE         扫描类型 (full|quick|network|files|processes)"
    echo "  -o, --output FILE       输出文件"
    echo "  -e, --exclude PATTERN   排除模式"
    echo "  -c, --config FILE       配置文件"
    echo "  -r, --report           生成详细报告"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --type full --output security_report.txt"
    echo "  $0 --type quick --verbose"
}

# 日志函数
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $message"
    
    if [ "$VERBOSE" = true ]; then
        echo "$log_entry"
    fi
}

# 输出函数
output() {
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        echo "$1"
    fi
}

# 记录问题
record_issue() {
    local level="$1"
    local category="$2"
    local description="$3"
    local recommendation="$4"
    
    TOTAL_ISSUES=$((TOTAL_ISSUES + 1))
    
    case $level in
        "HIGH")
            HIGH_RISK=$((HIGH_RISK + 1))
            color="$RED"
            ;;
        "MEDIUM")
            MEDIUM_RISK=$((MEDIUM_RISK + 1))
            color="$YELLOW"
            ;;
        "LOW")
            LOW_RISK=$((LOW_RISK + 1))
            color="$CYAN"
            ;;
        "INFO")
            INFO=$((INFO + 1))
            color="$BLUE"
            ;;
    esac
    
    output "${color}[$level] $category${NC}"
    output "  描述: $description"
    if [ -n "$recommendation" ]; then
        output "  建议: $recommendation"
    fi
    output ""
}

# 检查文件权限
check_file_permissions() {
    log_message "检查文件权限"
    
    # 检查敏感文件权限
    local sensitive_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/sudoers"
        "/etc/ssh/sshd_config"
        "/etc/hosts"
        "/etc/hostname"
    )
    
    for file in "${sensitive_files[@]}"; do
        if [ -f "$file" ]; then
            local perms=$(stat -c "%a" "$file" 2>/dev/null || stat -f "%OLp" "$file" 2>/dev/null)
            local owner=$(stat -c "%U" "$file" 2>/dev/null || stat -f "%Su" "$file" 2>/dev/null)
            local group=$(stat -c "%G" "$file" 2>/dev/null || stat -f "%Sg" "$file" 2>/dev/null)
            
            case $file in
                "/etc/passwd")
                    if [ "$perms" != "644" ]; then
                        record_issue "HIGH" "文件权限" "文件 $file 权限不正确: $perms (应为 644)" "chmod 644 $file"
                    fi
                    ;;
                "/etc/shadow")
                    if [ "$perms" != "640" ] && [ "$perms" != "600" ]; then
                        record_issue "HIGH" "文件权限" "文件 $file 权限不正确: $perms (应为 640 或 600)" "chmod 640 $file"
                    fi
                    ;;
                "/etc/sudoers")
                    if [ "$perms" != "440" ]; then
                        record_issue "HIGH" "文件权限" "文件 $file 权限不正确: $perms (应为 440)" "chmod 440 $file"
                    fi
                    ;;
            esac
        fi
    done
    
    # 检查可写目录
    local writable_dirs=(
        "/tmp"
        "/var/tmp"
        "/dev/shm"
    )
    
    for dir in "${writable_dirs[@]}"; do
        if [ -d "$dir" ]; then
            local perms=$(stat -c "%a" "$dir" 2>/dev/null || stat -f "%OLp" "$dir" 2>/dev/null)
            if [ "$perms" != "1777" ]; then
                record_issue "MEDIUM" "目录权限" "目录 $dir 权限不正确: $perms (应为 1777)" "chmod 1777 $dir"
            fi
        fi
    done
}

# 检查用户账户
check_user_accounts() {
    log_message "检查用户账户"
    
    # 检查空密码用户
    if [ -f /etc/shadow ]; then
        while IFS=: read -r user hash rest; do
            if [ -z "$hash" ] || [ "$hash" = "!" ] || [ "$hash" = "*" ]; then
                record_issue "HIGH" "用户账户" "用户 $user 没有密码" "为用户设置强密码"
            fi
        done < /etc/shadow
    fi
    
    # 检查UID为0的用户
    while IFS=: read -r user x uid rest; do
        if [ "$uid" = "0" ] && [ "$user" != "root" ]; then
            record_issue "HIGH" "用户账户" "用户 $user 具有root权限 (UID=0)" "检查并删除不必要的root权限用户"
        fi
    done < /etc/passwd
    
    # 检查最近登录
    if command -v last &> /dev/null; then
        local recent_logins=$(last -n 10 2>/dev/null | grep -v "wtmp begins" | wc -l)
        if [ "$recent_logins" -gt 0 ]; then
            record_issue "INFO" "用户活动" "发现 $recent_logins 条最近登录记录" "检查登录日志是否正常"
        fi
    fi
}

# 检查网络连接
check_network_connections() {
    log_message "检查网络连接"
    
    if command -v netstat &> /dev/null; then
        # 检查监听端口
        local listening_ports=$(netstat -tlnp 2>/dev/null | grep LISTEN | wc -l)
        if [ "$listening_ports" -gt 0 ]; then
            record_issue "INFO" "网络服务" "发现 $listening_ports 个监听端口" "检查是否有不必要的服务在运行"
        fi
        
        # 检查外部连接
        local external_conns=$(netstat -tnp 2>/dev/null | grep ESTABLISHED | grep -v "127.0.0.1\|::1" | wc -l)
        if [ "$external_conns" -gt 0 ]; then
            record_issue "MEDIUM" "网络连接" "发现 $external_conns 个外部连接" "检查连接是否合法"
        fi
    elif command -v ss &> /dev/null; then
        # 使用ss命令
        local listening_ports=$(ss -tlnp | grep LISTEN | wc -l)
        if [ "$listening_ports" -gt 0 ]; then
            record_issue "INFO" "网络服务" "发现 $listening_ports 个监听端口" "检查是否有不必要的服务在运行"
        fi
    fi
}

# 检查进程
check_processes() {
    log_message "检查进程"
    
    # 检查可疑进程
    local suspicious_processes=(
        "nc"
        "netcat"
        "ncat"
        "socat"
        "tcpdump"
        "wireshark"
        "nmap"
        "masscan"
        "zmap"
    )
    
    for proc in "${suspicious_processes[@]}"; do
        if pgrep "$proc" > /dev/null 2>&1; then
            record_issue "MEDIUM" "可疑进程" "发现可疑进程: $proc" "检查进程是否合法"
        fi
    done
    
    # 检查高权限进程
    local root_processes=$(ps aux | awk '$1=="root" && $8!="[" {print $11}' | sort | uniq | wc -l)
    if [ "$root_processes" -gt 0 ]; then
        record_issue "INFO" "进程权限" "发现 $root_processes 个以root权限运行的进程" "检查是否有进程需要降权"
    fi
}

# 检查系统配置
check_system_config() {
    log_message "检查系统配置"
    
    # 检查SSH配置
    if [ -f /etc/ssh/sshd_config ]; then
        if grep -q "^#PermitRootLogin yes" /etc/ssh/sshd_config || grep -q "^PermitRootLogin yes" /etc/ssh/sshd_config; then
            record_issue "HIGH" "SSH配置" "允许root用户SSH登录" "设置 PermitRootLogin no"
        fi
        
        if grep -q "^#PasswordAuthentication yes" /etc/ssh/sshd_config || grep -q "^PasswordAuthentication yes" /etc/ssh/sshd_config; then
            record_issue "MEDIUM" "SSH配置" "启用密码认证" "考虑使用密钥认证"
        fi
    fi
    
    # 检查防火墙状态
    if command -v ufw &> /dev/null; then
        local ufw_status=$(ufw status | grep "Status: active")
        if [ -z "$ufw_status" ]; then
            record_issue "MEDIUM" "防火墙" "UFW防火墙未启用" "启用防火墙: ufw enable"
        fi
    elif command -v iptables &> /dev/null; then
        local iptables_rules=$(iptables -L | grep -v "Chain\|target" | wc -l)
        if [ "$iptables_rules" -lt 3 ]; then
            record_issue "MEDIUM" "防火墙" "iptables规则较少" "检查防火墙配置"
        fi
    fi
    
    # 检查自动更新
    if command -v apt &> /dev/null; then
        if ! grep -q "APT::Periodic::Update-Package-Lists" /etc/apt/apt.conf.d/20auto-upgrades; then
            record_issue "LOW" "系统更新" "未启用自动更新" "考虑启用自动安全更新"
        fi
    fi
}

# 检查日志文件
check_log_files() {
    log_message "检查日志文件"
    
    # 检查日志文件权限
    local log_files=(
        "/var/log/auth.log"
        "/var/log/secure"
        "/var/log/messages"
        "/var/log/syslog"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            local perms=$(stat -c "%a" "$log_file" 2>/dev/null || stat -f "%OLp" "$log_file" 2>/dev/null)
            if [ "$perms" != "640" ] && [ "$perms" != "644" ]; then
                record_issue "LOW" "日志权限" "日志文件 $log_file 权限不正确: $perms" "chmod 640 $log_file"
            fi
        fi
    done
    
    # 检查日志轮转
    if [ -f /etc/logrotate.conf ]; then
        record_issue "INFO" "日志管理" "已配置日志轮转" "检查日志轮转配置是否合理"
    else
        record_issue "LOW" "日志管理" "未找到日志轮转配置" "配置日志轮转以防止磁盘空间不足"
    fi
}

# 检查文件完整性
check_file_integrity() {
    log_message "检查文件完整性"
    
    # 检查重要文件是否被修改
    local important_files=(
        "/etc/passwd"
        "/etc/shadow"
        "/etc/group"
        "/etc/hosts"
        "/etc/hostname"
    )
    
    for file in "${important_files[@]}"; do
        if [ -f "$file" ]; then
            local mtime=$(stat -c "%Y" "$file" 2>/dev/null || stat -f "%m" "$file" 2>/dev/null)
            local current_time=$(date +%s)
            local age=$((current_time - mtime))
            
            if [ "$age" -lt 3600 ]; then
                record_issue "HIGH" "文件完整性" "文件 $file 最近被修改 (${age}秒前)" "检查文件修改是否合法"
            fi
        fi
    done
}

# 生成安全报告
generate_security_report() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    output ""
    output "=== 安全扫描报告 ==="
    output "扫描时间: $end_time"
    output "扫描类型: $SCAN_TYPE"
    output ""
    output "问题统计:"
    output "  高风险: $HIGH_RISK"
    output "  中风险: $MEDIUM_RISK"
    output "  低风险: $LOW_RISK"
    output "  信息: $INFO"
    output "  总计: $TOTAL_ISSUES"
    output ""
    
    if [ "$TOTAL_ISSUES" -eq 0 ]; then
        output "${GREEN}未发现安全问题${NC}"
    elif [ "$HIGH_RISK" -gt 0 ]; then
        output "${RED}发现高风险安全问题，请立即处理${NC}"
    elif [ "$MEDIUM_RISK" -gt 0 ]; then
        output "${YELLOW}发现中风险安全问题，建议尽快处理${NC}"
    else
        output "${GREEN}发现低风险问题，建议适当处理${NC}"
    fi
}

# 执行快速扫描
quick_scan() {
    log_message "执行快速安全扫描"
    check_file_permissions
    check_user_accounts
    check_network_connections
}

# 执行完整扫描
full_scan() {
    log_message "执行完整安全扫描"
    check_file_permissions
    check_user_accounts
    check_network_connections
    check_processes
    check_system_config
    check_log_files
    check_file_integrity
}

# 执行网络扫描
network_scan() {
    log_message "执行网络安全扫描"
    check_network_connections
}

# 执行文件扫描
files_scan() {
    log_message "执行文件安全扫描"
    check_file_permissions
    check_file_integrity
}

# 执行进程扫描
processes_scan() {
    log_message "执行进程安全扫描"
    check_processes
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            SCAN_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -e|--exclude)
            EXCLUDE_PATTERN="$2"
            shift 2
            ;;
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -r|--report)
            GENERATE_REPORT=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 验证扫描类型
case $SCAN_TYPE in
    full|quick|network|files|processes)
        ;;
    *)
        echo "错误: 不支持的扫描类型: $SCAN_TYPE"
        exit 1
        ;;
esac

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 开始扫描
log_message "开始安全扫描"
output "安全扫描报告 / Security Scan Report"
output "扫描时间: $(date)"
output "扫描类型: $SCAN_TYPE"
output ""

# 执行相应类型的扫描
case $SCAN_TYPE in
    full)
        full_scan
        ;;
    quick)
        quick_scan
        ;;
    network)
        network_scan
        ;;
    files)
        files_scan
        ;;
    processes)
        processes_scan
        ;;
esac

# 生成报告
generate_security_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}安全扫描报告已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}安全扫描完成${NC}"
fi
