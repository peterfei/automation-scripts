#!/bin/bash

# =============================================================================
# 系统信息收集脚本
# System Information Collection Script
# =============================================================================
# 
# 用途/Use Case:
# - 收集系统基本信息用于故障排查
# - 生成系统状态报告
# - 监控系统性能指标
# 
# 使用方法/Usage:
# ./system_info.sh [output_file]
# 
# 示例/Examples:
# ./system_info.sh                    # 输出到控制台
# ./system_info.sh system_report.txt  # 保存到文件
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
NC='\033[0m' # No Color

# 输出函数
output() {
    if [ -n "$OUTPUT_FILE" ]; then
        echo "$1" >> "$OUTPUT_FILE"
    else
        echo "$1"
    fi
}

# 检查参数
if [ $# -gt 0 ]; then
    OUTPUT_FILE="$1"
    echo "系统信息将保存到: $OUTPUT_FILE"
fi

# 清空输出文件（如果指定）
if [ -n "$OUTPUT_FILE" ]; then
    > "$OUTPUT_FILE"
fi

output "=========================================="
output "系统信息报告 / System Information Report"
output "生成时间 / Generated: $(date)"
output "=========================================="
output ""

# 操作系统信息
output "${BLUE}操作系统信息 / Operating System:${NC}"
output "系统类型: $(uname -s)"
output "内核版本: $(uname -r)"
output "主机名: $(hostname)"
output "架构: $(uname -m)"
if [ -f /etc/os-release ]; then
    output "发行版: $(grep PRETTY_NAME /etc/os-release | cut -d'"' -f2)"
fi
output ""

# CPU信息
output "${BLUE}CPU信息 / CPU Information:${NC}"
output "CPU型号: $(lscpu | grep "Model name" | cut -d':' -f2 | xargs)"
output "CPU核心数: $(nproc)"
output "CPU使用率: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
output ""

# 内存信息
output "${BLUE}内存信息 / Memory Information:${NC}"
free -h | while read line; do
    output "$line"
done
output ""

# 磁盘信息
output "${BLUE}磁盘使用情况 / Disk Usage:${NC}"
df -h | while read line; do
    output "$line"
done
output ""

# 网络信息
output "${BLUE}网络信息 / Network Information:${NC}"
output "IP地址: $(hostname -I | awk '{print $1}')"
output "网络接口:"
ip addr show | grep -E "inet |UP|DOWN" | while read line; do
    output "  $line"
done
output ""

# 进程信息
output "${BLUE}进程信息 / Process Information:${NC}"
output "运行中的进程数: $(ps aux | wc -l)"
output "内存使用最多的前5个进程:"
ps aux --sort=-%mem | head -6 | while read line; do
    output "  $line"
done
output ""

# 服务状态
output "${BLUE}服务状态 / Service Status:${NC}"
if command -v systemctl &> /dev/null; then
    output "系统服务状态:"
    systemctl list-units --type=service --state=running | head -10 | while read line; do
        output "  $line"
    done
fi
output ""

# 系统负载
output "${BLUE}系统负载 / System Load:${NC}"
output "负载平均值: $(uptime | awk -F'load average:' '{print $2}')"
output "运行时间: $(uptime -p)"
output ""

# 用户信息
output "${BLUE}用户信息 / User Information:${NC}"
output "当前用户: $(whoami)"
output "登录用户数: $(who | wc -l)"
output "当前登录用户:"
who | while read line; do
    output "  $line"
done
output ""

# 环境变量
output "${BLUE}环境变量 / Environment Variables:${NC}"
output "PATH: $PATH"
output "SHELL: $SHELL"
output "HOME: $HOME"
output ""

output "=========================================="
output "报告结束 / End of Report"
output "=========================================="

if [ -n "$OUTPUT_FILE" ]; then
    echo "${GREEN}系统信息已保存到: $OUTPUT_FILE${NC}"
else
    echo "${GREEN}系统信息收集完成${NC}"
fi
