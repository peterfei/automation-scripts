#!/bin/bash

# =============================================================================
# 数据库备份脚本
# Database Backup Script
# =============================================================================
# 
# 用途/Use Case:
# - 自动备份MySQL/PostgreSQL数据库
# - 压缩和加密备份文件
# - 清理旧备份文件
# - 发送备份状态通知
# 
# 使用方法/Usage:
# ./database_backup.sh [options]
# 
# 选项/Options:
# -t, --type TYPE         数据库类型 (mysql|postgresql)
# -h, --host HOST         数据库主机
# -u, --user USER         数据库用户
# -p, --password PASS     数据库密码
# -d, --database DB       数据库名称
# -o, --output DIR        输出目录
# -c, --compress          压缩备份文件
# -e, --encrypt           加密备份文件
# -k, --key FILE          加密密钥文件
# -r, --retention DAYS    保留天数
# -m, --email EMAIL       发送邮件通知
# -l, --log FILE          日志文件
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./database_backup.sh --type mysql --host localhost --user root --database mydb
# ./database_backup.sh --type postgresql --compress --encrypt --retention 30
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
DB_TYPE=""
DB_HOST="localhost"
DB_USER=""
DB_PASSWORD=""
DB_NAME=""
OUTPUT_DIR="./backups"
COMPRESS=false
ENCRYPT=false
ENCRYPT_KEY=""
RETENTION_DAYS=30
EMAIL=""
LOG_FILE=""
VERBOSE=false

# 统计变量
BACKUP_SIZE=0
BACKUP_TIME=0
SUCCESS_COUNT=0
FAILED_COUNT=0

# 显示帮助信息
show_help() {
    echo "数据库备份脚本 / Database Backup Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -t, --type TYPE         数据库类型 (mysql|postgresql)"
    echo "  -h, --host HOST         数据库主机"
    echo "  -u, --user USER         数据库用户"
    echo "  -p, --password PASS     数据库密码"
    echo "  -d, --database DB       数据库名称"
    echo "  -o, --output DIR        输出目录"
    echo "  -c, --compress          压缩备份文件"
    echo "  -e, --encrypt           加密备份文件"
    echo "  -k, --key FILE          加密密钥文件"
    echo "  -r, --retention DAYS    保留天数"
    echo "  -m, --email EMAIL       发送邮件通知"
    echo "  -l, --log FILE          日志文件"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --type mysql --host localhost --user root --database mydb"
    echo "  $0 --type postgresql --compress --encrypt --retention 30"
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
    if [ -n "$LOG_FILE" ]; then
        echo "$1" >> "$LOG_FILE"
    else
        echo "$1"
    fi
}

# 检查必要的命令
check_dependencies() {
    local missing_deps=()
    
    case "$DB_TYPE" in
        mysql)
            if ! command -v mysqldump &> /dev/null; then
                missing_deps+=("mysqldump")
            fi
            ;;
        postgresql)
            if ! command -v pg_dump &> /dev/null; then
                missing_deps+=("pg_dump")
            fi
            ;;
    esac
    
    if [ "$COMPRESS" = true ] && ! command -v gzip &> /dev/null; then
        missing_deps+=("gzip")
    fi
    
    if [ "$ENCRYPT" = true ] && ! command -v openssl &> /dev/null; then
        missing_deps+=("openssl")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "${RED}错误: 缺少必要的命令: ${missing_deps[*]}${NC}"
        exit 1
    fi
}

# 创建输出目录
create_output_dir() {
    if [ ! -d "$OUTPUT_DIR" ]; then
        mkdir -p "$OUTPUT_DIR"
        log_message "创建输出目录: $OUTPUT_DIR"
    fi
}

# 生成备份文件名
generate_backup_filename() {
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local filename="${DB_NAME}_${timestamp}"
    
    if [ "$COMPRESS" = true ]; then
        filename="${filename}.sql.gz"
    else
        filename="${filename}.sql"
    fi
    
    if [ "$ENCRYPT" = true ]; then
        filename="${filename}.enc"
    fi
    
    echo "$filename"
}

# 备份MySQL数据库
backup_mysql() {
    local backup_file="$1"
    local start_time=$(date +%s)
    
    log_message "开始备份MySQL数据库: $DB_NAME"
    
    # 构建mysqldump命令
    local dump_cmd="mysqldump -h $DB_HOST -u $DB_USER"
    
    if [ -n "$DB_PASSWORD" ]; then
        dump_cmd="$dump_cmd -p$DB_PASSWORD"
    fi
    
    dump_cmd="$dump_cmd $DB_NAME"
    
    # 执行备份
    if [ "$COMPRESS" = true ]; then
        if [ "$ENCRYPT" = true ]; then
            # 压缩并加密
            if [ -n "$ENCRYPT_KEY" ]; then
                $dump_cmd | gzip | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass file:"$ENCRYPT_KEY"
            else
                $dump_cmd | gzip | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass pass:"$DB_PASSWORD"
            fi
        else
            # 只压缩
            $dump_cmd | gzip > "$backup_file"
        fi
    else
        if [ "$ENCRYPT" = true ]; then
            # 只加密
            if [ -n "$ENCRYPT_KEY" ]; then
                $dump_cmd | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass file:"$ENCRYPT_KEY"
            else
                $dump_cmd | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass pass:"$DB_PASSWORD"
            fi
        else
            # 直接备份
            $dump_cmd > "$backup_file"
        fi
    fi
    
    local result=$?
    local end_time=$(date +%s)
    BACKUP_TIME=$((end_time - start_time))
    
    if [ $result -eq 0 ]; then
        BACKUP_SIZE=$(du -h "$backup_file" | cut -f1)
        log_message "MySQL数据库备份成功: $backup_file (大小: $BACKUP_SIZE, 耗时: ${BACKUP_TIME}秒)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    else
        log_message "MySQL数据库备份失败: $DB_NAME"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# 备份PostgreSQL数据库
backup_postgresql() {
    local backup_file="$1"
    local start_time=$(date +%s)
    
    log_message "开始备份PostgreSQL数据库: $DB_NAME"
    
    # 设置环境变量
    export PGPASSWORD="$DB_PASSWORD"
    
    # 构建pg_dump命令
    local dump_cmd="pg_dump -h $DB_HOST -U $DB_USER -d $DB_NAME"
    
    # 执行备份
    if [ "$COMPRESS" = true ]; then
        if [ "$ENCRYPT" = true ]; then
            # 压缩并加密
            if [ -n "$ENCRYPT_KEY" ]; then
                $dump_cmd | gzip | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass file:"$ENCRYPT_KEY"
            else
                $dump_cmd | gzip | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass pass:"$DB_PASSWORD"
            fi
        else
            # 只压缩
            $dump_cmd | gzip > "$backup_file"
        fi
    else
        if [ "$ENCRYPT" = true ]; then
            # 只加密
            if [ -n "$ENCRYPT_KEY" ]; then
                $dump_cmd | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass file:"$ENCRYPT_KEY"
            else
                $dump_cmd | openssl enc -aes-256-cbc -salt -in - -out "$backup_file" -pass pass:"$DB_PASSWORD"
            fi
        else
            # 直接备份
            $dump_cmd > "$backup_file"
        fi
    fi
    
    local result=$?
    local end_time=$(date +%s)
    BACKUP_TIME=$((end_time - start_time))
    
    # 清除环境变量
    unset PGPASSWORD
    
    if [ $result -eq 0 ]; then
        BACKUP_SIZE=$(du -h "$backup_file" | cut -f1)
        log_message "PostgreSQL数据库备份成功: $backup_file (大小: $BACKUP_SIZE, 耗时: ${BACKUP_TIME}秒)"
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        return 0
    else
        log_message "PostgreSQL数据库备份失败: $DB_NAME"
        FAILED_COUNT=$((FAILED_COUNT + 1))
        return 1
    fi
}

# 清理旧备份
cleanup_old_backups() {
    if [ "$RETENTION_DAYS" -le 0 ]; then
        return 0
    fi
    
    log_message "清理 $RETENTION_DAYS 天前的备份文件"
    
    local deleted_count=0
    while IFS= read -r -d '' file; do
        rm -f "$file"
        deleted_count=$((deleted_count + 1))
        log_message "删除旧备份文件: $(basename "$file")"
    done < <(find "$OUTPUT_DIR" -name "${DB_NAME}_*.sql*" -type f -mtime +$RETENTION_DAYS -print0)
    
    log_message "清理完成，删除了 $deleted_count 个文件"
}

# 发送邮件通知
send_email_notification() {
    local subject="$1"
    local body="$2"
    
    if [ -z "$EMAIL" ]; then
        return 0
    fi
    
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$EMAIL"
    elif command -v sendmail &> /dev/null; then
        echo "$body" | sendmail "$EMAIL"
    else
        log_message "警告: 未找到邮件发送工具"
    fi
}

# 生成备份报告
generate_backup_report() {
    local backup_file="$1"
    local success="$2"
    
    local report=""
    report+="数据库备份报告\n"
    report+="================\n"
    report+="时间: $(date)\n"
    report+="数据库类型: $DB_TYPE\n"
    report+="数据库名称: $DB_NAME\n"
    report+="数据库主机: $DB_HOST\n"
    report+="备份文件: $backup_file\n"
    report+="文件大小: $BACKUP_SIZE\n"
    report+="备份耗时: ${BACKUP_TIME}秒\n"
    report+="状态: "
    
    if [ "$success" = true ]; then
        report+="成功\n"
    else
        report+="失败\n"
    fi
    
    report+="\n统计信息:\n"
    report+="成功备份: $SUCCESS_COUNT\n"
    report+="失败备份: $FAILED_COUNT\n"
    
    output "$report"
    
    # 发送邮件通知
    local subject="数据库备份通知 - $DB_NAME"
    if [ "$success" = true ]; then
        subject="[成功] $subject"
    else
        subject="[失败] $subject"
    fi
    
    send_email_notification "$subject" "$report"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--type)
            DB_TYPE="$2"
            shift 2
            ;;
        -h|--host)
            DB_HOST="$2"
            shift 2
            ;;
        -u|--user)
            DB_USER="$2"
            shift 2
            ;;
        -p|--password)
            DB_PASSWORD="$2"
            shift 2
            ;;
        -d|--database)
            DB_NAME="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_DIR="$2"
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
        -m|--email)
            EMAIL="$2"
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
        --help)
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

# 检查必需参数
if [ -z "$DB_TYPE" ]; then
    echo "错误: 请指定数据库类型"
    show_help
    exit 1
fi

if [ -z "$DB_USER" ]; then
    echo "错误: 请指定数据库用户"
    exit 1
fi

if [ -z "$DB_NAME" ]; then
    echo "错误: 请指定数据库名称"
    exit 1
fi

# 验证数据库类型
if [ "$DB_TYPE" != "mysql" ] && [ "$DB_TYPE" != "postgresql" ]; then
    echo "错误: 不支持的数据库类型: $DB_TYPE"
    exit 1
fi

# 检查依赖
check_dependencies

# 创建输出目录
create_output_dir

# 生成备份文件名
BACKUP_FILE=$(generate_backup_filename)
BACKUP_PATH="$OUTPUT_DIR/$BACKUP_FILE"

# 执行备份
log_message "开始数据库备份流程"
case "$DB_TYPE" in
    mysql)
        backup_mysql "$BACKUP_PATH"
        ;;
    postgresql)
        backup_postgresql "$BACKUP_PATH"
        ;;
esac

BACKUP_SUCCESS=$?

# 清理旧备份
cleanup_old_backups

# 生成报告
generate_backup_report "$BACKUP_FILE" $([ $BACKUP_SUCCESS -eq 0 ] && echo true || echo false)

if [ $BACKUP_SUCCESS -eq 0 ]; then
    echo "${GREEN}数据库备份完成: $BACKUP_PATH${NC}"
    exit 0
else
    echo "${RED}数据库备份失败${NC}"
    exit 1
fi
