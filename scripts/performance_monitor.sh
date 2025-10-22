#!/bin/bash

# =============================================================================
# 性能监控脚本
# Performance Monitoring Script
# =============================================================================
# 
# 用途/Use Case:
# - 监控系统性能指标
# - 记录CPU、内存、磁盘使用情况
# - 生成性能报告
# - 检测性能异常
# 
# 使用方法/Usage:
# ./performance_monitor.sh [options]
# 
# 选项/Options:
# -i, --interval SECONDS  监控间隔（秒），默认5秒
# -d, --duration SECONDS  监控持续时间，默认300秒
# -o, --output FILE       输出文件
# -c, --cpu THRESHOLD     CPU使用率阈值
# -m, --memory THRESHOLD  内存使用率阈值
# -s, --disk THRESHOLD    磁盘使用率阈值
# -a, --alert EMAIL       发送告警邮件
# -l, --log FILE          日志文件
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./performance_monitor.sh --interval 10 --duration 600
# ./performance_monitor.sh --cpu 80 --memory 90 --alert admin@example.com
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
INTERVAL=5
DURATION=300
OUTPUT_FILE=""
CPU_THRESHOLD=0
MEMORY_THRESHOLD=0
DISK_THRESHOLD=0
ALERT_EMAIL=""
LOG_FILE=""
VERBOSE=false

# 统计变量
TOTAL_SAMPLES=0
CPU_ALERTS=0
MEMORY_ALERTS=0
DISK_ALERTS=0
MAX_CPU=0
MAX_MEMORY=0
MAX_DISK=0
AVG_CPU=0
AVG_MEMORY=0
AVG_DISK=0

# 显示帮助信息
show_help() {
    echo "性能监控脚本 / Performance Monitoring Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -i, --interval SECONDS  监控间隔（秒），默认5秒"
    echo "  -d, --duration SECONDS  监控持续时间，默认300秒"
    echo "  -o, --output FILE       输出文件"
    echo "  -c, --cpu THRESHOLD     CPU使用率阈值"
    echo "  -m, --memory THRESHOLD  内存使用率阈值"
    echo "  -s, --disk THRESHOLD    磁盘使用率阈值"
    echo "  -a, --alert EMAIL       发送告警邮件"
    echo "  -l, --log FILE          日志文件"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --interval 10 --duration 600"
    echo "  $0 --cpu 80 --memory 90 --alert admin@example.com"
}

# 日志函数
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] $message"
    
    if [ -n "$LOG_FILE" ]; then
        echo "$log_entry" >> "$LOG_FILE"
    fi
    
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

# 获取CPU使用率
get_cpu_usage() {
    if command -v top &> /dev/null; then
        # 使用top命令
        top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1
    elif command -v vmstat &> /dev/null; then
        # 使用vmstat命令
        vmstat 1 2 | tail -1 | awk '{print 100-$15}'
    elif [ -f /proc/stat ]; then
        # 使用/proc/stat
        local cpu_info=$(cat /proc/stat | grep "cpu " | awk '{print $2" "$3" "$4" "$5" "$6" "$7" "$8}')
        local idle=$(echo $cpu_info | awk '{print $4}')
        local total=$(echo $cpu_info | awk '{sum=$1+$2+$3+$4+$5+$6+$7; print sum}')
        echo "scale=2; 100 - ($idle * 100 / $total)" | bc -l 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 获取内存使用率
get_memory_usage() {
    if command -v free &> /dev/null; then
        # 使用free命令
        free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}'
    elif [ -f /proc/meminfo ]; then
        # 使用/proc/meminfo
        local mem_total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        local mem_available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
        if [ -n "$mem_available" ]; then
            local mem_used=$((mem_total - mem_available))
            echo "scale=2; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "0"
        else
            local mem_free=$(grep MemFree /proc/meminfo | awk '{print $2}')
            local mem_used=$((mem_total - mem_free))
            echo "scale=2; $mem_used * 100 / $mem_total" | bc -l 2>/dev/null || echo "0"
        fi
    else
        echo "0"
    fi
}

# 获取磁盘使用率
get_disk_usage() {
    if command -v df &> /dev/null; then
        # 使用df命令，获取根分区使用率
        df / | tail -1 | awk '{print $5}' | cut -d'%' -f1
    else
        echo "0"
    fi
}

# 获取网络统计
get_network_stats() {
    if [ -f /proc/net/dev ]; then
        local rx_bytes=$(cat /proc/net/dev | grep -v "lo:" | awk '{sum+=$2} END {print sum}')
        local tx_bytes=$(cat /proc/net/dev | grep -v "lo:" | awk '{sum+=$10} END {print sum}')
        echo "$rx_bytes $tx_bytes"
    else
        echo "0 0"
    fi
}

# 获取负载平均值
get_load_average() {
    if [ -f /proc/loadavg ]; then
        cat /proc/loadavg | awk '{print $1" "$2" "$3}'
    elif command -v uptime &> /dev/null; then
        uptime | awk -F'load average:' '{print $2}' | sed 's/^[ \t]*//'
    else
        echo "0.00 0.00 0.00"
    fi
}

# 检查阈值告警
check_thresholds() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local disk_usage="$3"
    local timestamp="$4"
    
    local alerts=()
    
    # 检查CPU阈值
    if [ "$CPU_THRESHOLD" -gt 0 ] && (( $(echo "$cpu_usage > $CPU_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alerts+=("CPU使用率过高: ${cpu_usage}% (阈值: ${CPU_THRESHOLD}%)")
        CPU_ALERTS=$((CPU_ALERTS + 1))
    fi
    
    # 检查内存阈值
    if [ "$MEMORY_THRESHOLD" -gt 0 ] && (( $(echo "$memory_usage > $MEMORY_THRESHOLD" | bc -l 2>/dev/null || echo "0") )); then
        alerts+=("内存使用率过高: ${memory_usage}% (阈值: ${MEMORY_THRESHOLD}%)")
        MEMORY_ALERTS=$((MEMORY_ALERTS + 1))
    fi
    
    # 检查磁盘阈值
    if [ "$DISK_THRESHOLD" -gt 0 ] && [ "$disk_usage" -gt "$DISK_THRESHOLD" ]; then
        alerts+=("磁盘使用率过高: ${disk_usage}% (阈值: ${DISK_THRESHOLD}%)")
        DISK_ALERTS=$((DISK_ALERTS + 1))
    fi
    
    # 发送告警
    if [ ${#alerts[@]} -gt 0 ] && [ -n "$ALERT_EMAIL" ]; then
        local subject="性能监控告警 - $timestamp"
        local body="检测到以下性能问题:\n\n"
        for alert in "${alerts[@]}"; do
            body+="$alert\n"
        done
        body+="\n请及时处理。"
        
        if command -v mail &> /dev/null; then
            echo -e "$body" | mail -s "$subject" "$ALERT_EMAIL"
        elif command -v sendmail &> /dev/null; then
            echo -e "$body" | sendmail "$ALERT_EMAIL"
        fi
    fi
    
    # 输出告警信息
    for alert in "${alerts[@]}"; do
        log_message "告警: $alert"
    done
}

# 更新统计信息
update_statistics() {
    local cpu_usage="$1"
    local memory_usage="$2"
    local disk_usage="$3"
    
    TOTAL_SAMPLES=$((TOTAL_SAMPLES + 1))
    
    # 更新最大值
    if (( $(echo "$cpu_usage > $MAX_CPU" | bc -l 2>/dev/null || echo "0") )); then
        MAX_CPU="$cpu_usage"
    fi
    
    if (( $(echo "$memory_usage > $MAX_MEMORY" | bc -l 2>/dev/null || echo "0") )); then
        MAX_MEMORY="$memory_usage"
    fi
    
    if [ "$disk_usage" -gt "$MAX_DISK" ]; then
        MAX_DISK="$disk_usage"
    fi
    
    # 更新平均值
    AVG_CPU=$(echo "scale=2; ($AVG_CPU * ($TOTAL_SAMPLES - 1) + $cpu_usage) / $TOTAL_SAMPLES" | bc -l 2>/dev/null || echo "$AVG_CPU")
    AVG_MEMORY=$(echo "scale=2; ($AVG_MEMORY * ($TOTAL_SAMPLES - 1) + $memory_usage) / $TOTAL_SAMPLES" | bc -l 2>/dev/null || echo "$AVG_MEMORY")
    AVG_DISK=$(echo "scale=2; ($AVG_DISK * ($TOTAL_SAMPLES - 1) + $disk_usage) / $TOTAL_SAMPLES" | bc -l 2>/dev/null || echo "$AVG_DISK")
}

# 监控循环
monitor_loop() {
    local start_time=$(date +%s)
    local end_time=$((start_time + DURATION))
    
    log_message "开始性能监控 (间隔: ${INTERVAL}秒, 持续时间: ${DURATION}秒)"
    
    # 输出表头
    output "时间,CPU使用率(%),内存使用率(%),磁盘使用率(%),负载平均值,网络RX(KB),网络TX(KB)"
    
    while [ $(date +%s) -lt $end_time ]; do
        local current_time=$(date '+%Y-%m-%d %H:%M:%S')
        local cpu_usage=$(get_cpu_usage)
        local memory_usage=$(get_memory_usage)
        local disk_usage=$(get_disk_usage)
        local load_avg=$(get_load_average)
        local network_stats=$(get_network_stats)
        local rx_bytes=$(echo $network_stats | awk '{print $1}')
        local tx_bytes=$(echo $network_stats | awk '{print $2}')
        local rx_kb=$((rx_bytes / 1024))
        local tx_kb=$((tx_bytes / 1024))
        
        # 输出数据
        output "$current_time,$cpu_usage,$memory_usage,$disk_usage,$load_avg,$rx_kb,$tx_kb"
        
        # 更新统计信息
        update_statistics "$cpu_usage" "$memory_usage" "$disk_usage"
        
        # 检查阈值告警
        check_thresholds "$cpu_usage" "$memory_usage" "$disk_usage" "$current_time"
        
        # 显示当前状态
        if [ "$VERBOSE" = true ]; then
            echo "[$current_time] CPU: ${cpu_usage}% | 内存: ${memory_usage}% | 磁盘: ${disk_usage}% | 负载: $load_avg"
        fi
        
        sleep "$INTERVAL"
    done
}

# 生成报告
generate_report() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    output ""
    output "=== 性能监控报告 ==="
    output "结束时间: $end_time"
    output "监控样本数: $TOTAL_SAMPLES"
    output ""
    output "统计信息:"
    output "  CPU使用率:"
    output "    平均: ${AVG_CPU}%"
    output "    最大: ${MAX_CPU}%"
    output "    告警次数: $CPU_ALERTS"
    output ""
    output "  内存使用率:"
    output "    平均: ${AVG_MEMORY}%"
    output "    最大: ${MAX_MEMORY}%"
    output "    告警次数: $MEMORY_ALERTS"
    output ""
    output "  磁盘使用率:"
    output "    平均: ${AVG_DISK}%"
    output "    最大: ${MAX_DISK}%"
    output "    告警次数: $DISK_ALERTS"
    output ""
    output "总告警次数: $((CPU_ALERTS + MEMORY_ALERTS + DISK_ALERTS))"
}

# 清理函数
cleanup() {
    echo ""
    echo "${YELLOW}监控被中断 / Monitoring interrupted${NC}"
    generate_report
    exit 0
}

# 设置信号处理
trap cleanup SIGINT SIGTERM

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        -c|--cpu)
            CPU_THRESHOLD="$2"
            shift 2
            ;;
        -m|--memory)
            MEMORY_THRESHOLD="$2"
            shift 2
            ;;
        -s|--disk)
            DISK_THRESHOLD="$2"
            shift 2
            ;;
        -a|--alert)
            ALERT_EMAIL="$2"
            shift 2
            ;;
        -l|--log)
            LOG_FILE="$2"
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

# 验证参数
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo "错误: 监控间隔必须是正整数"
    exit 1
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo "错误: 监控持续时间必须是正整数"
    exit 1
fi

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 开始监控
monitor_loop

# 生成最终报告
generate_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}监控数据已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}性能监控完成${NC}"
fi
