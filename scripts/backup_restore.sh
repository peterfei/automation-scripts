#!/bin/bash

# =============================================================================
# 备份恢复脚本
# Backup and Restore Script
# =============================================================================
# 
# 用途/Use Case:
# - 创建文件和目录的备份
# - 恢复备份文件
# - 管理备份版本
# - 自动清理旧备份
# 
# 使用方法/Usage:
# ./backup_restore.sh [command] [options] [source] [destination]
# 
# 命令/Commands:
# backup                  创建备份
# restore                 恢复备份
# list                    列出备份
# delete                  删除备份
# verify                  验证备份
# 
# 选项/Options:
# -s, --source PATH       源路径
# -d, --dest PATH         目标路径
# -n, --name NAME         备份名称
# -c, --compress          压缩备份
# -e, --encrypt           加密备份
# -k, --key FILE          加密密钥文件
# -r, --retention DAYS    保留天数
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./backup_restore.sh backup --source /home/user --dest /backup
# ./backup_restore.sh restore --source /backup/user_20240101.tar.gz --dest /home/user
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
SOURCE_PATH=""
DEST_PATH=""
BACKUP_NAME=""
COMPRESS=false
ENCRYPT=false
ENCRYPT_KEY=""
RETENTION_DAYS=30
VERBOSE=false

# 统计变量
BACKUP_SIZE=0
BACKUP_TIME=0
FILES_COUNT=0

# 显示帮助信息
show_help() {
    echo "备份恢复脚本 / Backup and Restore Script"
    echo ""
    echo "用法 / Usage: $0 [命令 / command] [选项 / options] [源路径 / source] [目标路径 / destination]"
    echo ""
    echo "命令 / Commands:"
    echo "  backup                  创建备份"
    echo "  restore                 恢复备份"
    echo "  list                    列出备份"
    echo "  delete                  删除备份"
    echo "  verify                  验证备份"
    echo ""
    echo "选项 / Options:"
    echo "  -s, --source PATH       源路径"
    echo "  -d, --dest PATH         目标路径"
    echo "  -n, --name NAME         备份名称"
    echo "  -c, --compress          压缩备份"
    echo "  -e, --encrypt           加密备份"
    echo "  -k, --key FILE          加密密钥文件"
    echo "  -r, --retention DAYS    保留天数"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 backup --source /home/user --dest /backup"
    echo "  $0 restore --source /backup/user_20240101.tar.gz --dest /home/user"
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
    
    if [ "$COMPRESS" = true ] && ! command -v tar &> /dev/null; then
        missing_deps+=("tar")
    fi
    
    if [ "$ENCRYPT" = true ] && ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "${RED}错误: 缺少必要的命令: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# 生成备份文件名
generate_backup_filename() {
    local source_path="$1"
    local backup_name="$2"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local basename=$(basename "$source_path")
    
    if [ -n "$backup_name" ]; then
        basename="$backup_name"
    fi
    
    local filename="${basename}_${timestamp}"
    
    if [ "$COMPRESS" = true ]; then
        filename="${filename}.tar.gz"
    else
        filename="${filename}.tar"
    fi
    
    if [ "$ENCRYPT" = true ]; then
        filename="${filename}.enc"
    fi
    
    echo "$filename"
}

# 创建备份
create_backup() {
    local source_path="$1"
    local dest_path="$2"
    local backup_name="$3"
    
    if [ -z "$source_path" ] || [ -z "$dest_path" ]; then
        echo "${RED}错误: 请指定源路径和目标路径${NC}"
        return 1
    fi
    
    if [ ! -e "$source_path" ]; then
        echo "${RED}错误: 源路径不存在: $source_path${NC}"
        return 1
    fi
    
    # 创建目标目录
    mkdir -p "$dest_path"
    
    # 生成备份文件名
    local backup_file=$(generate_backup_filename "$source_path" "$backup_name")
    local backup_path="$dest_path/$backup_file"
    
    log_message "开始创建备份: $source_path -> $backup_path"
    
    local start_time=$(date +%s)
    
    # 创建备份
    if [ "$COMPRESS" = true ]; then
        if [ "$ENCRYPT" = true ]; then
            # 压缩并加密
            if [ -n "$ENCRYPT_KEY" ]; then
                tar -czf - -C "$(dirname "$source_path")" "$(basename "$source_path")" | \
                openssl enc -aes-256-cbc -salt -out "$backup_path" -pass file:"$ENCRYPT_KEY"
            else
                tar -czf - -C "$(dirname "$source_path")" "$(basename "$source_path")" | \
                openssl enc -aes-256-cbc -salt -out "$backup_path" -pass pass:"backup"
            fi
        else
            # 只压缩
            tar -czf "$backup_path" -C "$(dirname "$source_path")" "$(basename "$source_path")"
        fi
    else
        if [ "$ENCRYPT" = true ]; then
            # 只加密
            if [ -n "$ENCRYPT_KEY" ]; then
                tar -cf - -C "$(dirname "$source_path")" "$(basename "$source_path")" | \
                openssl enc -aes-256-cbc -salt -out "$backup_path" -pass file:"$ENCRYPT_KEY"
            else
                tar -cf - -C "$(dirname "$source_path")" "$(basename "$source_path")" | \
                openssl enc -aes-256-cbc -salt -out "$backup_path" -pass pass:"backup"
            fi
        else
            # 直接备份
            tar -cf "$backup_path" -C "$(dirname "$source_path")" "$(basename "$source_path")"
        fi
    fi
    
    local result=$?
    local end_time=$(date +%s)
    BACKUP_TIME=$((end_time - start_time))
    
    if [ $result -eq 0 ]; then
        BACKUP_SIZE=$(du -h "$backup_path" | cut -f1)
        FILES_COUNT=$(tar -tf "$backup_path" 2>/dev/null | wc -l)
        
        log_message "备份创建成功: $backup_path"
        log_message "备份大小: $BACKUP_SIZE"
        log_message "文件数量: $FILES_COUNT"
        log_message "备份耗时: ${BACKUP_TIME}秒"
        
        # 创建备份信息文件
        local info_file="${backup_path}.info"
        cat > "$info_file" << EOF
备份信息 / Backup Information
============================
源路径: $source_path
目标路径: $backup_path
备份时间: $(date)
备份大小: $BACKUP_SIZE
文件数量: $FILES_COUNT
备份耗时: ${BACKUP_TIME}秒
压缩: $COMPRESS
加密: $ENCRYPT
EOF
        
        output "${GREEN}备份创建成功: $backup_path${NC}"
        return 0
    else
        log_message "备份创建失败"
        output "${RED}备份创建失败${NC}"
        return 1
    fi
}

# 恢复备份
restore_backup() {
    local backup_path="$1"
    local dest_path="$2"
    
    if [ -z "$backup_path" ] || [ -z "$dest_path" ]; then
        echo "${RED}错误: 请指定备份文件路径和目标路径${NC}"
        return 1
    fi
    
    if [ ! -f "$backup_path" ]; then
        echo "${RED}错误: 备份文件不存在: $backup_path${NC}"
        return 1
    fi
    
    # 创建目标目录
    mkdir -p "$dest_path"
    
    log_message "开始恢复备份: $backup_path -> $dest_path"
    
    local start_time=$(date +%s)
    
    # 恢复备份
    if [ "$ENCRYPT" = true ]; then
        # 解密并解压
        if [ -n "$ENCRYPT_KEY" ]; then
            openssl enc -aes-256-cbc -d -in "$backup_path" -pass file:"$ENCRYPT_KEY" | \
            tar -xzf - -C "$dest_path"
        else
            openssl enc -aes-256-cbc -d -in "$backup_path" -pass pass:"backup" | \
            tar -xzf - -C "$dest_path"
        fi
    else
        # 直接解压
        tar -xzf "$backup_path" -C "$dest_path"
    fi
    
    local result=$?
    local end_time=$(date +%s)
    local restore_time=$((end_time - start_time))
    
    if [ $result -eq 0 ]; then
        log_message "备份恢复成功"
        log_message "恢复耗时: ${restore_time}秒"
        output "${GREEN}备份恢复成功: $dest_path${NC}"
        return 0
    else
        log_message "备份恢复失败"
        output "${RED}备份恢复失败${NC}"
        return 1
    fi
}

# 列出备份
list_backups() {
    local dest_path="$1"
    
    if [ -z "$dest_path" ]; then
        echo "${RED}错误: 请指定备份目录${NC}"
        return 1
    fi
    
    if [ ! -d "$dest_path" ]; then
        echo "${RED}错误: 备份目录不存在: $dest_path${NC}"
        return 1
    fi
    
    output "${BLUE}备份列表 / Backup List${NC}"
    output "目录: $dest_path"
    output ""
    
    # 列出备份文件
    find "$dest_path" -name "*.tar*" -type f | sort | while read backup_file; do
        local basename=$(basename "$backup_file")
        local size=$(du -h "$backup_file" | cut -f1)
        local date=$(stat -c "%y" "$backup_file" 2>/dev/null || stat -f "%Sm" "$backup_file" 2>/dev/null)
        
        output "文件: $basename"
        output "大小: $size"
        output "日期: $date"
        output ""
    done
}

# 删除备份
delete_backup() {
    local backup_path="$1"
    
    if [ -z "$backup_path" ]; then
        echo "${RED}错误: 请指定备份文件路径${NC}"
        return 1
    fi
    
    if [ ! -f "$backup_path" ]; then
        echo "${RED}错误: 备份文件不存在: $backup_path${NC}"
        return 1
    fi
    
    log_message "删除备份: $backup_path"
    
    if rm -f "$backup_path"; then
        # 删除信息文件
        rm -f "${backup_path}.info"
        output "${GREEN}备份删除成功: $backup_path${NC}"
        return 0
    else
        output "${RED}备份删除失败${NC}"
        return 1
    fi
}

# 验证备份
verify_backup() {
    local backup_path="$1"
    
    if [ -z "$backup_path" ]; then
        echo "${RED}错误: 请指定备份文件路径${NC}"
        return 1
    fi
    
    if [ ! -f "$backup_path" ]; then
        echo "${RED}错误: 备份文件不存在: $backup_path${NC}"
        return 1
    fi
    
    output "${BLUE}验证备份: $backup_path${NC}"
    
    # 验证备份文件
    if [ "$ENCRYPT" = true ]; then
        # 验证加密文件
        if [ -n "$ENCRYPT_KEY" ]; then
            openssl enc -aes-256-cbc -d -in "$backup_path" -pass file:"$ENCRYPT_KEY" | tar -tzf - > /dev/null
        else
            openssl enc -aes-256-cbc -d -in "$backup_path" -pass pass:"backup" | tar -tzf - > /dev/null
        fi
    else
        # 验证普通文件
        tar -tzf "$backup_path" > /dev/null
    fi
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        output "${GREEN}备份验证成功${NC}"
        return 0
    else
        output "${RED}备份验证失败${NC}"
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    local dest_path="$1"
    
    if [ -z "$dest_path" ]; then
        return 0
    fi
    
    if [ ! -d "$dest_path" ]; then
        return 0
    fi
    
    if [ "$RETENTION_DAYS" -le 0 ]; then
        return 0
    fi
    
    log_message "清理 $RETENTION_DAYS 天前的备份文件"
    
    local deleted_count=0
    while IFS= read -r -d '' file; do
        rm -f "$file"
        rm -f "${file}.info"
        deleted_count=$((deleted_count + 1))
        log_message "删除旧备份文件: $(basename "$file")"
    done < <(find "$dest_path" -name "*.tar*" -type f -mtime +$RETENTION_DAYS -print0)
    
    log_message "清理完成，删除了 $deleted_count 个文件"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        backup|restore|list|delete|verify)
            COMMAND="$1"
            shift
            break
            ;;
        -s|--source)
            SOURCE_PATH="$2"
            shift 2
            ;;
        -d|--dest)
            DEST_PATH="$2"
            shift 2
            ;;
        -n|--name)
            BACKUP_NAME="$2"
            shift 2
            ;;
        -c|--compress)
            COMPRESS=true
            shift
            ;;
        -e|--encrypt)
            ENCRYPT=true
            shift
            ;;
        -k|--key)
            ENCRYPT_KEY="$2"
            shift 2
            ;;
        -r|--retention)
            RETENTION_DAYS="$2"
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

# 检查依赖
check_dependencies

# 执行命令
case $COMMAND in
    backup)
        create_backup "$SOURCE_PATH" "$DEST_PATH" "$BACKUP_NAME"
        if [ $? -eq 0 ]; then
            cleanup_old_backups "$DEST_PATH"
        fi
        ;;
    restore)
        restore_backup "$SOURCE_PATH" "$DEST_PATH"
        ;;
    list)
        list_backups "$DEST_PATH"
        ;;
    delete)
        delete_backup "$SOURCE_PATH"
        ;;
    verify)
        verify_backup "$SOURCE_PATH"
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
