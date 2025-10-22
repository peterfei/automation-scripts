#!/bin/bash

# =============================================================================
# 网络监控脚本
# Network Monitoring Script
# =============================================================================
# 
# 用途/Use Case:
# - 监控网络连接状态
# - 检测网络延迟和丢包
# - 监控带宽使用情况
# - 检测网络服务可用性
# 
# 使用方法/Usage:
# ./network_monitor.sh [options]
# 
# 选项/Options:
# -i, --interval SECONDS  监控间隔（秒），默认5秒
# -c, --count TIMES       监控次数，默认无限次
# -t, --target HOST       目标主机，默认8.8.8.8
# -p, --port PORT         目标端口，默认80
# -l, --log FILE          日志文件路径
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./network_monitor.sh --interval 10 --count 5
# ./network_monitor.sh --target google.com --port 443
# ./network_monitor.sh --log network.log
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
NC='\033[0m' # No Color

# 默认配置
INTERVAL=5
COUNT=0
TARGET="8.8.8.8"
PORT=80
LOG_FILE=""
VERBOSE=false

# 统计变量
TOTAL_PINGS=0
SUCCESSFUL_PINGS=0
FAILED_PINGS=0
MIN_LATENCY=999999
MAX_LATENCY=0
TOTAL_LATENCY=0

# 显示帮助信息
show_help() {
    echo "网络监控脚本 / Network Monitoring Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -i, --interval SECONDS  监控间隔（秒），默认5秒"
    echo "  -c, --count TIMES       监控次数，默认无限次"
    echo "  -t, --target HOST       目标主机，默认8.8.8.8"
    echo "  -p, --port PORT         目标端口，默认80"
    echo "  -l, --log FILE          日志文件路径"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --interval 10 --count 5"
    echo "  $0 --target google.com --port 443"
    echo "  $0 --log network.log"
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

# 检查网络连接
check_connectivity() {
    local host="$1"
    local port="$2"
    
    # 使用nc检查端口连接
    if command -v nc &> /dev/null; then
        timeout 3 nc -z "$host" "$port" 2>/dev/null
        return $?
    elif command -v telnet &> /dev/null; then
        timeout 3 telnet "$host" "$port" 2>/dev/null | grep -q "Connected"
        return $?
    else
        # 使用ping作为备选
        ping -c 1 -W 3 "$host" &>/dev/null
        return $?
    fi
}

# 测试网络延迟
test_latency() {
    local host="$1"
    local result
    
    if command -v ping &> /dev/null; then
        result=$(ping -c 1 -W 3 "$host" 2>/dev/null | grep "time=" | sed 's/.*time=\([0-9.]*\).*/\1/')
        if [ -n "$result" ]; then
            echo "$result"
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# 获取网络接口信息
get_interface_info() {
    echo "${BLUE}网络接口信息 / Network Interface Information:${NC}"
    
    if command -v ip &> /dev/null; then
        ip addr show | grep -E "inet |UP|DOWN" | while read line; do
            echo "  $line"
        done
    elif command -v ifconfig &> /dev/null; then
        ifconfig | grep -E "inet |UP|DOWN" | while read line; do
            echo "  $line"
        done
    fi
    echo ""
}

# 获取网络统计信息
get_network_stats() {
    echo "${BLUE}网络统计信息 / Network Statistics:${NC}"
    
    if [ -f /proc/net/dev ]; then
        echo "接口统计 / Interface Statistics:"
        cat /proc/net/dev | head -2
        cat /proc/net/dev | tail -n +3 | while read line; do
            echo "  $line"
        done
    fi
    echo ""
}

# 监控网络状态
monitor_network() {
    local iteration=0
    
    echo "${GREEN}开始网络监控 / Starting network monitoring...${NC}"
    echo "目标主机 / Target: $TARGET"
    echo "目标端口 / Port: $PORT"
    echo "监控间隔 / Interval: ${INTERVAL}秒"
    if [ -n "$LOG_FILE" ]; then
        echo "日志文件 / Log file: $LOG_FILE"
    fi
    echo ""
    
    # 显示初始网络信息
    get_interface_info
    get_network_stats
    
    while true; do
        iteration=$((iteration + 1))
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # 检查连接
        if check_connectivity "$TARGET" "$PORT"; then
            status="${GREEN}连接正常${NC}"
            SUCCESSFUL_PINGS=$((SUCCESSFUL_PINGS + 1))
            
            # 测试延迟
            latency=$(test_latency "$TARGET")
            if [ "$latency" != "0" ]; then
                TOTAL_LATENCY=$(echo "$TOTAL_LATENCY + $latency" | bc -l 2>/dev/null || echo "$TOTAL_LATENCY")
                
                # 更新最小和最大延迟
                if (( $(echo "$latency < $MIN_LATENCY" | bc -l 2>/dev/null || echo "0") )); then
                    MIN_LATENCY="$latency"
                fi
                if (( $(echo "$latency > $MAX_LATENCY" | bc -l 2>/dev/null || echo "0") )); then
                    MAX_LATENCY="$latency"
                fi
                
                status="$status (延迟: ${latency}ms)"
            fi
        else
            status="${RED}连接失败${NC}"
            FAILED_PINGS=$((FAILED_PINGS + 1))
        fi
        
        TOTAL_PINGS=$((TOTAL_PINGS + 1))
        
        # 显示状态
        echo "[$timestamp] 第${iteration}次检查 / Check #$iteration: $status"
        
        # 记录日志
        log_message "Check #$iteration: $status"
        
        # 检查是否达到指定次数
        if [ "$COUNT" -gt 0 ] && [ "$iteration" -ge "$COUNT" ]; then
            break
        fi
        
        # 等待下次检查
        sleep "$INTERVAL"
    done
}

# 显示统计信息
show_statistics() {
    echo ""
    echo "${BLUE}监控统计信息 / Monitoring Statistics:${NC}"
    echo "总检查次数 / Total checks: $TOTAL_PINGS"
    echo "成功次数 / Successful: $SUCCESSFUL_PINGS"
    echo "失败次数 / Failed: $FAILED_PINGS"
    
    if [ "$TOTAL_PINGS" -gt 0 ]; then
        success_rate=$(echo "scale=2; $SUCCESSFUL_PINGS * 100 / $TOTAL_PINGS" | bc -l 2>/dev/null || echo "0")
        echo "成功率 / Success rate: ${success_rate}%"
    fi
    
    if [ "$SUCCESSFUL_PINGS" -gt 0 ] && [ "$TOTAL_LATENCY" != "0" ]; then
        avg_latency=$(echo "scale=2; $TOTAL_LATENCY / $SUCCESSFUL_PINGS" | bc -l 2>/dev/null || echo "0")
        echo "平均延迟 / Average latency: ${avg_latency}ms"
        echo "最小延迟 / Min latency: ${MIN_LATENCY}ms"
        echo "最大延迟 / Max latency: ${MAX_LATENCY}ms"
    fi
}

# 清理函数
cleanup() {
    echo ""
    echo "${YELLOW}监控被中断 / Monitoring interrupted${NC}"
    show_statistics
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
        -c|--count)
            COUNT="$2"
            shift 2
            ;;
        -t|--target)
            TARGET="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
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

if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
    echo "错误: 监控次数必须是非负整数"
    exit 1
fi

if ! [[ "$PORT" =~ ^[0-9]+$ ]] || [ "$PORT" -lt 1 ] || [ "$PORT" -gt 65535 ]; then
    echo "错误: 端口必须是1-65535之间的整数"
    exit 1
fi

# 检查必要的命令
if ! command -v ping &> /dev/null && ! command -v nc &> /dev/null && ! command -v telnet &> /dev/null; then
    echo "错误: 需要安装ping、nc或telnet命令"
    exit 1
fi

# 开始监控
monitor_network

# 显示最终统计
show_statistics

echo "${GREEN}网络监控完成 / Network monitoring completed!${NC}"
