#!/bin/bash

# =============================================================================
# Cron任务管理脚本
# Cron Job Management Script
# =============================================================================
# 
# 用途/Use Case:
# - 管理Cron任务
# - 添加、删除、列出定时任务
# - 备份和恢复Cron配置
# - 监控Cron任务执行
# 
# 使用方法/Usage:
# ./cron_manager.sh [command] [options]
# 
# 命令/Commands:
# add                     添加Cron任务
# remove                  删除Cron任务
# list                    列出Cron任务
# edit                    编辑Cron任务
# backup                  备份Cron配置
# restore                 恢复Cron配置
# monitor                 监控Cron任务
# 
# 选项/Options:
# -u, --user USER         指定用户
# -c, --cron CRON         时间表达式
# -s, --script SCRIPT     脚本路径
# -d, --description DESC  任务描述
# -f, --file FILE         配置文件
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./cron_manager.sh add --cron "0 2 * * *" --script "/path/to/script.sh"
# ./cron_manager.sh list --user root
# ./cron_manager.sh backup --file cron_backup.txt
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
COMMAND=""
USER=""
CRON_EXPR=""
SCRIPT_PATH=""
DESCRIPTION=""
CONFIG_FILE=""
VERBOSE=false

# 显示帮助信息
show_help() {
    echo "Cron任务管理脚本 / Cron Job Management Script"
    echo ""
    echo "用法 / Usage: $0 [命令 / command] [选项 / options]"
    echo ""
    echo "命令 / Commands:"
    echo "  add                     添加Cron任务"
    echo "  remove                  删除Cron任务"
    echo "  list                    列出Cron任务"
    echo "  edit                    编辑Cron任务"
    echo "  backup                  备份Cron配置"
    echo "  restore                 恢复Cron配置"
    echo "  monitor                 监控Cron任务"
    echo ""
    echo "选项 / Options:"
    echo "  -u, --user USER         指定用户"
    echo "  -c, --cron CRON         时间表达式"
    echo "  -s, --script SCRIPT     脚本路径"
    echo "  -d, --description DESC  任务描述"
    echo "  -f, --file FILE         配置文件"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 add --cron \"0 2 * * *\" --script \"/path/to/script.sh\""
    echo "  $0 list --user root"
    echo "  $0 backup --file cron_backup.txt"
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
    echo "$1"
}

# 检查Cron服务
check_cron_service() {
    if ! command -v crontab &> /dev/null; then
        echo "${RED}错误: crontab命令不可用${NC}"
        exit 1
    fi
    
    # 检查Cron服务是否运行
    if command -v systemctl &> /dev/null; then
        if ! systemctl is-active --quiet cron 2>/dev/null && ! systemctl is-active --quiet crond 2>/dev/null; then
            echo "${YELLOW}警告: Cron服务可能未运行${NC}"
        fi
    fi
}

# 获取Cron文件路径
get_cron_file() {
    local user="$1"
    
    if [ -z "$user" ]; then
        user=$(whoami)
    fi
    
    if [ "$user" = "root" ]; then
        echo "/var/spool/cron/crontabs/root"
    else
        echo "/var/spool/cron/crontabs/$user"
    fi
}

# 添加Cron任务
add_cron_job() {
    local user="$1"
    local cron_expr="$2"
    local script_path="$3"
    local description="$4"
    
    if [ -z "$cron_expr" ] || [ -z "$script_path" ]; then
        echo "${RED}错误: 请指定时间表达式和脚本路径${NC}"
        return 1
    fi
    
    if [ ! -f "$script_path" ]; then
        echo "${RED}错误: 脚本文件不存在: $script_path${NC}"
        return 1
    fi
    
    # 确保脚本可执行
    chmod +x "$script_path"
    
    log_message "添加Cron任务: $script_path"
    
    # 创建临时Cron文件
    local temp_cron=$(mktemp)
    crontab -u "$user" -l > "$temp_cron" 2>/dev/null || touch "$temp_cron"
    
    # 添加新任务
    if [ -n "$description" ]; then
        echo "# $description" >> "$temp_cron"
    fi
    echo "$cron_expr $script_path" >> "$temp_cron"
    
    # 安装新的Cron配置
    if crontab -u "$user" "$temp_cron"; then
        output "${GREEN}Cron任务添加成功${NC}"
        rm -f "$temp_cron"
        return 0
    else
        output "${RED}Cron任务添加失败${NC}"
        rm -f "$temp_cron"
        return 1
    fi
}

# 删除Cron任务
remove_cron_job() {
    local user="$1"
    local script_path="$2"
    
    if [ -z "$script_path" ]; then
        echo "${RED}错误: 请指定要删除的脚本路径${NC}"
        return 1
    fi
    
    log_message "删除Cron任务: $script_path"
    
    # 创建临时Cron文件
    local temp_cron=$(mktemp)
    crontab -u "$user" -l > "$temp_cron" 2>/dev/null || touch "$temp_cron"
    
    # 删除匹配的任务
    grep -v "$script_path" "$temp_cron" > "${temp_cron}.new"
    mv "${temp_cron}.new" "$temp_cron"
    
    # 安装新的Cron配置
    if crontab -u "$user" "$temp_cron"; then
        output "${GREEN}Cron任务删除成功${NC}"
        rm -f "$temp_cron"
        return 0
    else
        output "${RED}Cron任务删除失败${NC}"
        rm -f "$temp_cron"
        return 1
    fi
}

# 列出Cron任务
list_cron_jobs() {
    local user="$1"
    
    output "${BLUE}Cron任务列表 / Cron Jobs List${NC}"
    output "用户: $user"
    output ""
    
    if crontab -u "$user" -l 2>/dev/null; then
        return 0
    else
        output "${YELLOW}未找到Cron任务${NC}"
        return 1
    fi
}

# 编辑Cron任务
edit_cron_jobs() {
    local user="$1"
    
    log_message "编辑Cron任务: $user"
    
    if crontab -u "$user" -e; then
        output "${GREEN}Cron任务编辑完成${NC}"
        return 0
    else
        output "${RED}Cron任务编辑失败${NC}"
        return 1
    fi
}

# 备份Cron配置
backup_cron_config() {
    local user="$1"
    local backup_file="$2"
    
    if [ -z "$backup_file" ]; then
        backup_file="cron_backup_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    log_message "备份Cron配置: $user -> $backup_file"
    
    if crontab -u "$user" -l > "$backup_file" 2>/dev/null; then
        output "${GREEN}Cron配置备份成功: $backup_file${NC}"
        return 0
    else
        output "${RED}Cron配置备份失败${NC}"
        return 1
    fi
}

# 恢复Cron配置
restore_cron_config() {
    local user="$1"
    local backup_file="$2"
    
    if [ -z "$backup_file" ]; then
        echo "${RED}错误: 请指定备份文件${NC}"
        return 1
    fi
    
    if [ ! -f "$backup_file" ]; then
        echo "${RED}错误: 备份文件不存在: $backup_file${NC}"
        return 1
    fi
    
    log_message "恢复Cron配置: $backup_file -> $user"
    
    if crontab -u "$user" "$backup_file"; then
        output "${GREEN}Cron配置恢复成功${NC}"
        return 0
    else
        output "${RED}Cron配置恢复失败${NC}"
        return 1
    fi
}

# 监控Cron任务
monitor_cron_jobs() {
    local user="$1"
    
    output "${BLUE}监控Cron任务 / Monitoring Cron Jobs${NC}"
    output "用户: $user"
    output ""
    
    # 检查Cron日志
    local log_files=(
        "/var/log/cron"
        "/var/log/cron.log"
        "/var/log/syslog"
    )
    
    for log_file in "${log_files[@]}"; do
        if [ -f "$log_file" ]; then
            output "检查日志文件: $log_file"
            grep -i "cron" "$log_file" | tail -10
            output ""
        fi
    done
    
    # 检查最近的Cron任务执行
    if [ -d "/var/spool/cron/crontabs" ]; then
        local cron_file="/var/spool/cron/crontabs/$user"
        if [ -f "$cron_file" ]; then
            output "当前Cron任务:"
            cat "$cron_file"
            output ""
        fi
    fi
}

# 从配置文件批量添加Cron任务
add_cron_from_file() {
    local user="$1"
    local config_file="$2"
    
    if [ ! -f "$config_file" ]; then
        echo "${RED}错误: 配置文件不存在: $config_file${NC}"
        return 1
    fi
    
    log_message "从配置文件添加Cron任务: $config_file"
    
    local success_count=0
    local fail_count=0
    
    while IFS= read -r line; do
        # 跳过空行和注释
        if [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 解析配置行
        local cron_expr=$(echo "$line" | cut -d'|' -f1 | xargs)
        local script_path=$(echo "$line" | cut -d'|' -f2 | xargs)
        local description=$(echo "$line" | cut -d'|' -f3 | xargs)
        
        if [ -n "$cron_expr" ] && [ -n "$script_path" ]; then
            if add_cron_job "$user" "$cron_expr" "$script_path" "$description"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
        fi
    done < "$config_file"
    
    output "批量添加完成: 成功 $success_count 个，失败 $fail_count 个"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        add|remove|list|edit|backup|restore|monitor)
            COMMAND="$1"
            shift
            break
            ;;
        -u|--user)
            USER="$2"
            shift 2
            ;;
        -c|--cron)
            CRON_EXPR="$2"
            shift 2
            ;;
        -s|--script)
            SCRIPT_PATH="$2"
            shift 2
            ;;
        -d|--description)
            DESCRIPTION="$2"
            shift 2
            ;;
        -f|--file)
            CONFIG_FILE="$2"
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

# 设置默认用户
if [ -z "$USER" ]; then
    USER=$(whoami)
fi

# 检查Cron服务
check_cron_service

# 执行命令
case $COMMAND in
    add)
        if [ -n "$CONFIG_FILE" ]; then
            add_cron_from_file "$USER" "$CONFIG_FILE"
        else
            add_cron_job "$USER" "$CRON_EXPR" "$SCRIPT_PATH" "$DESCRIPTION"
        fi
        ;;
    remove)
        remove_cron_job "$USER" "$SCRIPT_PATH"
        ;;
    list)
        list_cron_jobs "$USER"
        ;;
    edit)
        edit_cron_jobs "$USER"
        ;;
    backup)
        backup_cron_config "$USER" "$CONFIG_FILE"
        ;;
    restore)
        restore_cron_config "$USER" "$CONFIG_FILE"
        ;;
    monitor)
        monitor_cron_jobs "$USER"
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
