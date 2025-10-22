#!/bin/bash

# =============================================================================
# 包管理器脚本
# Package Manager Script
# =============================================================================
# 
# 用途/Use Case:
# - 统一管理不同Linux发行版的包
# - 自动检测包管理器
# - 批量安装/更新/卸载软件包
# - 清理包缓存
# 
# 使用方法/Usage:
# ./package_manager.sh [command] [options] [packages...]
# 
# 命令/Commands:
# install                 安装软件包
# update                  更新软件包列表
# upgrade                 升级软件包
# remove                  卸载软件包
# search                  搜索软件包
# list                    列出已安装的软件包
# clean                   清理包缓存
# info                    显示软件包信息
# 
# 选项/Options:
# -f, --file FILE         从文件读取软件包列表
# -y, --yes               自动确认
# -q, --quiet             静默模式
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./package_manager.sh install nginx mysql
# ./package_manager.sh update --yes
# ./package_manager.sh upgrade --file packages.txt
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
PACKAGES=()
PACKAGE_FILE=""
AUTO_YES=false
QUIET=false
VERBOSE=false

# 包管理器检测
PACKAGE_MANAGER=""
DISTRO=""

# 显示帮助信息
show_help() {
    echo "包管理器脚本 / Package Manager Script"
    echo ""
    echo "用法 / Usage: $0 [命令 / command] [选项 / options] [软件包 / packages...]"
    echo ""
    echo "命令 / Commands:"
    echo "  install                 安装软件包"
    echo "  update                  更新软件包列表"
    echo "  upgrade                 升级软件包"
    echo "  remove                  卸载软件包"
    echo "  search                  搜索软件包"
    echo "  list                    列出已安装的软件包"
    echo "  clean                   清理包缓存"
    echo "  info                    显示软件包信息"
    echo ""
    echo "选项 / Options:"
    echo "  -f, --file FILE         从文件读取软件包列表"
    echo "  -y, --yes               自动确认"
    echo "  -q, --quiet             静默模式"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 install nginx mysql"
    echo "  $0 update --yes"
    echo "  $0 upgrade --file packages.txt"
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
    if [ "$QUIET" = false ]; then
        echo "$1"
    fi
}

# 检测包管理器
detect_package_manager() {
    log_message "检测包管理器"
    
    # 检测发行版
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO="$ID"
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/debian_version ]; then
        DISTRO="debian"
    else
        DISTRO="unknown"
    fi
    
    # 检测包管理器
    if command -v apt &> /dev/null; then
        PACKAGE_MANAGER="apt"
    elif command -v yum &> /dev/null; then
        PACKAGE_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        PACKAGE_MANAGER="dnf"
    elif command -v pacman &> /dev/null; then
        PACKAGE_MANAGER="pacman"
    elif command -v zypper &> /dev/null; then
        PACKAGE_MANAGER="zypper"
    elif command -v portage &> /dev/null; then
        PACKAGE_MANAGER="portage"
    else
        PACKAGE_MANAGER="unknown"
    fi
    
    output "${BLUE}检测到包管理器: $PACKAGE_MANAGER (发行版: $DISTRO)${NC}"
}

# 构建包管理器命令
build_package_command() {
    local action="$1"
    local packages="$2"
    local cmd=""
    
    case $PACKAGE_MANAGER in
        apt)
            case $action in
                install)
                    cmd="apt install -y $packages"
                    ;;
                update)
                    cmd="apt update"
                    ;;
                upgrade)
                    cmd="apt upgrade -y"
                    ;;
                remove)
                    cmd="apt remove -y $packages"
                    ;;
                search)
                    cmd="apt search $packages"
                    ;;
                list)
                    cmd="apt list --installed"
                    ;;
                clean)
                    cmd="apt clean && apt autoclean"
                    ;;
                info)
                    cmd="apt show $packages"
                    ;;
            esac
            ;;
        yum)
            case $action in
                install)
                    cmd="yum install -y $packages"
                    ;;
                update)
                    cmd="yum update -y"
                    ;;
                upgrade)
                    cmd="yum upgrade -y"
                    ;;
                remove)
                    cmd="yum remove -y $packages"
                    ;;
                search)
                    cmd="yum search $packages"
                    ;;
                list)
                    cmd="yum list installed"
                    ;;
                clean)
                    cmd="yum clean all"
                    ;;
                info)
                    cmd="yum info $packages"
                    ;;
            esac
            ;;
        dnf)
            case $action in
                install)
                    cmd="dnf install -y $packages"
                    ;;
                update)
                    cmd="dnf update -y"
                    ;;
                upgrade)
                    cmd="dnf upgrade -y"
                    ;;
                remove)
                    cmd="dnf remove -y $packages"
                    ;;
                search)
                    cmd="dnf search $packages"
                    ;;
                list)
                    cmd="dnf list installed"
                    ;;
                clean)
                    cmd="dnf clean all"
                    ;;
                info)
                    cmd="dnf info $packages"
                    ;;
            esac
            ;;
        pacman)
            case $action in
                install)
                    cmd="pacman -S --noconfirm $packages"
                    ;;
                update)
                    cmd="pacman -Sy"
                    ;;
                upgrade)
                    cmd="pacman -Syu --noconfirm"
                    ;;
                remove)
                    cmd="pacman -R --noconfirm $packages"
                    ;;
                search)
                    cmd="pacman -Ss $packages"
                    ;;
                list)
                    cmd="pacman -Q"
                    ;;
                clean)
                    cmd="pacman -Sc --noconfirm"
                    ;;
                info)
                    cmd="pacman -Si $packages"
                    ;;
            esac
            ;;
        zypper)
            case $action in
                install)
                    cmd="zypper install -y $packages"
                    ;;
                update)
                    cmd="zypper refresh"
                    ;;
                upgrade)
                    cmd="zypper update -y"
                    ;;
                remove)
                    cmd="zypper remove -y $packages"
                    ;;
                search)
                    cmd="zypper search $packages"
                    ;;
                list)
                    cmd="zypper packages --installed"
                    ;;
                clean)
                    cmd="zypper clean --all"
                    ;;
                info)
                    cmd="zypper info $packages"
                    ;;
            esac
            ;;
        portage)
            case $action in
                install)
                    cmd="emerge $packages"
                    ;;
                update)
                    cmd="emerge --sync"
                    ;;
                upgrade)
                    cmd="emerge -uDN @world"
                    ;;
                remove)
                    cmd="emerge --unmerge $packages"
                    ;;
                search)
                    cmd="emerge --search $packages"
                    ;;
                list)
                    cmd="qlist -I"
                    ;;
                clean)
                    cmd="emerge --depclean"
                    ;;
                info)
                    cmd="emerge --info $packages"
                    ;;
            esac
            ;;
        *)
            echo "${RED}错误: 不支持的包管理器: $PACKAGE_MANAGER${NC}"
            return 1
            ;;
    esac
    
    echo "$cmd"
}

# 执行包管理器命令
execute_package_command() {
    local action="$1"
    local packages="$2"
    
    local cmd=$(build_package_command "$action" "$packages")
    if [ $? -ne 0 ]; then
        return 1
    fi
    
    log_message "执行命令: $cmd"
    
    if [ "$AUTO_YES" = true ]; then
        eval "sudo $cmd"
    else
        eval "sudo $cmd"
    fi
    
    return $?
}

# 从文件读取软件包列表
read_packages_from_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "${RED}错误: 文件不存在: $file${NC}"
        return 1
    fi
    
    log_message "从文件读取软件包列表: $file"
    
    while IFS= read -r package; do
        # 跳过空行和注释
        if [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        
        # 去除前后空格
        package=$(echo "$package" | xargs)
        
        if [ -n "$package" ]; then
            PACKAGES+=("$package")
        fi
    done < "$file"
    
    output "从文件读取了 ${#PACKAGES[@]} 个软件包"
}

# 安装软件包
install_packages() {
    local packages="$1"
    
    output "${BLUE}安装软件包: $packages${NC}"
    
    if execute_package_command "install" "$packages"; then
        output "${GREEN}软件包安装成功${NC}"
        return 0
    else
        output "${RED}软件包安装失败${NC}"
        return 1
    fi
}

# 更新软件包列表
update_packages() {
    output "${BLUE}更新软件包列表${NC}"
    
    if execute_package_command "update" ""; then
        output "${GREEN}软件包列表更新成功${NC}"
        return 0
    else
        output "${RED}软件包列表更新失败${NC}"
        return 1
    fi
}

# 升级软件包
upgrade_packages() {
    output "${BLUE}升级软件包${NC}"
    
    if execute_package_command "upgrade" ""; then
        output "${GREEN}软件包升级成功${NC}"
        return 0
    else
        output "${RED}软件包升级失败${NC}"
        return 1
    fi
}

# 卸载软件包
remove_packages() {
    local packages="$1"
    
    output "${BLUE}卸载软件包: $packages${NC}"
    
    if execute_package_command "remove" "$packages"; then
        output "${GREEN}软件包卸载成功${NC}"
        return 0
    else
        output "${RED}软件包卸载失败${NC}"
        return 1
    fi
}

# 搜索软件包
search_packages() {
    local packages="$1"
    
    output "${BLUE}搜索软件包: $packages${NC}"
    
    if execute_package_command "search" "$packages"; then
        return 0
    else
        output "${RED}软件包搜索失败${NC}"
        return 1
    fi
}

# 列出已安装的软件包
list_packages() {
    output "${BLUE}列出已安装的软件包${NC}"
    
    if execute_package_command "list" ""; then
        return 0
    else
        output "${RED}列出软件包失败${NC}"
        return 1
    fi
}

# 清理包缓存
clean_packages() {
    output "${BLUE}清理包缓存${NC}"
    
    if execute_package_command "clean" ""; then
        output "${GREEN}包缓存清理成功${NC}"
        return 0
    else
        output "${RED}包缓存清理失败${NC}"
        return 1
    fi
}

# 显示软件包信息
show_package_info() {
    local packages="$1"
    
    output "${BLUE}显示软件包信息: $packages${NC}"
    
    if execute_package_command "info" "$packages"; then
        return 0
    else
        output "${RED}显示软件包信息失败${NC}"
        return 1
    fi
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        install|update|upgrade|remove|search|list|clean|info)
            COMMAND="$1"
            shift
            break
            ;;
        -f|--file)
            PACKAGE_FILE="$2"
            shift 2
            ;;
        -y|--yes)
            AUTO_YES=true
            shift
            ;;
        -q|--quiet)
            QUIET=true
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
            PACKAGES+=("$1")
            shift
            ;;
    esac
done

# 检查命令
if [ -z "$COMMAND" ]; then
    echo "错误: 请指定命令"
    show_help
    exit 1
fi

# 检测包管理器
detect_package_manager

if [ "$PACKAGE_MANAGER" = "unknown" ]; then
    echo "${RED}错误: 未检测到支持的包管理器${NC}"
    exit 1
fi

# 从文件读取软件包列表
if [ -n "$PACKAGE_FILE" ]; then
    read_packages_from_file "$PACKAGE_FILE"
fi

# 构建软件包字符串
PACKAGE_STRING=""
if [ ${#PACKAGES[@]} -gt 0 ]; then
    PACKAGE_STRING="${PACKAGES[*]}"
fi

# 执行命令
case $COMMAND in
    install)
        install_packages "$PACKAGE_STRING"
        ;;
    update)
        update_packages
        ;;
    upgrade)
        upgrade_packages
        ;;
    remove)
        remove_packages "$PACKAGE_STRING"
        ;;
    search)
        search_packages "$PACKAGE_STRING"
        ;;
    list)
        list_packages
        ;;
    clean)
        clean_packages
        ;;
    info)
        show_package_info "$PACKAGE_STRING"
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
