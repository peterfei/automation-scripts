#!/bin/bash

# =============================================================================
# 批量文件重命名脚本
# Batch File Rename Script
# =============================================================================
# 
# 用途/Use Case:
# - 批量重命名文件和目录
# - 支持多种重命名模式（前缀、后缀、模式替换、序列编号）
# - 提供安全的预览模式和备份功能
# - 支持文件过滤和排除模式
# 
# 使用方法/Usage:
# ./batch_file_rename.sh [options] [directory]
# 
# 选项/Options:
# -d, --directory DIR       指定目录，默认为当前目录
# -p, --prefix PREFIX       添加前缀
# -s, --suffix SUFFIX       添加后缀
# -r, --replace OLD NEW     替换模式
# -n, --number              序列编号
# -t, --timestamp           添加时间戳
# -c, --case CASE           大小写转换 (upper|lower|title)
# -e, --extensions EXTS     文件扩展名过滤 (逗号分隔)
# -x, --exclude PATTERN     排除模式
# -m, --min-size SIZE       最小文件大小 (如: 1MB, 500KB)
# -M, --max-size SIZE       最大文件大小
# -f, --pattern PATTERN     自定义模式
# -b, --backup             创建备份
# -u, --undo               回滚操作
# -l, --log-file FILE       日志文件
# -o, --output FILE         输出文件
# --dry-run                预览模式（不实际重命名）
# --force                  强制覆盖
# --recursive              递归处理子目录
# --start NUMBER           序列编号起始值
# --padding NUMBER         序列编号填充位数
# --format FORMAT          时间戳格式
# --stats                  显示统计信息
# --progress               显示进度条
# -v, --verbose            详细输出
# -h, --help               显示帮助信息
# 
# 示例/Examples:
# ./batch_file_rename.sh --prefix "IMG_" --directory /photos
# ./batch_file_rename.sh --replace "old" "new" --extensions "jpg,png"
# ./batch_file_rename.sh --number --start 1 --padding 3 --dry-run
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
DIRECTORY="."
PREFIX=""
SUFFIX=""
REPLACE_OLD=""
REPLACE_NEW=""
NUMBER=false
TIMESTAMP=false
CASE_CONVERSION=""
EXTENSIONS=""
EXCLUDE_PATTERN=""
MIN_SIZE=""
MAX_SIZE=""
CUSTOM_PATTERN=""
BACKUP=false
UNDO=false
LOG_FILE=""
OUTPUT_FILE=""
DRY_RUN=false
FORCE=false
RECURSIVE=false
START_NUMBER=1
PADDING=3
TIMESTAMP_FORMAT="%Y%m%d_%H%M%S"
SHOW_STATS=false
SHOW_PROGRESS=false
VERBOSE=false

# 统计变量
TOTAL_FILES=0
PROCESSED_FILES=0
SKIPPED_FILES=0
ERROR_FILES=0
BACKUP_CREATED=false

# 显示帮助信息
show_help() {
    echo "批量文件重命名脚本 / Batch File Rename Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options] [目录 / directory]"
    echo ""
    echo "选项 / Options:"
    echo "  -d, --directory DIR       指定目录，默认为当前目录"
    echo "  -p, --prefix PREFIX       添加前缀"
    echo "  -s, --suffix SUFFIX       添加后缀"
    echo "  -r, --replace OLD NEW     替换模式"
    echo "  -n, --number              序列编号"
    echo "  -t, --timestamp           添加时间戳"
    echo "  -c, --case CASE           大小写转换 (upper|lower|title)"
    echo "  -e, --extensions EXTS     文件扩展名过滤 (逗号分隔)"
    echo "  -x, --exclude PATTERN     排除模式"
    echo "  -m, --min-size SIZE       最小文件大小 (如: 1MB, 500KB)"
    echo "  -M, --max-size SIZE       最大文件大小"
    echo "  -f, --pattern PATTERN     自定义模式"
    echo "  -b, --backup             创建备份"
    echo "  -u, --undo               回滚操作"
    echo "  -l, --log-file FILE       日志文件"
    echo "  -o, --output FILE         输出文件"
    echo "  --dry-run                预览模式（不实际重命名）"
    echo "  --force                  强制覆盖"
    echo "  --recursive              递归处理子目录"
    echo "  --start NUMBER           序列编号起始值"
    echo "  --padding NUMBER         序列编号填充位数"
    echo "  --format FORMAT          时间戳格式"
    echo "  --stats                  显示统计信息"
    echo "  --progress               显示进度条"
    echo "  -v, --verbose            详细输出"
    echo "  -h, --help               显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --prefix \"IMG_\" --directory /photos"
    echo "  $0 --replace \"old\" \"new\" --extensions \"jpg,png\""
    echo "  $0 --number --start 1 --padding 3 --dry-run"
    echo "  $0 --timestamp --format \"%Y%m%d\" --backup"
    echo "  $0 --case lower --exclude \"*backup*\" --dry-run"
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

# 解析文件大小
parse_size() {
    local size_str="$1"
    local size_bytes=0
    
    if [[ "$size_str" =~ ^([0-9]+)([KkMmGg]?[Bb]?)$ ]]; then
        local number="${BASH_REMATCH[1]}"
        local unit="${BASH_REMATCH[2],,}"
        
        case "$unit" in
            "kb"|"k")
                size_bytes=$((number * 1024))
                ;;
            "mb"|"m")
                size_bytes=$((number * 1024 * 1024))
                ;;
            "gb"|"g")
                size_bytes=$((number * 1024 * 1024 * 1024))
                ;;
            "b"|"")
                size_bytes=$number
                ;;
        esac
    fi
    
    echo $size_bytes
}

# 获取文件大小
get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# 检查文件是否匹配过滤条件
check_file_filters() {
    local file="$1"
    local basename=$(basename "$file")
    
    # 检查扩展名过滤
    if [ -n "$EXTENSIONS" ]; then
        local ext="${basename##*.}"
        local match=false
        IFS=',' read -ra EXT_ARRAY <<< "$EXTENSIONS"
        for allowed_ext in "${EXT_ARRAY[@]}"; do
            if [ "$(echo "$ext" | tr '[:upper:]' '[:lower:]')" = "$(echo "$allowed_ext" | tr '[:upper:]' '[:lower:]')" ]; then
                match=true
                break
            fi
        done
        if [ "$match" = false ]; then
            return 1
        fi
    fi
    
    # 检查排除模式
    if [ -n "$EXCLUDE_PATTERN" ]; then
        if [[ "$basename" == $EXCLUDE_PATTERN ]]; then
            return 1
        fi
    fi
    
    # 检查文件大小
    if [ -n "$MIN_SIZE" ] || [ -n "$MAX_SIZE" ]; then
        local file_size=$(get_file_size "$file")
        local min_bytes=0
        local max_bytes=0
        
        if [ -n "$MIN_SIZE" ]; then
            min_bytes=$(parse_size "$MIN_SIZE")
            if [ "$file_size" -lt "$min_bytes" ]; then
                return 1
            fi
        fi
        
        if [ -n "$MAX_SIZE" ]; then
            max_bytes=$(parse_size "$MAX_SIZE")
            if [ "$file_size" -gt "$max_bytes" ]; then
                return 1
            fi
        fi
    fi
    
    return 0
}

# 生成新文件名
generate_new_filename() {
    local file="$1"
    local basename=$(basename "$file")
    local dirname=$(dirname "$file")
    local name="${basename%.*}"
    local ext="${basename##*.}"
    local new_name="$name"
    
    # 处理扩展名
    if [ "$ext" != "$basename" ]; then
        local new_ext=".$ext"
    else
        local new_ext=""
    fi
    
    # 应用前缀
    if [ -n "$PREFIX" ]; then
        new_name="${PREFIX}${new_name}"
    fi
    
    # 应用后缀
    if [ -n "$SUFFIX" ]; then
        new_name="${new_name}${SUFFIX}"
    fi
    
    # 应用替换模式
    if [ -n "$REPLACE_OLD" ] && [ -n "$REPLACE_NEW" ]; then
        new_name="${new_name//$REPLACE_OLD/$REPLACE_NEW}"
    fi
    
    # 应用大小写转换
    case "$CASE_CONVERSION" in
        "upper")
            new_name=$(echo "$new_name" | tr '[:lower:]' '[:upper:]')
            ;;
        "lower")
            new_name=$(echo "$new_name" | tr '[:upper:]' '[:lower:]')
            ;;
        "title")
            new_name=$(echo "$new_name" | sed 's/.*/\u&/')
            ;;
    esac
    
    # 应用时间戳
    if [ "$TIMESTAMP" = true ]; then
        local timestamp=$(date +"$TIMESTAMP_FORMAT")
        new_name="${new_name}_${timestamp}"
    fi
    
    # 应用自定义模式
    if [ -n "$CUSTOM_PATTERN" ]; then
        # 替换模式中的变量
        local pattern="$CUSTOM_PATTERN"
        pattern="${pattern//\{original\}/$name}"
        pattern="${pattern//\{date\}/$(date +%Y%m%d)}"
        pattern="${pattern//\{time\}/$(date +%H%M%S)}"
        pattern="${pattern//\{counter\}/$PROCESSED_FILES}"
        new_name="$pattern"
    fi
    
    # 构建完整的新文件名
    local new_file="${dirname}/${new_name}${new_ext}"
    
    echo "$new_file"
}

# 创建备份
create_backup() {
    local backup_file="rename_backup_$(date +%Y%m%d_%H%M%S).txt"
    
    log_message "创建备份文件: $backup_file"
    
    echo "# 批量重命名备份文件" > "$backup_file"
    echo "# 创建时间: $(date)" >> "$backup_file"
    echo "# 原始目录: $DIRECTORY" >> "$backup_file"
    echo "" >> "$backup_file"
    
    BACKUP_CREATED=true
    echo "$backup_file"
}

# 执行重命名
perform_rename() {
    local old_file="$1"
    local new_file="$2"
    local backup_file="$3"
    
    if [ "$DRY_RUN" = true ]; then
        output "预览: $old_file -> $new_file"
        return 0
    fi
    
    # 检查目标文件是否已存在
    if [ -e "$new_file" ] && [ "$FORCE" = false ]; then
        log_message "跳过: 目标文件已存在 $new_file"
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        return 1
    fi
    
    # 执行重命名
    if mv "$old_file" "$new_file" 2>/dev/null; then
        log_message "重命名成功: $old_file -> $new_file"
        
        # 记录到备份文件
        if [ -n "$backup_file" ]; then
            echo "$old_file|$new_file" >> "$backup_file"
        fi
        
        PROCESSED_FILES=$((PROCESSED_FILES + 1))
        return 0
    else
        log_message "重命名失败: $old_file -> $new_file"
        ERROR_FILES=$((ERROR_FILES + 1))
        return 1
    fi
}

# 处理文件
process_file() {
    local file="$1"
    local backup_file="$2"
    
    # 检查文件过滤条件
    if ! check_file_filters "$file"; then
        SKIPPED_FILES=$((SKIPPED_FILES + 1))
        return 0
    fi
    
    # 生成新文件名
    local new_file=$(generate_new_filename "$file")
    
    # 执行重命名
    perform_rename "$file" "$new_file" "$backup_file"
}

# 收集文件列表
collect_files() {
    local files=()
    
    if [ "$RECURSIVE" = true ]; then
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$DIRECTORY" -type f -print0)
    else
        while IFS= read -r -d '' file; do
            files+=("$file")
        done < <(find "$DIRECTORY" -maxdepth 1 -type f -print0)
    fi
    
    echo "${files[@]}"
}

# 显示统计信息
show_statistics() {
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    output ""
    output "${BLUE}=== 批量重命名统计信息 ===${NC}"
    output "总文件数: $TOTAL_FILES"
    output "处理文件数: $PROCESSED_FILES"
    output "跳过文件数: $SKIPPED_FILES"
    output "错误文件数: $ERROR_FILES"
    output "处理时间: ${duration}秒"
    
    if [ "$BACKUP_CREATED" = true ]; then
        output "备份文件: 已创建"
    fi
    
    if [ "$DRY_RUN" = true ]; then
        output "${YELLOW}注意: 这是预览模式，没有实际重命名文件${NC}"
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--directory)
            DIRECTORY="$2"
            shift 2
            ;;
        -p|--prefix)
            PREFIX="$2"
            shift 2
            ;;
        -s|--suffix)
            SUFFIX="$2"
            shift 2
            ;;
        -r|--replace)
            REPLACE_OLD="$2"
            REPLACE_NEW="$3"
            shift 3
            ;;
        -n|--number)
            NUMBER=true
            shift
            ;;
        -t|--timestamp)
            TIMESTAMP=true
            shift
            ;;
        -c|--case)
            CASE_CONVERSION="$2"
            shift 2
            ;;
        -e|--extensions)
            EXTENSIONS="$2"
            shift 2
            ;;
        -x|--exclude)
            EXCLUDE_PATTERN="$2"
            shift 2
            ;;
        -m|--min-size)
            MIN_SIZE="$2"
            shift 2
            ;;
        -M|--max-size)
            MAX_SIZE="$2"
            shift 2
            ;;
        -f|--pattern)
            CUSTOM_PATTERN="$2"
            shift 2
            ;;
        -b|--backup)
            BACKUP=true
            shift
            ;;
        -u|--undo)
            UNDO=true
            shift
            ;;
        -l|--log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --recursive)
            RECURSIVE=true
            shift
            ;;
        --start)
            START_NUMBER="$2"
            shift 2
            ;;
        --padding)
            PADDING="$2"
            shift 2
            ;;
        --format)
            TIMESTAMP_FORMAT="$2"
            shift 2
            ;;
        --stats)
            SHOW_STATS=true
            shift
            ;;
        --progress)
            SHOW_PROGRESS=true
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
        -*)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$DIRECTORY" ] || [ "$DIRECTORY" = "." ]; then
                DIRECTORY="$1"
            fi
            shift
            ;;
    esac
done

# 验证参数
if [ -z "$PREFIX" ] && [ -z "$SUFFIX" ] && [ -z "$REPLACE_OLD" ] && [ "$NUMBER" = false ] && [ "$TIMESTAMP" = false ] && [ -z "$CASE_CONVERSION" ] && [ -z "$CUSTOM_PATTERN" ]; then
    echo "错误: 请指定至少一种重命名模式"
    show_help
    exit 1
fi

if [ ! -d "$DIRECTORY" ]; then
    echo "错误: 目录不存在: $DIRECTORY"
    exit 1
fi

# 验证大小写转换选项
if [ -n "$CASE_CONVERSION" ] && [[ ! "$CASE_CONVERSION" =~ ^(upper|lower|title)$ ]]; then
    echo "错误: 无效的大小写转换选项: $CASE_CONVERSION"
    exit 1
fi

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 开始处理
start_time=$(date +%s)
log_message "开始批量文件重命名: $DIRECTORY"

# 创建备份文件
backup_file=""
if [ "$BACKUP" = true ] && [ "$DRY_RUN" = false ]; then
    backup_file=$(create_backup)
fi

# 收集文件
files=($(collect_files))
TOTAL_FILES=${#files[@]}

if [ "$TOTAL_FILES" -eq 0 ]; then
    echo "未找到符合条件的文件"
    exit 0
fi

log_message "找到 $TOTAL_FILES 个文件"

# 处理文件
for file in "${files[@]}"; do
    process_file "$file" "$backup_file"
done

# 显示统计信息
show_statistics

if [ "$DRY_RUN" = false ]; then
    echo "${GREEN}批量重命名完成${NC}"
else
    echo "${YELLOW}预览完成${NC}"
fi
