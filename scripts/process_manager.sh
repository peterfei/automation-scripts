#!/bin/bash

# =============================================================================
# 进程管理脚本
# Process Management Script
# =============================================================================
# 
# 用途/Use Case:
# - 监控和管理系统进程
# - 查找和终止特定进程
# - 监控进程资源使用情况
# - 自动重启失败的进程
# 
# 使用方法/Usage:
# ./process_manager.sh [command] [options]
# 
# 命令/Commands:
# list                   列出所有进程
# find <pattern>         查找匹配的进程
# kill <pid|pattern>     终止进程
# monitor <pid>          监控特定进程
# restart <pattern>      重启匹配的进程
# top                    显示资源使用最多的进程
# 
# 选项/Options:
# -u, --user USER        指定用户
# -c, --cpu THRESHOLD    CPU使用率阈值
# -m, --memory THRESHOLD 内存使用率阈值
# -i, --interval SECONDS 监控间隔
# -h, --help             显示帮助信息
# 
# 示例/Examples:
# ./process_manager.sh list
# ./process_manager.sh find nginx
# ./process_manager.sh kill 1234
# ./process_manager.sh monitor 1234 --interval 5
# ./process_manager.sh top --cpu 50 --memory 100
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
USER_FILTER=""
CPU_THRESHOLD=0
MEMORY_THRESHOLD=0
INTERVAL=5
VERBOSE=false

# 显示帮助信息
show_help() {
    echo "进程管理脚本 / Process Management Script"
    echo ""
    echo "用法 / Usage: $0 [命令 / command] [选项 / options]"
    echo ""
    echo "命令 / Commands:"
    echo "  list                   列出所有进程"
    echo "  find <pattern>         查找匹配的进程"
    echo "  kill <pid|pattern>     终止进程"
    echo "  monitor <pid>          监控特定进程"
    echo "  restart <pattern>      重启匹配的进程"
    echo "  top                    显示资源使用最多的进程"
    echo ""
    echo "选项 / Options:"
    echo "  -u, --user USER        指定用户"
    echo "  -c, --cpu THRESHOLD    CPU使用率阈值"
    echo "  -m, --memory THRESHOLD 内存使用率阈值（MB）"
    echo "  -i, --interval SECONDS 监控间隔（秒）"
    echo "  -v, --verbose          详细输出"
    echo "  -h, --help             显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 list"
    echo "  $0 find nginx"
    echo "  $0 kill 1234"
    echo "  $0 monitor 1234 --interval 5"
    echo "  $0 top --cpu 50 --memory 100"
}

# 获取进程列表
get_process_list() {
    local user_filter="$1"
    local cpu_threshold="$2"
    local memory_threshold="$3"
    
    if [ -n "$user_filter" ]; then
        ps aux --sort=-%cpu | awk -v user="$user_filter" -v cpu="$cpu_threshold" -v mem="$memory_threshold" '
        NR==1 {print $0; next}
        $1 == user && ($3 >= cpu || $4 >= mem) {print $0}'
    else
        ps aux --sort=-%cpu | awk -v cpu="$cpu_threshold" -v mem="$memory_threshold" '
        NR==1 {print $0; next}
        $3 >= cpu || $4 >= mem {print $0}'
    fi
}

# 查找进程
find_processes() {
    local pattern="$1"
    local user_filter="$2"
    
    echo "${BLUE}查找进程: $pattern${NC}"
    echo ""
    
    if [ -n "$user_filter" ]; then
        ps aux | grep -v grep | grep "$pattern" | grep "$user_filter"
    else
        ps aux | grep -v grep | grep "$pattern"
    fi
}

# 终止进程
kill_process() {
    local target="$1"
    local user_filter="$2"
    local force=false
    
    # 检查是否是数字（PID）
    if [[ "$target" =~ ^[0-9]+$ ]]; then
        echo "${YELLOW}终止进程 PID: $target${NC}"
        
        # 检查进程是否存在
        if ps -p "$target" > /dev/null 2>&1; then
            # 尝试正常终止
            kill "$target" 2>/dev/null
            sleep 2
            
            # 检查是否还在运行
            if ps -p "$target" > /dev/null 2>&1; then
                echo "${YELLOW}进程仍在运行，强制终止...${NC}"
                kill -9 "$target" 2>/dev/null
                force=true
            fi
            
            if ps -p "$target" > /dev/null 2>&1; then
                echo "${RED}无法终止进程 $target${NC}"
                return 1
            else
                if [ "$force" = true ]; then
                    echo "${GREEN}进程 $target 已强制终止${NC}"
                else
                    echo "${GREEN}进程 $target 已正常终止${NC}"
                fi
            fi
        else
            echo "${RED}进程 $target 不存在${NC}"
            return 1
        fi
    else
        # 按名称查找并终止
        echo "${YELLOW}查找并终止进程: $target${NC}"
        
        local pids
        if [ -n "$user_filter" ]; then
            pids=$(ps aux | grep -v grep | grep "$target" | grep "$user_filter" | awk '{print $2}')
        else
            pids=$(ps aux | grep -v grep | grep "$target" | awk '{print $2}')
        fi
        
        if [ -z "$pids" ]; then
            echo "${RED}未找到匹配的进程: $target${NC}"
            return 1
        fi
        
        for pid in $pids; do
            echo "终止进程 PID: $pid"
            kill "$pid" 2>/dev/null
            sleep 1
            
            if ps -p "$pid" > /dev/null 2>&1; then
                kill -9 "$pid" 2>/dev/null
                echo "${GREEN}进程 $pid 已强制终止${NC}"
            else
                echo "${GREEN}进程 $pid 已正常终止${NC}"
            fi
        done
    fi
}

# 监控进程
monitor_process() {
    local pid="$1"
    local interval="$2"
    
    if ! ps -p "$pid" > /dev/null 2>&1; then
        echo "${RED}进程 $pid 不存在${NC}"
        return 1
    fi
    
    echo "${BLUE}监控进程 PID: $pid (间隔: ${interval}秒)${NC}"
    echo "按 Ctrl+C 停止监控"
    echo ""
    
    # 显示表头
    printf "%-8s %-8s %-8s %-8s %-8s %-8s %-8s %-s\n" "TIME" "PID" "CPU%" "MEM%" "RSS" "VSZ" "STAT" "COMMAND"
    echo "----------------------------------------------------------------"
    
    while true; do
        if ps -p "$pid" > /dev/null 2>&1; then
            local info=$(ps -p "$pid" -o pid,pcpu,pmem,rss,vsz,stat,comm --no-headers)
            local timestamp=$(date '+%H:%M:%S')
            printf "%-8s %s\n" "$timestamp" "$info"
        else
            echo "${RED}进程 $pid 已结束${NC}"
            break
        fi
        
        sleep "$interval"
    done
}

# 重启进程
restart_process() {
    local pattern="$1"
    local user_filter="$2"
    
    echo "${BLUE}重启进程: $pattern${NC}"
    
    # 查找进程
    local pids
    if [ -n "$user_filter" ]; then
        pids=$(ps aux | grep -v grep | grep "$pattern" | grep "$user_filter" | awk '{print $2}')
    else
        pids=$(ps aux | grep -v grep | grep "$pattern" | awk '{print $2}')
    fi
    
    if [ -z "$pids" ]; then
        echo "${RED}未找到匹配的进程: $pattern${NC}"
        return 1
    fi
    
    # 终止进程
    for pid in $pids; do
        echo "终止进程 PID: $pid"
        kill "$pid" 2>/dev/null
        sleep 2
        
        if ps -p "$pid" > /dev/null 2>&1; then
            kill -9 "$pid" 2>/dev/null
        fi
    done
    
    echo "${GREEN}进程已终止，请手动重启服务${NC}"
}

# 显示资源使用最多的进程
show_top_processes() {
    local cpu_threshold="$1"
    local memory_threshold="$2"
    local user_filter="$3"
    
    echo "${BLUE}资源使用最多的进程 / Top Resource Consuming Processes${NC}"
    echo ""
    
    if [ "$cpu_threshold" -gt 0 ] || [ "$memory_threshold" -gt 0 ]; then
        echo "阈值过滤 / Threshold Filter:"
        [ "$cpu_threshold" -gt 0 ] && echo "  CPU使用率 >= ${cpu_threshold}%"
        [ "$memory_threshold" -gt 0 ] && echo "  内存使用 >= ${memory_threshold}MB"
        echo ""
    fi
    
    get_process_list "$user_filter" "$cpu_threshold" "$memory_threshold"
}

# 列出所有进程
list_processes() {
    local user_filter="$1"
    
    echo "${BLUE}进程列表 / Process List${NC}"
    echo ""
    
    if [ -n "$user_filter" ]; then
        echo "用户过滤 / User filter: $user_filter"
        echo ""
        ps aux | head -1
        ps aux | tail -n +2 | grep "$user_filter"
    else
        ps aux
    fi
}

# 解析命令行参数
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        list|find|kill|monitor|restart|top)
            COMMAND="$1"
            shift
            break
            ;;
        -u|--user)
            USER_FILTER="$2"
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
        -i|--interval)
            INTERVAL="$2"
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

# 检查命令
if [ -z "$COMMAND" ]; then
    echo "错误: 请指定命令"
    show_help
    exit 1
fi

# 执行命令
case $COMMAND in
    list)
        list_processes "$USER_FILTER"
        ;;
    find)
        if [ $# -lt 1 ]; then
            echo "错误: 请指定查找模式"
            exit 1
        fi
        find_processes "$1" "$USER_FILTER"
        ;;
    kill)
        if [ $# -lt 1 ]; then
            echo "错误: 请指定要终止的进程"
            exit 1
        fi
        kill_process "$1" "$USER_FILTER"
        ;;
    monitor)
        if [ $# -lt 1 ]; then
            echo "错误: 请指定要监控的进程ID"
            exit 1
        fi
        monitor_process "$1" "$INTERVAL"
        ;;
    restart)
        if [ $# -lt 1 ]; then
            echo "错误: 请指定要重启的进程模式"
            exit 1
        fi
        restart_process "$1" "$USER_FILTER"
        ;;
    top)
        show_top_processes "$CPU_THRESHOLD" "$MEMORY_THRESHOLD" "$USER_FILTER"
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
