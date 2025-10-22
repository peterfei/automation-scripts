#!/bin/bash

# =============================================================================
# Web服务器监控脚本
# Web Server Monitoring Script
# =============================================================================
# 
# 用途/Use Case:
# - 监控Web服务器状态
# - 检查HTTP响应码
# - 监控响应时间
# - 检测SSL证书状态
# - 生成监控报告
# 
# 使用方法/Usage:
# ./webserver_monitor.sh [options] [url]
# 
# 选项/Options:
# -u, --url URL           监控的URL
# -i, --interval SECONDS  监控间隔（秒），默认60秒
# -d, --duration SECONDS  监控持续时间，默认3600秒
# -t, --timeout SECONDS   请求超时时间，默认10秒
# -c, --code CODE         期望的HTTP状态码，默认200
# -s, --ssl               检查SSL证书
# -a, --alert EMAIL       发送告警邮件
# -o, --output FILE       输出文件
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./webserver_monitor.sh --url https://example.com --interval 30
# ./webserver_monitor.sh --url https://example.com --ssl --alert admin@example.com
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
URL=""
INTERVAL=60
DURATION=3600
TIMEOUT=10
EXPECTED_CODE=200
CHECK_SSL=false
ALERT_EMAIL=""
OUTPUT_FILE=""
VERBOSE=false

# 统计变量
TOTAL_REQUESTS=0
SUCCESSFUL_REQUESTS=0
FAILED_REQUESTS=0
AVG_RESPONSE_TIME=0
MIN_RESPONSE_TIME=999999
MAX_RESPONSE_TIME=0
SSL_ERRORS=0

# 显示帮助信息
show_help() {
    echo "Web服务器监控脚本 / Web Server Monitoring Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options] [URL]"
    echo ""
    echo "选项 / Options:"
    echo "  -u, --url URL           监控的URL"
    echo "  -i, --interval SECONDS  监控间隔（秒），默认60秒"
    echo "  -d, --duration SECONDS  监控持续时间，默认3600秒"
    echo "  -t, --timeout SECONDS   请求超时时间，默认10秒"
    echo "  -c, --code CODE         期望的HTTP状态码，默认200"
    echo "  -s, --ssl               检查SSL证书"
    echo "  -a, --alert EMAIL       发送告警邮件"
    echo "  -o, --output FILE       输出文件"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --url https://example.com --interval 30"
    echo "  $0 --url https://example.com --ssl --alert admin@example.com"
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

# 检查URL响应
check_url_response() {
    local url="$1"
    local timeout="$2"
    local expected_code="$3"
    
    local start_time=$(date +%s%3N)
    
    # 使用curl检查URL
    local response=$(curl -s -o /dev/null -w "%{http_code}|%{time_total}|%{time_connect}|%{time_starttransfer}" \
        --max-time "$timeout" \
        --connect-timeout "$timeout" \
        "$url" 2>/dev/null)
    
    local end_time=$(date +%s%3N)
    local total_time=$((end_time - start_time))
    
    if [ -n "$response" ]; then
        local http_code=$(echo "$response" | cut -d'|' -f1)
        local time_total=$(echo "$response" | cut -d'|' -f2)
        local time_connect=$(echo "$response" | cut -d'|' -f3)
        local time_starttransfer=$(echo "$response" | cut -d'|' -f4)
        
        # 转换时间单位为毫秒
        local response_time=$(echo "$time_total * 1000" | bc -l 2>/dev/null || echo "$time_total")
        
        echo "$http_code|$response_time|$time_connect|$time_starttransfer"
    else
        echo "000|$total_time|0|0"
    fi
}

# 检查SSL证书
check_ssl_certificate() {
    local url="$1"
    
    if [[ "$url" != https://* ]]; then
        return 0
    fi
    
    local domain=$(echo "$url" | sed 's|https://||' | cut -d'/' -f1)
    
    # 检查SSL证书
    local cert_info=$(echo | openssl s_client -servername "$domain" -connect "$domain:443" 2>/dev/null | openssl x509 -text -noout 2>/dev/null)
    
    if [ -z "$cert_info" ]; then
        SSL_ERRORS=$((SSL_ERRORS + 1))
        return 1
    fi
    
    # 获取证书过期时间
    local not_after=$(echo "$cert_info" | grep -A1 "Not After" | tail -1 | sed 's/.*Not After : //')
    local current_date=$(date +%s)
    local expiry_date=$(date -d "$not_after" +%s 2>/dev/null)
    
    if [ -z "$expiry_date" ]; then
        # macOS 兼容性
        expiry_date=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null)
    fi
    
    if [ -n "$expiry_date" ]; then
        local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
        
        if [ "$days_until_expiry" -lt 30 ]; then
            log_message "警告: SSL证书将在 $days_until_expiry 天后过期"
        fi
    fi
    
    return 0
}

# 发送告警邮件
send_alert_email() {
    local subject="$1"
    local body="$2"
    local email="$3"
    
    if [ -z "$email" ]; then
        return 0
    fi
    
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$email"
    elif command -v sendmail &> /dev/null; then
        echo "$body" | sendmail "$email"
    else
        log_message "警告: 未找到邮件发送工具"
    fi
}

# 监控Web服务器
monitor_webserver() {
    local url="$1"
    local interval="$2"
    local duration="$3"
    local timeout="$4"
    local expected_code="$5"
    local check_ssl="$6"
    local alert_email="$7"
    
    local start_time=$(date +%s)
    local end_time=$((start_time + duration))
    local iteration=0
    
    log_message "开始监控Web服务器: $url"
    log_message "监控间隔: ${interval}秒"
    log_message "监控持续时间: ${duration}秒"
    
    # 输出表头
    output "时间,HTTP状态码,响应时间(ms),连接时间(ms),首字节时间(ms),SSL状态"
    
    while [ $(date +%s) -lt $end_time ]; do
        iteration=$((iteration + 1))
        local current_time=$(date '+%Y-%m-%d %H:%M:%S')
        
        # 检查URL响应
        local response=$(check_url_response "$url" "$timeout" "$expected_code")
        local http_code=$(echo "$response" | cut -d'|' -f1)
        local response_time=$(echo "$response" | cut -d'|' -f2)
        local connect_time=$(echo "$response" | cut -d'|' -f3)
        local starttransfer_time=$(echo "$response" | cut -d'|' -f4)
        
        # 检查SSL证书
        local ssl_status="N/A"
        if [ "$check_ssl" = true ]; then
            if check_ssl_certificate "$url"; then
                ssl_status="OK"
            else
                ssl_status="ERROR"
            fi
        fi
        
        # 更新统计信息
        TOTAL_REQUESTS=$((TOTAL_REQUESTS + 1))
        
        if [ "$http_code" = "$expected_code" ]; then
            SUCCESSFUL_REQUESTS=$((SUCCESSFUL_REQUESTS + 1))
            local status="${GREEN}成功${NC}"
        else
            FAILED_REQUESTS=$((FAILED_REQUESTS + 1))
            local status="${RED}失败${NC}"
            
            # 发送告警邮件
            if [ -n "$alert_email" ]; then
                local subject="Web服务器监控告警 - $url"
                local body="检测到Web服务器问题:\n\nURL: $url\n时间: $current_time\nHTTP状态码: $http_code\n响应时间: ${response_time}ms\n"
                send_alert_email "$subject" "$body" "$alert_email"
            fi
        fi
        
        # 更新响应时间统计
        if [ "$response_time" != "0" ]; then
            AVG_RESPONSE_TIME=$(echo "scale=2; ($AVG_RESPONSE_TIME * ($TOTAL_REQUESTS - 1) + $response_time) / $TOTAL_REQUESTS" | bc -l 2>/dev/null || echo "$AVG_RESPONSE_TIME")
            
            if (( $(echo "$response_time < $MIN_RESPONSE_TIME" | bc -l 2>/dev/null || echo "0") )); then
                MIN_RESPONSE_TIME="$response_time"
            fi
            
            if (( $(echo "$response_time > $MAX_RESPONSE_TIME" | bc -l 2>/dev/null || echo "0") )); then
                MAX_RESPONSE_TIME="$response_time"
            fi
        fi
        
        # 输出结果
        output "$current_time,$http_code,$response_time,$connect_time,$starttransfer_time,$ssl_status"
        
        # 显示状态
        if [ "$VERBOSE" = true ]; then
            echo "[$current_time] 第${iteration}次检查: $status (状态码: $http_code, 响应时间: ${response_time}ms)"
        fi
        
        # 等待下次检查
        sleep "$interval"
    done
}

# 生成监控报告
generate_report() {
    local end_time=$(date '+%Y-%m-%d %H:%M:%S')
    
    output ""
    output "=== Web服务器监控报告 ==="
    output "结束时间: $end_time"
    output "监控URL: $URL"
    output "总请求数: $TOTAL_REQUESTS"
    output "成功请求: $SUCCESSFUL_REQUESTS"
    output "失败请求: $FAILED_REQUESTS"
    
    if [ "$TOTAL_REQUESTS" -gt 0 ]; then
        local success_rate=$(echo "scale=2; $SUCCESSFUL_REQUESTS * 100 / $TOTAL_REQUESTS" | bc -l 2>/dev/null || echo "0")
        output "成功率: ${success_rate}%"
    fi
    
    if [ "$TOTAL_REQUESTS" -gt 0 ] && [ "$AVG_RESPONSE_TIME" != "0" ]; then
        output "平均响应时间: ${AVG_RESPONSE_TIME}ms"
        output "最小响应时间: ${MIN_RESPONSE_TIME}ms"
        output "最大响应时间: ${MAX_RESPONSE_TIME}ms"
    fi
    
    if [ "$CHECK_SSL" = true ]; then
        output "SSL错误数: $SSL_ERRORS"
    fi
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
        -u|--url)
            URL="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -d|--duration)
            DURATION="$2"
            shift 2
            ;;
        -t|--timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        -c|--code)
            EXPECTED_CODE="$2"
            shift 2
            ;;
        -s|--ssl)
            CHECK_SSL=true
            shift
            ;;
        -a|--alert)
            ALERT_EMAIL="$2"
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
            if [ -z "$URL" ]; then
                URL="$1"
            fi
            shift
            ;;
    esac
done

# 检查参数
if [ -z "$URL" ]; then
    echo "错误: 请指定要监控的URL"
    show_help
    exit 1
fi

# 验证参数
if ! [[ "$INTERVAL" =~ ^[0-9]+$ ]] || [ "$INTERVAL" -lt 1 ]; then
    echo "错误: 监控间隔必须是正整数"
    exit 1
fi

if ! [[ "$DURATION" =~ ^[0-9]+$ ]] || [ "$DURATION" -lt 1 ]; then
    echo "错误: 监控持续时间必须是正整数"
    exit 1
fi

if ! [[ "$TIMEOUT" =~ ^[0-9]+$ ]] || [ "$TIMEOUT" -lt 1 ]; then
    echo "错误: 请求超时时间必须是正整数"
    exit 1
fi

if ! [[ "$EXPECTED_CODE" =~ ^[0-9]+$ ]] || [ "$EXPECTED_CODE" -lt 100 ] || [ "$EXPECTED_CODE" -gt 599 ]; then
    echo "错误: HTTP状态码必须是100-599之间的整数"
    exit 1
fi

# 检查必要的命令
if ! command -v curl &> /dev/null; then
    echo "错误: 需要安装curl命令"
    exit 1
fi

if [ "$CHECK_SSL" = true ] && ! command -v openssl &> /dev/null; then
    echo "错误: 需要安装openssl命令来检查SSL证书"
    exit 1
fi

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 开始监控
monitor_webserver "$URL" "$INTERVAL" "$DURATION" "$TIMEOUT" "$EXPECTED_CODE" "$CHECK_SSL" "$ALERT_EMAIL"

# 生成最终报告
generate_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}监控数据已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}Web服务器监控完成${NC}"
fi
