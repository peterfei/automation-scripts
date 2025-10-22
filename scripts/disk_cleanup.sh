#!/bin/bash

# =============================================================================
# 磁盘清理脚本
# Disk Cleanup Script
# =============================================================================
# 
# 用途/Use Case:
# - 清理临时文件和缓存
# - 释放磁盘空间
# - 清理日志文件
# - 清理下载目录中的旧文件
# 
# 使用方法/Usage:
# ./disk_cleanup.sh [options]
# 
# 选项/Options:
# -a, --all          清理所有类型的文件
# -t, --temp         只清理临时文件
# -l, --logs         只清理日志文件
# -d, --downloads    只清理下载目录
# -c, --cache        只清理缓存文件
# -s, --size         显示清理前后的大小对比
# -h, --help         显示帮助信息
# 
# 示例/Examples:
# ./disk_cleanup.sh --all --size
# ./disk_cleanup.sh --temp --logs
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

# 默认选项
CLEAN_TEMP=false
CLEAN_LOGS=false
CLEAN_DOWNLOADS=false
CLEAN_CACHE=false
SHOW_SIZE=false
CLEAN_ALL=false

# 统计变量
TOTAL_CLEANED=0
FILES_CLEANED=0

# 显示帮助信息
show_help() {
    echo "磁盘清理脚本 / Disk Cleanup Script"
    echo ""
    echo "用法 / Usage: $0 [选项 / options]"
    echo ""
    echo "选项 / Options:"
    echo "  -a, --all          清理所有类型的文件"
    echo "  -t, --temp         只清理临时文件"
    echo "  -l, --logs         只清理日志文件"
    echo "  -d, --downloads    只清理下载目录"
    echo "  -c, --cache        只清理缓存文件"
    echo "  -s, --size         显示清理前后的大小对比"
    echo "  -h, --help         显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 --all --size"
    echo "  $0 --temp --logs"
}

# 获取目录大小
get_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# 清理临时文件
clean_temp_files() {
    echo "${BLUE}清理临时文件 / Cleaning temporary files...${NC}"
    
    # 系统临时目录
    TEMP_DIRS=("/tmp" "/var/tmp" "$HOME/.cache/tmp")
    
    for dir in "${TEMP_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "清理目录: $dir"
            # 清理7天前的文件
            find "$dir" -type f -mtime +7 -delete 2>/dev/null
            # 清理空目录
            find "$dir" -type d -empty -delete 2>/dev/null
        fi
    done
    
    # 清理用户临时文件
    if [ -d "$HOME/.local/share/Trash" ]; then
        echo "清空回收站: $HOME/.local/share/Trash"
        rm -rf "$HOME/.local/share/Trash"/*
    fi
}

# 清理日志文件
clean_log_files() {
    echo "${BLUE}清理日志文件 / Cleaning log files...${NC}"
    
    # 系统日志目录
    LOG_DIRS=("/var/log" "$HOME/.local/share/logs")
    
    for dir in "${LOG_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "清理日志目录: $dir"
            # 清理30天前的日志文件
            find "$dir" -name "*.log" -type f -mtime +30 -delete 2>/dev/null
            # 清理压缩的日志文件
            find "$dir" -name "*.log.*" -type f -mtime +7 -delete 2>/dev/null
        fi
    done
    
    # 清理journal日志
    if command -v journalctl &> /dev/null; then
        echo "清理journal日志..."
        sudo journalctl --vacuum-time=7d 2>/dev/null
    fi
}

# 清理下载目录
clean_downloads() {
    echo "${BLUE}清理下载目录 / Cleaning downloads directory...${NC}"
    
    DOWNLOAD_DIR="$HOME/Downloads"
    if [ -d "$DOWNLOAD_DIR" ]; then
        echo "清理下载目录: $DOWNLOAD_DIR"
        # 清理30天前的文件
        find "$DOWNLOAD_DIR" -type f -mtime +30 -delete 2>/dev/null
        # 清理空目录
        find "$DOWNLOAD_DIR" -type d -empty -delete 2>/dev/null
    fi
}

# 清理缓存文件
clean_cache_files() {
    echo "${BLUE}清理缓存文件 / Cleaning cache files...${NC}"
    
    # 用户缓存目录
    CACHE_DIRS=(
        "$HOME/.cache"
        "$HOME/.local/share/Trash"
        "$HOME/.thumbnails"
        "$HOME/.recently-used"
    )
    
    for dir in "${CACHE_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "清理缓存目录: $dir"
            rm -rf "$dir"/* 2>/dev/null
        fi
    done
    
    # 清理包管理器缓存
    if command -v apt &> /dev/null; then
        echo "清理APT缓存..."
        sudo apt clean 2>/dev/null
        sudo apt autoclean 2>/dev/null
    fi
    
    if command -v yum &> /dev/null; then
        echo "清理YUM缓存..."
        sudo yum clean all 2>/dev/null
    fi
    
    if command -v dnf &> /dev/null; then
        echo "清理DNF缓存..."
        sudo dnf clean all 2>/dev/null
    fi
    
    if command -v pacman &> /dev/null; then
        echo "清理Pacman缓存..."
        sudo pacman -Sc 2>/dev/null
    fi
}

# 计算清理的文件大小
calculate_cleaned_size() {
    local size=$(du -sh "$1" 2>/dev/null | cut -f1)
    echo "$size"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--all)
            CLEAN_ALL=true
            shift
            ;;
        -t|--temp)
            CLEAN_TEMP=true
            shift
            ;;
        -l|--logs)
            CLEAN_LOGS=true
            shift
            ;;
        -d|--downloads)
            CLEAN_DOWNLOADS=true
            shift
            ;;
        -c|--cache)
            CLEAN_CACHE=true
            shift
            ;;
        -s|--size)
            SHOW_SIZE=true
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

# 如果没有指定任何选项，显示帮助
if [ "$CLEAN_ALL" = false ] && [ "$CLEAN_TEMP" = false ] && [ "$CLEAN_LOGS" = false ] && [ "$CLEAN_DOWNLOADS" = false ] && [ "$CLEAN_CACHE" = false ]; then
    show_help
    exit 0
fi

echo "${GREEN}开始磁盘清理 / Starting disk cleanup...${NC}"
echo ""

# 记录清理前的大小
if [ "$SHOW_SIZE" = true ]; then
    echo "${YELLOW}清理前磁盘使用情况 / Disk usage before cleanup:${NC}"
    df -h | head -1
    df -h | grep -E "(/$|/home)" | while read line; do
        echo "  $line"
    done
    echo ""
fi

# 执行清理
if [ "$CLEAN_ALL" = true ]; then
    clean_temp_files
    clean_log_files
    clean_downloads
    clean_cache_files
else
    [ "$CLEAN_TEMP" = true ] && clean_temp_files
    [ "$CLEAN_LOGS" = true ] && clean_log_files
    [ "$CLEAN_DOWNLOADS" = true ] && clean_downloads
    [ "$CLEAN_CACHE" = true ] && clean_cache_files
fi

# 显示清理后的结果
if [ "$SHOW_SIZE" = true ]; then
    echo ""
    echo "${YELLOW}清理后磁盘使用情况 / Disk usage after cleanup:${NC}"
    df -h | head -1
    df -h | grep -E "(/$|/home)" | while read line; do
        echo "  $line"
    done
fi

echo ""
echo "${GREEN}磁盘清理完成 / Disk cleanup completed!${NC}"
