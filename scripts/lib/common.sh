#!/bin/bash

# 严格模式
set -euo pipefail
IFS=$'\n\t'

# 颜色定义
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export BLUE='\033[0;34m'
export NC='\033[0m'

# 日志相关
export LOG_DIR="logs"
export MAIN_LOG="$LOG_DIR/system.log"
mkdir -p "$LOG_DIR"

# 函数：日志记录
log() {
    local level=$1
    shift
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [${level}] $*" | tee -a "$MAIN_LOG"
}

# 函数：错误处理
error_handler() {
    local line_no=$1
    local error_code=$2
    local script_name=$3
    log "ERROR" "错误发生在 $script_name 的第 $line_no 行，错误代码: $error_code"
    exit 1
}

# 函数：检查必要的命令
check_command() {
    local cmd=$1
    if ! command -v "$cmd" >/dev/null 2>&1; then
        log "ERROR" "命令 '$cmd' 未找到"
        return 1
    fi
}

# 函数：显示菜单
show_menu() {
    local title=$1
    shift
    local options=("$@")
    
    echo -e "${BLUE}$title${NC}"
    for i in "${!options[@]}"; do
        echo "$((i+1)). ${options[i]}"
    done
    
    local choice
    while true; do
        read -p "请选择 [1-${#options[@]}]: " choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#options[@]}" ]; then
            break
        fi
        echo -e "${RED}无效的选择，请重试${NC}"
    done
    
    echo "$choice"
}

# 函数：生成安全的随机密码
generate_secure_password() {
    local length=${1:-16}
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# 函数：检查目录权限
check_directory_permissions() {
    local dir=$1
    local required_perms=${2:-755}
    
    if [ ! -d "$dir" ]; then
        log "ERROR" "目录 $dir 不存在"
        return 1
    fi
    
    local current_perms=$(stat -f "%Lp" "$dir")
    if [ "$current_perms" != "$required_perms" ]; then
        log "WARN" "目录 $dir 权限不正确 (当前: $current_perms, 需要: $required_perms)"
        return 1
    fi
}

# 函数：备份文件
backup_file() {
    local file=$1
    local backup_dir=${2:-"backups"}
    local timestamp=$(date +%Y%m%d_%H%M%S)
    
    mkdir -p "$backup_dir"
    if [ -f "$file" ]; then
        cp "$file" "${backup_dir}/$(basename "$file").${timestamp}.bak"
        log "INFO" "已备份文件 $file"
    else
        log "WARN" "文件 $file 不存在，跳过备份"
    fi
}

# 函数：检查系统资源
check_system_resources() {
    local min_memory=${1:-2048} # 最小内存要求(MB)
    local min_disk=${2:-10240}  # 最小磁盘空间要求(MB)
    
    # 检查内存
    local total_memory=$(sysctl hw.memsize | awk '{print $2/1024/1024}' | cut -d. -f1)
    if [ "$total_memory" -lt "$min_memory" ]; then
        log "ERROR" "内存不足 (当前: ${total_memory}MB, 需要: ${min_memory}MB)"
        return 1
    fi
    
    # 检查磁盘空间
    local free_disk=$(df -m . | awk 'NR==2 {print $4}')
    if [ "$free_disk" -lt "$min_disk" ]; then
        log "ERROR" "磁盘空间不足 (当前: ${free_disk}MB, 需要: ${min_disk}MB)"
        return 1
    fi
    
    log "INFO" "系统资源检查通过"
    return 0
}

# 函数：检查网络连接
check_network() {
    local host=${1:-"8.8.8.8"}
    if ping -c 1 "$host" >/dev/null 2>&1; then
        log "INFO" "网络连接正常"
        return 0
    else
        log "ERROR" "网络连接失败"
        return 1
    fi
}

# 函数：检查Docker服务
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        log "ERROR" "Docker 服务未运行"
        return 1
    fi
    log "INFO" "Docker 服务运行正常"
    return 0
}

# 函数：检查容器健康状态
check_container_health() {
    local container=$1
    local status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null)
    
    case "$status" in
        "healthy")
            log "INFO" "容器 $container 状态正常"
            return 0
            ;;
        "unhealthy")
            log "ERROR" "容器 $container 状态异常"
            return 1
            ;;
        *)
            log "WARN" "容器 $container 状态未知"
            return 2
            ;;
    esac
}

# 函数：检查端口占用
check_port() {
    local port=$1
    if lsof -i ":$port" >/dev/null 2>&1; then
        log "WARN" "端口 $port 已被占用"
        return 1
    fi
    return 0
}

# 函数：等待服务就绪
wait_for_service() {
    local host=$1
    local port=$2
    local timeout=${3:-30}
    local start_time=$(date +%s)
    
    while true; do
        if nc -z "$host" "$port" >/dev/null 2>&1; then
            log "INFO" "服务 $host:$port 已就绪"
            return 0
        fi
        
        if [ $(($(date +%s) - start_time)) -ge "$timeout" ]; then
            log "ERROR" "等待服务 $host:$port 超时"
            return 1
        fi
        
        sleep 1
    done
}

# 函数：清理旧日志
cleanup_logs() {
    local log_dir=${1:-"$LOG_DIR"}
    local days=${2:-7}
    
    find "$log_dir" -type f -name "*.log" -mtime +"$days" -exec rm {} \;
    log "INFO" "已清理 $days 天前的日志文件"
}

# 函数：检查SSL证书
check_ssl_cert() {
    local domain=$1
    local cert_file="/etc/letsencrypt/live/$domain/fullchain.pem"
    
    if [ ! -f "$cert_file" ]; then
        log "ERROR" "SSL证书文件不存在: $cert_file"
        return 1
    fi
    
    local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
    local expiry_epoch=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s)
    local current_epoch=$(date +%s)
    local days_left=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    if [ "$days_left" -lt 30 ]; then
        log "WARN" "SSL证书将在 $days_left 天后过期"
        return 1
    fi
    
    log "INFO" "SSL证书检查通过，剩余 $days_left 天"
    return 0
}

# 导出所有函数
export -f log
export -f error_handler
export -f check_command
export -f show_menu
export -f generate_secure_password
export -f check_directory_permissions
export -f backup_file
export -f check_system_resources
export -f check_network
export -f check_docker
export -f check_container_health
export -f check_port
export -f wait_for_service
export -f cleanup_logs
export -f check_ssl_cert 