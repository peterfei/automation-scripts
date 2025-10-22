#!/bin/bash

# =============================================================================
# Docker管理脚本
# Docker Management Script
# =============================================================================
# 
# 用途/Use Case:
# - 管理Docker容器和镜像
# - 批量操作Docker资源
# - 监控Docker状态
# - 清理Docker资源
# 
# 使用方法/Usage:
# ./docker_manager.sh [command] [options]
# 
# 命令/Commands:
# ps                      列出容器
# images                  列出镜像
# run                     运行容器
# stop                    停止容器
# start                   启动容器
# restart                 重启容器
# rm                      删除容器
# rmi                     删除镜像
# pull                    拉取镜像
# build                   构建镜像
# logs                    查看日志
# exec                    执行命令
# stats                   显示统计信息
# clean                   清理资源
# 
# 选项/Options:
# -a, --all               显示所有资源
# -f, --force             强制操作
# -q, --quiet             静默模式
# -v, --verbose           详细输出
# -h, --help              显示帮助信息
# 
# 示例/Examples:
# ./docker_manager.sh ps --all
# ./docker_manager.sh run nginx --name web
# ./docker_manager.sh clean --all
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
ALL=false
FORCE=false
QUIET=false
VERBOSE=false

# 显示帮助信息
show_help() {
    echo "Docker管理脚本 / Docker Management Script"
    echo ""
    echo "用法 / Usage: $0 [命令 / command] [选项 / options]"
    echo ""
    echo "命令 / Commands:"
    echo "  ps                      列出容器"
    echo "  images                  列出镜像"
    echo "  run                     运行容器"
    echo "  stop                    停止容器"
    echo "  start                   启动容器"
    echo "  restart                 重启容器"
    echo "  rm                      删除容器"
    echo "  rmi                     删除镜像"
    echo "  pull                    拉取镜像"
    echo "  build                   构建镜像"
    echo "  logs                    查看日志"
    echo "  exec                    执行命令"
    echo "  stats                   显示统计信息"
    echo "  clean                   清理资源"
    echo ""
    echo "选项 / Options:"
    echo "  -a, --all               显示所有资源"
    echo "  -f, --force             强制操作"
    echo "  -q, --quiet             静默模式"
    echo "  -v, --verbose           详细输出"
    echo "  -h, --help              显示帮助信息"
    echo ""
    echo "示例 / Examples:"
    echo "  $0 ps --all"
    echo "  $0 run nginx --name web"
    echo "  $0 clean --all"
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

# 检查Docker是否安装
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "${RED}错误: Docker未安装或未在PATH中${NC}"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        echo "${RED}错误: Docker守护进程未运行或权限不足${NC}"
        exit 1
    fi
}

# 列出容器
list_containers() {
    output "${BLUE}列出Docker容器${NC}"
    
    if [ "$ALL" = true ]; then
        docker ps -a
    else
        docker ps
    fi
}

# 列出镜像
list_images() {
    output "${BLUE}列出Docker镜像${NC}"
    
    docker images
}

# 运行容器
run_container() {
    local image="$1"
    local name="$2"
    local ports="$3"
    local volumes="$4"
    local env_vars="$5"
    
    if [ -z "$image" ]; then
        echo "${RED}错误: 请指定镜像名称${NC}"
        return 1
    fi
    
    output "${BLUE}运行容器: $image${NC}"
    
    local cmd="docker run -d"
    
    if [ -n "$name" ]; then
        cmd="$cmd --name $name"
    fi
    
    if [ -n "$ports" ]; then
        cmd="$cmd -p $ports"
    fi
    
    if [ -n "$volumes" ]; then
        cmd="$cmd -v $volumes"
    fi
    
    if [ -n "$env_vars" ]; then
        cmd="$cmd -e $env_vars"
    fi
    
    cmd="$cmd $image"
    
    log_message "执行命令: $cmd"
    
    if eval "$cmd"; then
        output "${GREEN}容器运行成功${NC}"
        return 0
    else
        output "${RED}容器运行失败${NC}"
        return 1
    fi
}

# 停止容器
stop_container() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "${RED}错误: 请指定容器名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}停止容器: $container${NC}"
    
    if docker stop "$container"; then
        output "${GREEN}容器停止成功${NC}"
        return 0
    else
        output "${RED}容器停止失败${NC}"
        return 1
    fi
}

# 启动容器
start_container() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "${RED}错误: 请指定容器名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}启动容器: $container${NC}"
    
    if docker start "$container"; then
        output "${GREEN}容器启动成功${NC}"
        return 0
    else
        output "${RED}容器启动失败${NC}"
        return 1
    fi
}

# 重启容器
restart_container() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "${RED}错误: 请指定容器名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}重启容器: $container${NC}"
    
    if docker restart "$container"; then
        output "${GREEN}容器重启成功${NC}"
        return 0
    else
        output "${RED}容器重启失败${NC}"
        return 1
    fi
}

# 删除容器
remove_container() {
    local container="$1"
    
    if [ -z "$container" ]; then
        echo "${RED}错误: 请指定容器名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}删除容器: $container${NC}"
    
    local cmd="docker rm"
    if [ "$FORCE" = true ]; then
        cmd="$cmd -f"
    fi
    
    if eval "$cmd $container"; then
        output "${GREEN}容器删除成功${NC}"
        return 0
    else
        output "${RED}容器删除失败${NC}"
        return 1
    fi
}

# 删除镜像
remove_image() {
    local image="$1"
    
    if [ -z "$image" ]; then
        echo "${RED}错误: 请指定镜像名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}删除镜像: $image${NC}"
    
    local cmd="docker rmi"
    if [ "$FORCE" = true ]; then
        cmd="$cmd -f"
    fi
    
    if eval "$cmd $image"; then
        output "${GREEN}镜像删除成功${NC}"
        return 0
    else
        output "${RED}镜像删除失败${NC}"
        return 1
    fi
}

# 拉取镜像
pull_image() {
    local image="$1"
    
    if [ -z "$image" ]; then
        echo "${RED}错误: 请指定镜像名称${NC}"
        return 1
    fi
    
    output "${BLUE}拉取镜像: $image${NC}"
    
    if docker pull "$image"; then
        output "${GREEN}镜像拉取成功${NC}"
        return 0
    else
        output "${RED}镜像拉取失败${NC}"
        return 1
    fi
}

# 构建镜像
build_image() {
    local dockerfile="$1"
    local tag="$2"
    local context="$3"
    
    if [ -z "$dockerfile" ]; then
        dockerfile="Dockerfile"
    fi
    
    if [ -z "$context" ]; then
        context="."
    fi
    
    output "${BLUE}构建镜像: $tag${NC}"
    
    local cmd="docker build -f $dockerfile"
    if [ -n "$tag" ]; then
        cmd="$cmd -t $tag"
    fi
    cmd="$cmd $context"
    
    log_message "执行命令: $cmd"
    
    if eval "$cmd"; then
        output "${GREEN}镜像构建成功${NC}"
        return 0
    else
        output "${RED}镜像构建失败${NC}"
        return 1
    fi
}

# 查看日志
view_logs() {
    local container="$1"
    local lines="$2"
    
    if [ -z "$container" ]; then
        echo "${RED}错误: 请指定容器名称或ID${NC}"
        return 1
    fi
    
    output "${BLUE}查看容器日志: $container${NC}"
    
    local cmd="docker logs"
    if [ -n "$lines" ]; then
        cmd="$cmd --tail $lines"
    fi
    cmd="$cmd $container"
    
    if eval "$cmd"; then
        return 0
    else
        output "${RED}查看日志失败${NC}"
        return 1
    fi
}

# 执行命令
execute_command() {
    local container="$1"
    local command="$2"
    
    if [ -z "$container" ] || [ -z "$command" ]; then
        echo "${RED}错误: 请指定容器名称或ID和命令${NC}"
        return 1
    fi
    
    output "${BLUE}在容器中执行命令: $container${NC}"
    
    if docker exec -it "$container" $command; then
        return 0
    else
        output "${RED}命令执行失败${NC}"
        return 1
    fi
}

# 显示统计信息
show_stats() {
    output "${BLUE}Docker统计信息${NC}"
    
    docker stats --no-stream
}

# 清理资源
clean_resources() {
    output "${BLUE}清理Docker资源${NC}"
    
    local cleaned=0
    
    # 清理停止的容器
    if [ "$ALL" = true ]; then
        output "清理所有停止的容器..."
        local stopped_containers=$(docker ps -a -q -f status=exited)
        if [ -n "$stopped_containers" ]; then
            docker rm $stopped_containers
            cleaned=$((cleaned + 1))
        fi
    fi
    
    # 清理悬空镜像
    output "清理悬空镜像..."
    local dangling_images=$(docker images -q -f dangling=true)
    if [ -n "$dangling_images" ]; then
        docker rmi $dangling_images
        cleaned=$((cleaned + 1))
    fi
    
    # 清理未使用的卷
    if [ "$ALL" = true ]; then
        output "清理未使用的卷..."
        docker volume prune -f
        cleaned=$((cleaned + 1))
    fi
    
    # 清理未使用的网络
    if [ "$ALL" = true ]; then
        output "清理未使用的网络..."
        docker network prune -f
        cleaned=$((cleaned + 1))
    fi
    
    # 清理构建缓存
    if [ "$ALL" = true ]; then
        output "清理构建缓存..."
        docker builder prune -f
        cleaned=$((cleaned + 1))
    fi
    
    output "${GREEN}清理完成，清理了 $cleaned 类资源${NC}"
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        ps|images|run|stop|start|restart|rm|rmi|pull|build|logs|exec|stats|clean)
            COMMAND="$1"
            shift
            break
            ;;
        -a|--all)
            ALL=true
            shift
            ;;
        -f|--force)
            FORCE=true
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

# 检查Docker
check_docker

# 执行命令
case $COMMAND in
    ps)
        list_containers
        ;;
    images)
        list_images
        ;;
    run)
        # 解析运行参数
        local image=""
        local name=""
        local ports=""
        local volumes=""
        local env_vars=""
        
        while [[ $# -gt 0 ]]; do
            case $1 in
                --name)
                    name="$2"
                    shift 2
                    ;;
                --ports|-p)
                    ports="$2"
                    shift 2
                    ;;
                --volumes|-v)
                    volumes="$2"
                    shift 2
                    ;;
                --env|-e)
                    env_vars="$2"
                    shift 2
                    ;;
                *)
                    if [ -z "$image" ]; then
                        image="$1"
                    fi
                    shift
                    ;;
            esac
        done
        
        run_container "$image" "$name" "$ports" "$volumes" "$env_vars"
        ;;
    stop)
        stop_container "$1"
        ;;
    start)
        start_container "$1"
        ;;
    restart)
        restart_container "$1"
        ;;
    rm)
        remove_container "$1"
        ;;
    rmi)
        remove_image "$1"
        ;;
    pull)
        pull_image "$1"
        ;;
    build)
        build_image "$1" "$2" "$3"
        ;;
    logs)
        view_logs "$1" "$2"
        ;;
    exec)
        execute_command "$1" "$2"
        ;;
    stats)
        show_stats
        ;;
    clean)
        clean_resources
        ;;
    *)
        echo "未知命令: $COMMAND"
        show_help
        exit 1
        ;;
esac
