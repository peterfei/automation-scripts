#!/bin/bash

# =============================================================================
# 邮件通知脚本
# Email Notification Script
# =============================================================================
# 
# 用途/Use Case:
# - 发送邮件通知
# - 支持HTML和纯文本格式
# - 支持附件
# - 批量发送邮件
# 
# 使用方法/Usage:
# ./email_notifier.sh [options]
# 
# 选项/Options:
# -t, --to EMAIL          收件人邮箱
# -c, --cc EMAIL          抄送邮箱
# -b, --bcc EMAIL         密送邮箱
# -s, --subject SUBJECT   邮件主题
# -m, --message MESSAGE   邮件内容
# -f, --file FILE         邮件内容文件
# -a, --attachment FILE   附件文件
# -h, --html              HTML格式
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./email_notifier.sh --to user@example.com --subject "测试" --message "Hello World"
# ./email_notifier.sh --to user@example.com --subject "报告" --file report.html --html
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
TO_EMAIL=""
CC_EMAIL=""
BCC_EMAIL=""
SUBJECT=""
MESSAGE=""
MESSAGE_FILE=""
ATTACHMENT=""
HTML_FORMAT=false
VERBOSE=false

# 显示帮助信息
show_help() {
    echo "邮件通知脚本 / Email Notification Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -t, --to EMAIL          收件人邮箱"
    echo "  -c, --cc EMAIL          抄送邮箱"
    echo "  -b, --bcc EMAIL         密送邮箱"
    echo "  -s, --subject SUBJECT   邮件主题"
    echo "  -m, --message MESSAGE   邮件内容"
    echo "  -f, --file FILE         邮件内容文件"
    echo "  -a, --attachment FILE   附件文件"
    echo "  -h, --html              HTML格式"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --to user@example.com --subject \"测试\" --message \"Hello World\""
    echo "  $0 --to user@example.com --subject \"报告\" --file report.html --html"
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

# 检查邮件发送工具
check_mail_tools() {
    local tools=()
    
    if ! command -v mail &> /dev/null; then
        tools+=("mail")
    fi
    
    if ! command -v sendmail &> /dev/null; then
        tools+=("sendmail")
    fi
    
    if ! command -v mutt &> /dev/null; then
        tools+=("mutt")
    fi
    
    if [ ${#tools[@]} -eq 3 ]; then
        echo "${RED}错误: 未找到邮件发送工具，请安装 mail、sendmail 或 mutt${NC}"
        exit 1
    fi
}

# 发送纯文本邮件
send_text_email() {
    local to="$1"
    local cc="$2"
    local bcc="$3"
    local subject="$4"
    local message="$5"
    local attachment="$6"
    
    log_message "发送纯文本邮件到: $to"
    
    if [ -n "$attachment" ] && [ -f "$attachment" ]; then
        # 使用mutt发送带附件的邮件
        if command -v mutt &> /dev/null; then
            local mutt_cmd="mutt -s \"$subject\""
            
            if [ -n "$cc" ]; then
                mutt_cmd="$mutt_cmd -c \"$cc\""
            fi
            
            if [ -n "$bcc" ]; then
                mutt_cmd="$mutt_cmd -b \"$bcc\""
            fi
            
            mutt_cmd="$mutt_cmd -a \"$attachment\" -- \"$to\""
            
            echo "$message" | eval "$mutt_cmd"
        else
            echo "${RED}错误: 需要安装 mutt 来发送带附件的邮件${NC}"
            return 1
        fi
    else
        # 使用mail或sendmail发送纯文本邮件
        if command -v mail &> /dev/null; then
            local mail_cmd="mail -s \"$subject\""
            
            if [ -n "$cc" ]; then
                mail_cmd="$mail_cmd -c \"$cc\""
            fi
            
            if [ -n "$bcc" ]; then
                mail_cmd="$mail_cmd -b \"$bcc\""
            fi
            
            mail_cmd="$mail_cmd \"$to\""
            
            echo "$message" | eval "$mail_cmd"
        elif command -v sendmail &> /dev/null; then
            local sendmail_cmd="sendmail"
            
            if [ -n "$cc" ]; then
                sendmail_cmd="$sendmail_cmd -c \"$cc\""
            fi
            
            if [ -n "$bcc" ]; then
                sendmail_cmd="$sendmail_cmd -b \"$bcc\""
            fi
            
            sendmail_cmd="$sendmail_cmd \"$to\""
            
            echo "$message" | eval "$sendmail_cmd"
        else
            echo "${RED}错误: 未找到可用的邮件发送工具${NC}"
            return 1
        fi
    fi
}

# 发送HTML邮件
send_html_email() {
    local to="$1"
    local cc="$2"
    local bcc="$3"
    local subject="$4"
    local message="$5"
    local attachment="$6"
    
    log_message "发送HTML邮件到: $to"
    
    # 使用mutt发送HTML邮件
    if command -v mutt &> /dev/null; then
        local mutt_cmd="mutt -s \"$subject\" -e \"set content_type=text/html\""
        
        if [ -n "$cc" ]; then
            mutt_cmd="$mutt_cmd -c \"$cc\""
        fi
        
        if [ -n "$bcc" ]; then
            mutt_cmd="$mutt_cmd -b \"$bcc\""
        fi
        
        if [ -n "$attachment" ] && [ -f "$attachment" ]; then
            mutt_cmd="$mutt_cmd -a \"$attachment\""
        fi
        
        mutt_cmd="$mutt_cmd -- \"$to\""
        
        echo "$message" | eval "$mutt_cmd"
    else
        echo "${RED}错误: 需要安装 mutt 来发送HTML邮件${NC}"
        return 1
    fi
}

# 发送邮件
send_email() {
    local to="$1"
    local cc="$2"
    local bcc="$3"
    local subject="$4"
    local message="$5"
    local attachment="$6"
    local html="$7"
    
    if [ -z "$to" ]; then
        echo "${RED}错误: 请指定收件人邮箱${NC}"
        return 1
    fi
    
    if [ -z "$subject" ]; then
        echo "${RED}错误: 请指定邮件主题${NC}"
        return 1
    fi
    
    if [ -z "$message" ]; then
        echo "${RED}错误: 请指定邮件内容${NC}"
        return 1
    fi
    
    # 检查邮件发送工具
    check_mail_tools
    
    # 发送邮件
    if [ "$html" = true ]; then
        send_html_email "$to" "$cc" "$bcc" "$subject" "$message" "$attachment"
    else
        send_text_email "$to" "$cc" "$bcc" "$subject" "$message" "$attachment"
    fi
    
    local result=$?
    
    if [ $result -eq 0 ]; then
        output "${GREEN}邮件发送成功${NC}"
        return 0
    else
        output "${RED}邮件发送失败${NC}"
        return 1
    fi
}

# 批量发送邮件
send_bulk_email() {
    local recipients_file="$1"
    local subject="$2"
    local message="$3"
    local attachment="$4"
    local html="$5"
    
    if [ ! -f "$recipients_file" ]; then
        echo "${RED}错误: 收件人文件不存在: $recipients_file${NC}"
        return 1
    fi
    
    log_message "开始批量发送邮件"
    
    local success_count=0
    local fail_count=0
    
    while IFS= read -r email; do
        # 跳过空行和注释
        if [[ -z "$email" || "$email" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 去除前后空格
        email=$(echo "$email" | xargs)
        
        if [ -n "$email" ]; then
            if send_email "$email" "" "" "$subject" "$message" "$attachment" "$html"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
        fi
    done < "$recipients_file"
    
    output "批量发送完成: 成功 $success_count 封，失败 $fail_count 封"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--to)
            TO_EMAIL="$2"
            shift 2
            ;;
        -c|--cc)
            CC_EMAIL="$2"
            shift 2
            ;;
        -b|--bcc)
            BCC_EMAIL="$2"
            shift 2
            ;;
        -s|--subject)
            SUBJECT="$2"
            shift 2
            ;;
        -m|--message)
            MESSAGE="$2"
            shift 2
            ;;
        -f|--file)
            MESSAGE_FILE="$2"
            shift 2
            ;;
        -a|--attachment)
            ATTACHMENT="$2"
            shift 2
            ;;
        --html)
            HTML_FORMAT=true
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
        *)
            echo "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查参数
if [ -z "$TO_EMAIL" ]; then
    echo "错误: 请指定收件人邮箱"
    show_help
    exit 1
fi

if [ -z "$SUBJECT" ]; then
    echo "错误: 请指定邮件主题"
    show_help
    exit 1
fi

# 获取邮件内容
if [ -n "$MESSAGE_FILE" ]; then
    if [ ! -f "$MESSAGE_FILE" ]; then
        echo "${RED}错误: 邮件内容文件不存在: $MESSAGE_FILE${NC}"
        exit 1
    fi
    MESSAGE=$(cat "$MESSAGE_FILE")
elif [ -z "$MESSAGE" ]; then
    echo "错误: 请指定邮件内容或内容文件"
    show_help
    exit 1
fi

# 检查附件
if [ -n "$ATTACHMENT" ] && [ ! -f "$ATTACHMENT" ]; then
    echo "${RED}错误: 附件文件不存在: $ATTACHMENT${NC}"
    exit 1
fi

# 发送邮件
if [[ "$TO_EMAIL" == *","* ]]; then
    # 多个收件人
    IFS=',' read -ra EMAILS <<< "$TO_EMAIL"
    for email in "${EMAILS[@]}"; do
        email=$(echo "$email" | xargs)
        if [ -n "$email" ]; then
            send_email "$email" "$CC_EMAIL" "$BCC_EMAIL" "$SUBJECT" "$MESSAGE" "$ATTACHMENT" "$HTML_FORMAT"
        fi
    done
else
    # 单个收件人
    send_email "$TO_EMAIL" "$CC_EMAIL" "$BCC_EMAIL" "$SUBJECT" "$MESSAGE" "$ATTACHMENT" "$HTML_FORMAT"
fi
