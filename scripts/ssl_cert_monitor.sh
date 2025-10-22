#!/bin/bash

# =============================================================================
# SSL证书监控脚本
# SSL Certificate Monitoring Script
# =============================================================================
# 
# 用途/Use Case:
# - 监控SSL证书过期时间
# - 检查证书链完整性
# - 验证证书配置
# - 发送过期提醒
# 
# 使用方法/Usage:
# ./ssl_cert_monitor.sh [options] [domain|file]
# 
# 选项/Options:
# -f, --file FILE        指定证书文件
# -d, --domain DOMAIN    指定域名
# -p, --port PORT        指定端口，默认443
# -w, --warning DAYS     警告天数，默认30天
# -c, --critical DAYS    严重警告天数，默认7天
# -e, --email EMAIL      发送邮件提醒
# -l, --list FILE        从文件读取域名列表
# -o, --output FILE      输出到文件
# -v, --verbose          详细输出
# -h, --help             显示帮助信息
# 
# 示例/Examples:
# ./ssl_cert_monitor.sh --domain example.com
# ./ssl_cert_monitor.sh --file cert.pem --warning 60
# ./ssl_cert_monitor.sh --list domains.txt --email admin@example.com
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
CERT_FILE=""
DOMAIN=""
PORT=443
WARNING_DAYS=30
CRITICAL_DAYS=7
EMAIL=""
DOMAIN_LIST=""
OUTPUT_FILE=""
VERBOSE=false

# 统计变量
TOTAL_CHECKS=0
WARNING_COUNT=0
CRITICAL_COUNT=0
EXPIRED_COUNT=0
VALID_COUNT=0

# 显示帮助信息
show_help() {
    echo "SSL证书监控脚本 / SSL Certificate Monitoring Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options] [域名|文件 / domain|file]"
    echo ""
    echo "选项 / Options:"
    echo "  -f, --file FILE        指定证书文件"
    echo "  -d, --domain DOMAIN    指定域名"
    echo "  -p, --port PORT        指定端口，默认443"
    echo "  -w, --warning DAYS     警告天数，默认30天"
    echo "  -c, --critical DAYS    严重警告天数，默认7天"
    echo "  -e, --email EMAIL      发送邮件提醒"
    echo "  -l, --list FILE        从文件读取域名列表"
    echo "  -o, --output FILE      输出到文件"
    echo "  -v, --verbose          详细输出"
    echo "  -h, --help             显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --domain example.com"
    echo "  $0 --file cert.pem --warning 60"
    echo "  $0 --list domains.txt --email admin@example.com"
}

# 输出函数
output() {
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        echo "$1"
    fi
}

# 检查证书文件
check_cert_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "${RED}错误: 证书文件不存在: $file${NC}"
        return 1
    fi
    
    # 检查文件格式
    if ! openssl x509 -in "$file" -text -noout &>/dev/null; then
        echo "${RED}错误: 无效的证书文件格式: $file${NC}"
        return 1
    fi
    
    return 0
}

# 获取证书信息
get_cert_info() {
    local source="$1"
    local is_file="$2"
    
    local cert_info=""
    
    if [ "$is_file" = true ]; then
        # 从文件读取证书
        cert_info=$(openssl x509 -in "$source" -text -noout 2>/dev/null)
    else
        # 从域名获取证书
        cert_info=$(echo | openssl s_client -servername "$source" -connect "$source:$PORT" 2>/dev/null | openssl x509 -text -noout 2>/dev/null)
    fi
    
    if [ -z "$cert_info" ]; then
        return 1
    fi
    
    echo "$cert_info"
}

# 解析证书信息
parse_cert_info() {
    local cert_info="$1"
    local source="$2"
    
    # 获取过期时间
    local not_after=$(echo "$cert_info" | grep -A1 "Not After" | tail -1 | sed 's/.*Not After : //')
    local not_before=$(echo "$cert_info" | grep -A1 "Not Before" | tail -1 | sed 's/.*Not Before: //')
    
    # 获取主题
    local subject=$(echo "$cert_info" | grep "Subject:" | sed 's/.*Subject: //')
    
    # 获取颁发者
    local issuer=$(echo "$cert_info" | grep "Issuer:" | sed 's/.*Issuer: //')
    
    # 获取序列号
    local serial=$(echo "$cert_info" | grep "Serial Number:" | sed 's/.*Serial Number: //')
    
    # 获取指纹
    local fingerprint=$(echo "$cert_info" | grep -A1 "SHA1 Fingerprint" | tail -1 | sed 's/.*SHA1 Fingerprint=//')
    
    # 计算剩余天数
    local current_date=$(date +%s)
    local expiry_date=$(date -d "$not_after" +%s 2>/dev/null)
    
    if [ -z "$expiry_date" ]; then
        # macOS 兼容性
        expiry_date=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$not_after" +%s 2>/dev/null)
    fi
    
    if [ -z "$expiry_date" ]; then
        echo "${RED}错误: 无法解析证书过期时间${NC}"
        return 1
    fi
    
    local days_until_expiry=$(( (expiry_date - current_date) / 86400 ))
    
    # 确定状态
    local status=""
    local color=""
    
    if [ "$days_until_expiry" -lt 0 ]; then
        status="已过期"
        color="$RED"
        EXPIRED_COUNT=$((EXPIRED_COUNT + 1))
    elif [ "$days_until_expiry" -le "$CRITICAL_DAYS" ]; then
        status="严重警告"
        color="$RED"
        CRITICAL_COUNT=$((CRITICAL_COUNT + 1))
    elif [ "$days_until_expiry" -le "$WARNING_DAYS" ]; then
        status="警告"
        color="$YELLOW"
        WARNING_COUNT=$((WARNING_COUNT + 1))
    else
        status="正常"
        color="$GREEN"
        VALID_COUNT=$((VALID_COUNT + 1))
    fi
    
    # 输出结果
    output "${BLUE}=== 证书信息 ===${NC}"
    output "来源: $source"
    output "主题: $subject"
    output "颁发者: $issuer"
    output "序列号: $serial"
    output "指纹: $fingerprint"
    output "有效期开始: $not_before"
    output "有效期结束: $not_after"
    output "剩余天数: $days_until_expiry"
    output "状态: ${color}$status${NC}"
    output ""
    
    # 返回状态码
    if [ "$days_until_expiry" -lt 0 ]; then
        return 3  # 已过期
    elif [ "$days_until_expiry" -le "$CRITICAL_DAYS" ]; then
        return 2  # 严重警告
    elif [ "$days_until_expiry" -le "$WARNING_DAYS" ]; then
        return 1  # 警告
    else
        return 0  # 正常
    fi
}

# 检查域名证书
check_domain_cert() {
    local domain="$1"
    
    echo "${BLUE}检查域名证书: $domain${NC}"
    
    # 检查域名解析
    if ! nslookup "$domain" &>/dev/null; then
        echo "${RED}错误: 无法解析域名: $domain${NC}"
        return 1
    fi
    
    # 获取证书信息
    local cert_info=$(get_cert_info "$domain" false)
    if [ -z "$cert_info" ]; then
        echo "${RED}错误: 无法获取证书信息: $domain${NC}"
        return 1
    fi
    
    # 解析证书信息
    parse_cert_info "$cert_info" "$domain"
    local result=$?
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    return $result
}

# 检查证书文件
check_cert_file() {
    local file="$1"
    
    echo "${BLUE}检查证书文件: $file${NC}"
    
    # 验证证书文件
    if ! check_cert_file "$file"; then
        return 1
    fi
    
    # 获取证书信息
    local cert_info=$(get_cert_info "$file" true)
    if [ -z "$cert_info" ]; then
        echo "${RED}错误: 无法读取证书文件: $file${NC}"
        return 1
    fi
    
    # 解析证书信息
    parse_cert_info "$cert_info" "$file"
    local result=$?
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    return $result
}

# 从文件读取域名列表
check_domain_list() {
    local list_file="$1"
    
    if [ ! -f "$list_file" ]; then
        echo "${RED}错误: 域名列表文件不存在: $list_file${NC}"
        return 1
    fi
    
    echo "${BLUE}从文件读取域名列表: $list_file${NC}"
    
    while IFS= read -r domain; do
        # 跳过空行和注释
        if [[ -z "$domain" || "$domain" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 去除前后空格
        domain=$(echo "$domain" | xargs)
        
        if [ -n "$domain" ]; then
            check_domain_cert "$domain"
        fi
    done < "$list_file"
}

# 发送邮件提醒
send_email_alert() {
    local subject="$1"
    local body="$2"
    local recipient="$3"
    
    if [ -z "$recipient" ]; then
        return 0
    fi
    
    if command -v mail &> /dev/null; then
        echo "$body" | mail -s "$subject" "$recipient"
    elif command -v sendmail &> /dev/null; then
        echo "$body" | sendmail "$recipient"
    else
        echo "${YELLOW}警告: 未找到邮件发送工具${NC}"
    fi
}

# 生成报告
generate_report() {
    output ""
    output "${BLUE}=== SSL证书监控报告 ===${NC}"
    output "检查时间: $(date)"
    output "总检查数: $TOTAL_CHECKS"
    output "正常: $VALID_COUNT"
    output "警告: $WARNING_COUNT"
    output "严重警告: $CRITICAL_COUNT"
    output "已过期: $EXPIRED_COUNT"
    output ""
    
    # 发送邮件提醒
    if [ -n "$EMAIL" ] && [ "$WARNING_COUNT" -gt 0 ] || [ "$CRITICAL_COUNT" -gt 0 ] || [ "$EXPIRED_COUNT" -gt 0 ]; then
        local subject="SSL证书监控提醒"
        local body="SSL证书监控发现以下问题:\n\n"
        body+="总检查数: $TOTAL_CHECKS\n"
        body+="正常: $VALID_COUNT\n"
        body+="警告: $WARNING_COUNT\n"
        body+="严重警告: $CRITICAL_COUNT\n"
        body+="已过期: $EXPIRED_COUNT\n"
        
        send_email_alert "$subject" "$body" "$EMAIL"
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -f|--file)
            CERT_FILE="$2"
            shift 2
            ;;
        -d|--domain)
            DOMAIN="$2"
            shift 2
            ;;
        -p|--port)
            PORT="$2"
            shift 2
            ;;
        -w|--warning)
            WARNING_DAYS="$2"
            shift 2
            ;;
        -c|--critical)
            CRITICAL_DAYS="$2"
            shift 2
            ;;
        -e|--email)
            EMAIL="$2"
            shift 2
            ;;
        -l|--list)
            DOMAIN_LIST="$2"
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
            if [ -z "$DOMAIN" ] && [ -z "$CERT_FILE" ] && [ -z "$DOMAIN_LIST" ]; then
                DOMAIN="$1"
            fi
            shift
            ;;
    esac
done

# 检查参数
if [ -z "$CERT_FILE" ] && [ -z "$DOMAIN" ] && [ -z "$DOMAIN_LIST" ]; then
    echo "错误: 请指定证书文件、域名或域名列表"
    show_help
    exit 1
fi

# 验证参数
if ! [[ "$WARNING_DAYS" =~ ^[0-9]+$ ]] || [ "$WARNING_DAYS" -lt 1 ]; then
    echo "错误: 警告天数必须是正整数"
    exit 1
fi

if ! [[ "$CRITICAL_DAYS" =~ ^[0-9]+$ ]] || [ "$CRITICAL_DAYS" -lt 1 ]; then
    echo "错误: 严重警告天数必须是正整数"
    exit 1
fi

if [ "$CRITICAL_DAYS" -ge "$WARNING_DAYS" ]; then
    echo "错误: 严重警告天数必须小于警告天数"
    exit 1
fi

# 清空输出文件
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

# 执行检查
if [ -n "$CERT_FILE" ]; then
    check_cert_file "$CERT_FILE"
elif [ -n "$DOMAIN_LIST" ]; then
    check_domain_list "$DOMAIN_LIST"
else
    check_domain_cert "$DOMAIN"
fi

# 生成报告
generate_report

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}检查结果已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}SSL证书检查完成${NC}"
fi
