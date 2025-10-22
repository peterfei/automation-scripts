#!/bin/bash

# =============================================================================
# 文件同步脚本
# File Synchronization Script
# =============================================================================
# 
# 用途/Use Case:
# - 同步文件和目录
# - 支持本地和远程同步
# - 增量同步
# - 冲突检测和解决
# 
# 使用方法/Usage:
# ./file_sync.sh [options] [source] [destination]
# 
# 选项/Options:
# -s, --source PATH       源路径
# -d, --dest PATH         目标路径
# -r, --remote HOST       远程主机
# -u, --user USER         远程用户
# -p, --port PORT         远程端口
# -k, --key FILE          SSH密钥文件
# -e, --exclude PATTERN   排除模式
# -i, --include PATTERN   包含模式
# -a, --archive           归档模式
# -v, --verbose           详细输出
# -d, --dry-run           试运行
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./file_sync.sh --source /local/path --dest /remote/path
# ./file_sync.sh --source /local/path --remote user@host --dest /remote/path
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
SOURCE_PATH=""
DEST_PATH=""
REMOTE_HOST=""
REMOTE_USER=""
REMOTE_PORT=22
SSH_KEY=""
EXCLUDE_PATTERNS=()
INCLUDE_PATTERNS=()
ARCHIVE_MODE=false
VERBOSE=false
DRY_RUN=false

# 统计变量
TOTAL_FILES=0
SYNCED_FILES=0
SKIPPED_FILES=0
ERROR_FILES=0
TOTAL_SIZE=0

# 显示帮助信息
show_help() {
    echo "文件同步脚本 / File Synchronization Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options] [源路径 / source] [目标路径 / destination]"
    echo ""
    echo "选项 / Options:"
    echo "  -s, --source PATH       源路径"
    echo "  -d, --dest PATH         目标路径"
    echo "  -r, --remote HOST       远程主机"
    echo "  -u, --user USER         远程用户"
    echo "  -p, --port PORT         远程端口"
    echo "  -k, --key FILE          SSH密钥文件"
    echo "  -e, --exclude PATTERN   排除模式"
    echo "  -i, --include PATTERN   包含模式"
    echo "  -a, --archive           归档模式"
    echo "  -v, --verbose           详细输出"
    echo "  -d, --dry-run           试运行"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --source /local/path --dest /remote/path"
    echo "  $0 --source /local/path --remote user@host --dest /remote/path"
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

# 检查必要的命令
check_dependencies() {
    local missing_deps=()
    
    if ! command -v rsync &> /dev/null; then
        missing_deps+=("rsync")
    fi
    
    if [ -n "$REMOTE_HOST" ] && ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "${RED}错误: 缺少必要的命令: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# 构建rsync命令
build_rsync_command() {
    local source="$1"
    local dest="$2"
    local remote_host="$3"
    local remote_user="$4"
    local remote_port="$5"
    local ssh_key="$6"
    local exclude_patterns="$7"
    local include_patterns="$8"
    local archive_mode="$9"
    local dry_run="$10"
    
    local cmd="rsync"
    
    # 基本选项
    if [ "$archive_mode" = true ]; then
        cmd="$cmd -a"
    else
        cmd="$cmd -r"
    fi
    
    cmd="$cmd -v"
    
    if [ "$dry_run" = true ]; then
        cmd="$cmd --dry-run"
    fi
    
    # 排除模式
    for pattern in "${exclude_patterns[@]}"; do
        cmd="$cmd --exclude='$pattern'"
    done
    
    # 包含模式
    for pattern in "${include_patterns[@]}"; do
        cmd="$cmd --include='$pattern'"
    done
    
    # 远程连接
    if [ -n "$remote_host" ]; then
        local ssh_cmd="ssh"
        
        if [ -n "$remote_port" ]; then
            ssh_cmd="$ssh_cmd -p $remote_port"
        fi
        
        if [ -n "$ssh_key" ]; then
            ssh_cmd="$ssh_cmd -i $ssh_key"
        fi
        
        if [ -n "$remote_user" ]; then
            dest="$remote_user@$remote_host:$dest"
        else
            dest="$remote_host:$dest"
        fi
        
        cmd="$cmd -e '$ssh_cmd'"
    fi
    
    cmd="$cmd '$source' '$dest'"
    
    echo "$cmd"
}

# 同步文件
sync_files() {
    local source="$1"
    local dest="$2"
    local remote_host="$3"
    local remote_user="$4"
    local remote_port="$5"
    local ssh_key="$6"
    local exclude_patterns="$7"
    local include_patterns="$8"
    local archive_mode="$9"
    local dry_run="$10"
    
    if [ -z "$source" ] || [ -z "$dest" ]; then
        echo "${RED}错误: 请指定源路径和目标路径${NC}"
        return 1
    fi
    
    if [ ! -e "$source" ]; then
        echo "${RED}错误: 源路径不存在: $source${NC}"
        return 1
    fi
    
    log_message "开始同步文件: $source -> $dest"
    
    # 构建rsync命令
    local rsync_cmd=$(build_rsync_command "$source" "$dest" "$remote_host" "$remote_user" "$remote_port" "$ssh_key" "$exclude_patterns" "$include_patterns" "$archive_mode" "$dry_run")
    
    log_message "执行命令: $rsync_cmd"
    
    # 执行同步
    local start_time=$(date +%s)
    local result=$(eval "$rsync_cmd" 2>&1)
    local end_time=$(date +%s)
    local sync_time=$((end_time - start_time))
    
    if [ $? -eq 0 ]; then
        output "${GREEN}文件同步成功${NC}"
        output "同步耗时: ${sync_time}秒"
        
        # 解析同步结果
        if [ "$VERBOSE" = true ]; then
            echo "$result"
        fi
        
        return 0
    else
        output "${RED}文件同步失败${NC}"
        output "错误信息: $result"
        return 1
    fi
}

# 检查文件冲突
check_conflicts() {
    local source="$1"
    local dest="$2"
    local remote_host="$3"
    local remote_user="$4"
    local remote_port="$5"
    local ssh_key="$6"
    
    log_message "检查文件冲突"
    
    # 构建比较命令
    local compare_cmd="rsync -av --dry-run"
    
    if [ -n "$remote_host" ]; then
        local ssh_cmd="ssh"
        
        if [ -n "$remote_port" ]; then
            ssh_cmd="$ssh_cmd -p $remote_port"
        fi
        
        if [ -n "$ssh_key" ]; then
            ssh_cmd="$ssh_cmd -i $ssh_key"
        fi
        
        if [ -n "$remote_user" ]; then
            dest="$remote_user@$remote_host:$dest"
        else
            dest="$remote_host:$dest"
        fi
        
        compare_cmd="$compare_cmd -e '$ssh_cmd'"
    fi
    
    compare_cmd="$compare_cmd '$source' '$dest'"
    
    # 执行比较
    local conflicts=$(eval "$compare_cmd" 2>/dev/null | grep -E "^\*" | wc -l)
    
    if [ "$conflicts" -gt 0 ]; then
        output "${YELLOW}发现 $conflicts 个文件冲突${NC}"
        return 1
    else
        output "${GREEN}未发现文件冲突${NC}"
        return 0
    fi
}

# 生成同步报告
generate_sync_report() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    output ""
    output "=== 文件同步报告 ==="
    output "结束时间: $end_time"
    output "源路径: $SOURCE_PATH"
    output "目标路径: $DEST_PATH"
    
    if [ -n "$REMOTE_HOST" ]; then
        output "远程主机: $REMOTE_HOST"
    fi
    
    output "总文件数: $TOTAL_FILES"
    output "同步文件数: $SYNCED_FILES"
    output "跳过文件数: $SKIPPED_FILES"
    output "错误文件数: $ERROR_FILES"
    
    if [ "$TOTAL_FILES" -gt 0 ]; then
        local success_rate=$(echo "scale=2; $SYNCED_FILES * 100 / $TOTAL_FILES" | bc -l 2>/dev/null || echo "0")
        output "成功率: ${success_rate}%"
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -s|--source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        -d|--dest)
            DEST_PATH="$2"
            shift 2
            ;;
        -r|--remote)
            REMOTE_HOST="$2"
            shift 2
            ;;
        -u|--user)
            REMOTE_USER="$2"
            shift 2
            ;;
        -p|--port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        -k|--key)
            SSH_KEY="$2"
            shift 2
            ;;
        -e|--exclude)
            EXCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        -i|--include)
            INCLUDE_PATTERNS+=("$2")
            shift 2
            ;;
        -a|--archive)
            ARCHIVE_MODE=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$SOURCE_PATH" ]; then
                SOURCE_PATH="$1"
            elif [ -z "$DEST_PATH" ]; then
                DEST_PATH="$1"
            fi
            shift
            ;;
    esac
done

# 检查参数
if [ -z "$SOURCE_PATH" ] || [ -z "$DEST_PATH" ]; then
    echo "错误: 请指定源路径和目标路径"
    show_help
    exit 1
fi

# 检查依赖
check_dependencies

# 检查文件冲突
if [ "$DRY_RUN" = false ]; then
    check_conflicts "$SOURCE_PATH" "$DEST_PATH" "$REMOTE_HOST" "$REMOTE_USER" "$REMOTE_PORT" "$SSH_KEY"
fi

# 执行同步
sync_files "$SOURCE_PATH" "$DEST_PATH" "$REMOTE_HOST" "$REMOTE_USER" "$REMOTE_PORT" "$SSH_KEY" "${EXCLUDE_PATTERNS[@]}" "${INCLUDE_PATTERNS[@]}" "$ARCHIVE_MODE" "$DRY_RUN"

# 生成报告
generate_sync_report

if [ "$DRY_RUN" = true ]; then
    echo "${GREEN}试运行完成${NC}"
else
    echo "${GREEN}文件同步完成${NC}"
fi
