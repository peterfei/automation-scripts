#!/bin/bash

# =============================================================================
# 日志分析脚本
# Log Analyzer Script
# =============================================================================
# 
# 用途/Use Case:
# - 分析系统日志文件
# - 统计错误和警告信息
# - 查找特定模式
# - 生成日志报告
# 
# 使用方法/Usage:
# ./log_analyzer.sh [options] [log_file]
# 
# 选项/Options:
# -f, --file FILE        指定日志文件
# -d, --dir DIR          指定日志目录
# -p, --pattern PATTERN  搜索模式
# -e, --error            只显示错误日志
# -w, --warning          只显示警告日志
# -i, --info             只显示信息日志
# -s, --since DATE       从指定日期开始
# -u, --until DATE       到指定日期结束
# -c, --count            统计行数
# -t, --top N            显示前N条记录
# -o, --output FILE      输出到文件
# -h, --help             显示帮助信息
# 
# 示例/Examples:
# ./log_analyzer.sh --file /var/log/syslog --error
# ./log_analyzer.sh --dir /var/log --pattern "error" --count
# ./log_analyzer.sh --file app.log --since "2024-01-01" --top 10
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
LOG_FILE=""
LOG_DIR=""
PATTERN=""
ERROR_ONLY=false
WARNING_ONLY=false
INFO_ONLY=false
SINCE_DATE=""
UNTIL_DATE=""
COUNT_ONLY=false
TOP_COUNT=0
OUTPUT_FILE=""
VERBOSE=false

# 统计变量
TOTAL_LINES=0
ERROR_COUNT=0
WARNING_COUNT=0
INFO_COUNT=0
PATTERN_COUNT=0

# 显示帮助信息
show_help() {
    echo "日志分析脚本 / Log Analyzer Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options] [日志文件 / log_file]"
    echo ""
    echo "选项 / Options:"
    echo "  -f, --file FILE        指定日志文件"
    echo "  -d, --dir DIR          指定日志目录"
    echo "  -p, --pattern PATTERN  搜索模式"
    echo "  -e, --error            只显示错误日志"
    echo "  -w, --warning          只显示警告日志"
    echo "  -i, --info             只显示信息日志"
    echo "  -s, --since DATE       从指定日期开始 (YYYY-MM-DD)"
    echo "  -u, --until DATE       到指定日期结束 (YYYY-MM-DD)"
    echo "  -c, --count            统计行数"
    echo "  -t, --top N            显示前N条记录"
    echo "  -o, --output FILE      输出到文件"
    echo "  -v, --verbose          详细输出"
    echo "  -h, --help             显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --file /var/log/syslog --error"
    echo "  $0 --dir /var/log --pattern \"error\" --count"
    echo "  $0 --file app.log --since \"2024-01-01\" --top 10"
}

# 输出函数
output() {
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        echo "$1"
    fi
}

# 解析日期
parse_date() {
    local date_str="$1"
    if [[ "$date_str" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        echo "$date_str"
    else
        echo ""
    fi
}

# 检查日志级别
check_log_level() {
    local line="$1"
    
    if echo "$line" | grep -qi "error\|err\|failed\|fail"; then
        echo "error"
    elif echo "$line" | grep -qi "warn\|warning"; then
        echo "warning"
    elif echo "$line" | grep -qi "info\|information"; then
        echo "info"
    else
        echo "other"
    fi
}

# 分析单个日志文件
analyze_log_file() {
    local file="$1"
    local temp_file="/tmp/log_analyzer_$$"
    
    if [ ! -f "$file" ]; then
        echo "${RED}错误: 文件不存在: $file${NC}"
        return 1
    fi
    
    echo "${BLUE}分析日志文件: $file${NC}"
    
    # 创建临时文件用于过滤
    cp "$file" "$temp_file"
    
    # 应用日期过滤
    if [ -n "$SINCE_DATE" ]; then
        grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}|^[A-Za-z]{3} [0-9]{1,2}|^[0-9]{1,2}/[A-Za-z]{3}/[0-9]{4}" "$temp_file" | \
        awk -v since="$SINCE_DATE" '$0 >= since' > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    fi
    
    if [ -n "$UNTIL_DATE" ]; then
        grep -E "^[0-9]{4}-[0-9]{2}-[0-9]{2}|^[A-Za-z]{3} [0-9]{1,2}|^[0-9]{1,2}/[A-Za-z]{3}/[0-9]{4}" "$temp_file" | \
        awk -v until="$UNTIL_DATE" '$0 <= until' > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    fi
    
    # 应用模式过滤
    if [ -n "$PATTERN" ]; then
        grep -i "$PATTERN" "$temp_file" > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    fi
    
    # 应用级别过滤
    if [ "$ERROR_ONLY" = true ]; then
        grep -i "error\|err\|failed\|fail" "$temp_file" > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    elif [ "$WARNING_ONLY" = true ]; then
        grep -i "warn\|warning" "$temp_file" > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    elif [ "$INFO_ONLY" = true ]; then
        grep -i "info\|information" "$temp_file" > "${temp_file}.filtered"
        mv "${temp_file}.filtered" "$temp_file"
    fi
    
    # 统计信息
    local file_lines=$(wc -l < "$temp_file")
    local file_errors=$(grep -ci "error\|err\|failed\|fail" "$temp_file")
    local file_warnings=$(grep -ci "warn\|warning" "$temp_file")
    local file_info=$(grep -ci "info\|information" "$temp_file")
    local file_pattern=0
    
    if [ -n "$PATTERN" ]; then
        file_pattern=$(grep -ci "$PATTERN" "$temp_file")
    fi
    
    # 更新全局统计
    TOTAL_LINES=$((TOTAL_LINES + file_lines))
    ERROR_COUNT=$((ERROR_COUNT + file_errors))
    WARNING_COUNT=$((WARNING_COUNT + file_warnings))
    INFO_COUNT=$((INFO_COUNT + file_info))
    PATTERN_COUNT=$((PATTERN_COUNT + file_pattern))
    
    # 显示结果
    if [ "$COUNT_ONLY" = true ]; then
        output "文件: $file"
        output "总行数: $file_lines"
        output "错误: $file_errors"
        output "警告: $file_warnings"
        output "信息: $file_info"
        if [ -n "$PATTERN" ]; then
            output "匹配模式 '$PATTERN': $file_pattern"
        fi
        output ""
    else
        if [ "$TOP_COUNT" -gt 0 ]; then
            head -n "$TOP_COUNT" "$temp_file" | while read line; do
                local level=$(check_log_level "$line")
                case $level in
                    "error")
                        output "${RED}$line${NC}"
                        ;;
                    "warning")
                        output "${YELLOW}$line${NC}"
                        ;;
                    "info")
                        output "${GREEN}$line${NC}"
                        ;;
                    *)
                        output "$line"
                        ;;
                esac
            done
        else
            while read line; do
                local level=$(check_log_level "$line")
                case $level in
                    "error")
                        output "${RED}$line${NC}"
                        ;;
                    "warning")
                        output "${YELLOW}$line${NC}"
                        ;;
                    "info")
                        output "${GREEN}$line${NC}"
                        ;;
                    *)
                        output "$line"
                        ;;
                esac
            done < "$temp_file"
        fi
    fi
    
    # 清理临时文件
    rm -f "$temp_file"
}

# 分析日志目录
analyze_log_directory() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        echo "${RED}错误: 目录不存在: $dir${NC}"
        return 1
    fi
    
    echo "${BLUE}分析日志目录: $dir${NC}"
    
    # 查找所有日志文件
    find "$dir" -type f \( -name "*.log" -o -name "*.out" -o -name "*.err" \) | while read file; do
        analyze_log_file "$file"
    done
}

# 生成报告
generate_report() {
    output ""
    output "${BLUE}=== 日志分析报告 ===${NC}"
    output "分析时间: $(date)"
    output ""
    
    if [ -n "$LOG_FILE" ]; then
        output "日志文件: $LOG_FILE"
    elif [ -n "$LOG_DIR" ]; then
        output "日志目录: $LOG_DIR"
    fi
    
    if [ -n "$PATTERN" ]; then
        output "搜索模式: $PATTERN"
    fi
    
    if [ -n "$SINCE_DATE" ]; then
        output "开始日期: $SINCE_DATE"
    fi
    
    if [ -n "$UNTIL_DATE" ]; then
        output "结束日期: $UNTIL_DATE"
    fi
    
    output ""
    output "统计结果:"
    output "  总行数: $TOTAL_LINES"
    output "  错误数: $ERROR_COUNT"
    output "  警告数: $WARNING_COUNT"
    output "  信息数: $INFO_COUNT"
    
    if [ -n "$PATTERN" ]; then
        output "  匹配模式 '$PATTERN': $PATTERN_COUNT"
    fi
    
    if [ "$TOTAL_LINES" -gt 0 ]; then
        local error_rate=$(echo "scale=2; $ERROR_COUNT * 100 / $TOTAL_LINES" | bc -l 2>/dev/null || echo "0")
        local warning_rate=$(echo "scale=2; $WARNING_COUNT * 100 / $TOTAL_LINES" | bc -l 2>/dev/null || echo "0")
        output ""
        output "错误率: ${error_rate}%"
        output "警告率: ${warning_rate}%"
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            LOG_FILE="$2"
            shift 2
            ;;
        -d|--dir)
            LOG_DIR="$2"
            shift 2
            ;;
        -p|--pattern)
            PATTERN="$2"
            shift 2
            ;;
        -e|--error)
            ERROR_ONLY=true
            shift
            ;;
        -w|--warning)
            WARNING_ONLY=true
            shift
            ;;
        -i|--info)
            INFO_ONLY=true
            shift
            ;;
        -s|--since)
            SINCE_DATE=$(parse_date "$2")
            if [ -z "$SINCE_DATE" ]; then
                echo "错误: 无效的日期格式: $2 (应为 YYYY-MM-DD)"
                exit 1
            fi
            shift 2
            ;;
        -u|--until)
            UNTIL_DATE=$(parse_date "$2")
            if [ -z "$UNTIL_DATE" ]; then
                echo "错误: 无效的日期格式: $2 (应为 YYYY-MM-DD)"
                exit 1
            fi
            shift 2
            ;;
        -c|--count)
            COUNT_ONLY=true
            shift
            ;;
        -t|--top)
            TOP_COUNT="$2"
            shift 2
            ;;
        -o|--output)
            OUTPUT_FILE="$2"
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
        -*)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$LOG_FILE" ] && [ -z "$LOG_DIR" ]; then
                LOG_FILE="$1"
            fi
            shift
            ;;
    esac
done

# 检查参数
if [ -z "$LOG_FILE" ] && [ -z "$LOG_DIR" ]; then
    echo "错误: 请指定日志文件或目录"
    show_help
    exit 1
fi

if [ -n "$LOG_FILE" ] && [ -n "$LOG_DIR" ]; then
    echo "错误: 不能同时指定文件和目录"
    exit 1
fi

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 执行分析
if [ -n "$LOG_FILE" ]; then
    analyze_log_file "$LOG_FILE"
else
    analyze_log_directory "$LOG_DIR"
fi

# 生成报告
generate_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}分析结果已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}日志分析完成${NC}"
fi
