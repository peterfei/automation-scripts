#!/bin/bash

# =============================================================================
# 系统优化脚本
# System Optimizer Script
# =============================================================================
# 
# 用途/Use Case:
# - 优化系统性能
# - 调整内核参数
# - 优化内存使用
# - 优化磁盘I/O
# - 优化网络设置
# 
# 使用方法/Usage:
# ./system_optimizer.sh [options]
# 
# 选项/Options:
# -t, --type TYPE         优化类型 (all|memory|disk|network|kernel)
# -o, --output FILE       输出文件
# -b, --backup            备份配置
# -r, --restore FILE      恢复配置
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./system_optimizer.sh --type all --backup
# ./system_optimizer.sh --type memory --verbose
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
OPTIMIZE_TYPE="all"
OUTPUT_FILE=""
BACKUP_CONFIG=false
RESTORE_FILE=""
VERBOSE=false

# 统计变量
OPTIMIZATIONS_APPLIED=0
OPTIMIZATIONS_FAILED=0
BACKUP_CREATED=false

# 显示帮助信息
show_help() {
    echo "系统优化脚本 / System Optimizer Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -t, --type TYPE         优化类型 (all|memory|disk|network|kernel)"
    echo "  -o, --output FILE       输出文件"
    echo "  -b, --backup            备份配置"
    echo "  -r, --restore FILE      恢复配置"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --type all --backup"
    echo "  $0 --type memory --verbose"
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

# 检查权限
check_permissions() {
    if [ "$EUID" -ne 0 ]; then
        echo "${RED}错误: 需要root权限来优化系统${NC}"
        exit 1
    fi
}

# 备份系统配置
backup_system_config() {
    local backup_dir="/tmp/system_optimizer_backup_$(date +%Y%m%d_%H%M%S)"
    
    log_message "创建系统配置备份: $backup_dir"
    
    mkdir -p "$backup_dir"
    
    # 备份内核参数
    if [ -f /etc/sysctl.conf ]; then
        cp /etc/sysctl.conf "$backup_dir/sysctl.conf"
    fi
    
    # 备份limits配置
    if [ -f /etc/security/limits.conf ]; then
        cp /etc/security/limits.conf "$backup_dir/limits.conf"
    fi
    
    # 备份fstab
    if [ -f /etc/fstab ]; then
        cp /etc/fstab "$backup_dir/fstab"
    fi
    
    # 备份网络配置
    if [ -d /etc/sysconfig/network-scripts ]; then
        cp -r /etc/sysconfig/network-scripts "$backup_dir/"
    fi
    
    # 创建备份信息文件
    cat > "$backup_dir/backup_info.txt" << EOF
系统优化备份信息
==================
备份时间: $(date)
备份目录: $backup_dir
优化类型: $OPTIMIZE_TYPE
EOF
    
    output "${GREEN}系统配置备份完成: $backup_dir${NC}"
    BACKUP_CREATED=true
}

# 恢复系统配置
restore_system_config() {
    local restore_file="$1"
    
    if [ -z "$restore_file" ]; then
        echo "${RED}错误: 请指定恢复文件${NC}"
        return 1
    fi
    
    if [ ! -d "$restore_file" ]; then
        echo "${RED}错误: 恢复目录不存在: $restore_file${NC}"
        return 1
    fi
    
    log_message "恢复系统配置: $restore_file"
    
    # 恢复内核参数
    if [ -f "$restore_file/sysctl.conf" ]; then
        cp "$restore_file/sysctl.conf" /etc/sysctl.conf
        sysctl -p
    fi
    
    # 恢复limits配置
    if [ -f "$restore_file/limits.conf" ]; then
        cp "$restore_file/limits.conf" /etc/security/limits.conf
    fi
    
    # 恢复fstab
    if [ -f "$restore_file/fstab" ]; then
        cp "$restore_file/fstab" /etc/fstab
    fi
    
    # 恢复网络配置
    if [ -d "$restore_file/network-scripts" ]; then
        cp -r "$restore_file/network-scripts" /etc/sysconfig/
    fi
    
    output "${GREEN}系统配置恢复完成${NC}"
}

# 优化内存设置
optimize_memory() {
    log_message "优化内存设置"
    
    # 调整swap使用策略
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    
    # 调整内存回收策略
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    
    # 调整内存分配策略
    echo "vm.overcommit_memory=1" >> /etc/sysctl.conf
    
    # 调整内存回收阈值
    echo "vm.dirty_ratio=15" >> /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf
    
    # 调整内存回收时间
    echo "vm.dirty_expire_centisecs=3000" >> /etc/sysctl.conf
    echo "vm.dirty_writeback_centisecs=500" >> /etc/sysctl.conf
    
    # 应用设置
    sysctl -p
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}内存设置优化完成${NC}"
}

# 优化磁盘I/O
optimize_disk() {
    log_message "优化磁盘I/O设置"
    
    # 调整I/O调度器
    echo "kernel.elevator=deadline" >> /etc/sysctl.conf
    
    # 调整文件系统缓存
    echo "vm.dirty_ratio=15" >> /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf
    
    # 调整文件描述符限制
    echo "* soft nofile 65536" >> /etc/security/limits.conf
    echo "* hard nofile 65536" >> /etc/security/limits.conf
    
    # 调整进程限制
    echo "* soft nproc 65536" >> /etc/security/limits.conf
    echo "* hard nproc 65536" >> /etc/security/limits.conf
    
    # 应用设置
    sysctl -p
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}磁盘I/O优化完成${NC}"
}

# 优化网络设置
optimize_network() {
    log_message "优化网络设置"
    
    # 调整TCP缓冲区大小
    echo "net.core.rmem_max=16777216" >> /etc/sysctl.conf
    echo "net.core.wmem_max=16777216" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_rmem=4096 65536 16777216" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_wmem=4096 65536 16777216" >> /etc/sysctl.conf
    
    # 调整TCP连接参数
    echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_slow_start_after_idle=0" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_tw_reuse=1" >> /etc/sysctl.conf
    echo "net.ipv4.tcp_fin_timeout=15" >> /etc/sysctl.conf
    
    # 调整网络缓冲区
    echo "net.core.netdev_max_backlog=5000" >> /etc/sysctl.conf
    echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
    
    # 调整连接跟踪
    echo "net.netfilter.nf_conntrack_max=65536" >> /etc/sysctl.conf
    echo "net.netfilter.nf_conntrack_tcp_timeout_established=1200" >> /etc/sysctl.conf
    
    # 应用设置
    sysctl -p
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}网络设置优化完成${NC}"
}

# 优化内核参数
optimize_kernel() {
    log_message "优化内核参数"
    
    # 调整进程调度
    echo "kernel.sched_rt_runtime_us=-1" >> /etc/sysctl.conf
    
    # 调整中断处理
    echo "kernel.nmi_watchdog=0" >> /etc/sysctl.conf
    
    # 调整内存管理
    echo "kernel.shmmax=68719476736" >> /etc/sysctl.conf
    echo "kernel.shmall=4294967296" >> /etc/sysctl.conf
    
    # 调整文件系统
    echo "fs.file-max=2097152" >> /etc/sysctl.conf
    echo "fs.nr_open=2097152" >> /etc/sysctl.conf
    
    # 调整进程限制
    echo "kernel.pid_max=4194304" >> /etc/sysctl.conf
    
    # 应用设置
    sysctl -p
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}内核参数优化完成${NC}"
}

# 优化系统服务
optimize_services() {
    log_message "优化系统服务"
    
    # 禁用不必要的服务
    local services_to_disable=(
        "bluetooth"
        "cups"
        "avahi-daemon"
        "cups-browsed"
        "ModemManager"
        "whoopsie"
    )
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl disable "$service"
            log_message "禁用服务: $service"
        fi
    done
    
    # 优化系统服务
    local services_to_optimize=(
        "systemd-journald"
        "systemd-logind"
        "systemd-resolved"
    )
    
    for service in "${services_to_optimize[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl restart "$service"
            log_message "重启服务: $service"
        fi
    done
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}系统服务优化完成${NC}"
}

# 优化系统资源
optimize_resources() {
    log_message "优化系统资源"
    
    # 调整系统资源限制
    echo "DefaultLimitNOFILE=65536" >> /etc/systemd/system.conf
    echo "DefaultLimitNPROC=65536" >> /etc/systemd/system.conf
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    # 调整系统资源
    echo "session required pam_limits.so" >> /etc/pam.d/common-session
    
    OPTIMIZATIONS_APPLIED=$((OPTIMIZATIONS_APPLIED + 1))
    output "${GREEN}系统资源优化完成${NC}"
}

# 生成优化报告
generate_optimization_report() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    output ""
    output "=== 系统优化报告 ==="
    output "结束时间: $end_time"
    output "优化类型: $OPTIMIZE_TYPE"
    output "应用优化: $OPTIMIZATIONS_APPLIED"
    output "失败优化: $OPTIMIZATIONS_FAILED"
    
    if [ "$BACKUP_CREATED" = true ]; then
        output "配置备份: 已创建"
    fi
    
    output ""
    output "建议重启系统以应用所有优化设置"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            OPTIMIZE_TYPE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP_CONFIG=true
            shift
            ;;
        -r|--restore)
            RESTORE_FILE="$2"
            shift 2
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

# 检查权限
check_permissions

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 恢复配置
if [ -n "$RESTORE_FILE" ]; then
    restore_system_config "$RESTORE_FILE"
    exit 0
fi

# 备份配置
if [ "$BACKUP_CONFIG" = true ]; then
    backup_system_config
fi

# 执行优化
case $OPTIMIZE_TYPE in
    all)
        optimize_memory
        optimize_disk
        optimize_network
        optimize_kernel
        optimize_services
        optimize_resources
        ;;
    memory)
        optimize_memory
        ;;
    disk)
        optimize_disk
        ;;
    network)
        optimize_network
        ;;
    kernel)
        optimize_kernel
        ;;
    services)
        optimize_services
        ;;
    resources)
        optimize_resources
        ;;
    *)
        echo "错误: 不支持的优化类型: $OPTIMIZE_TYPE"
        exit 1
        ;;
esac

# 生成报告
generate_optimization_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}优化报告已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}系统优化完成${NC}"
fi
