#!/bin/bash

# 严格模式
set -euo pipefail
IFS=$'\n\t'

# 日志文件
LOGFILE="install.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 默认值
DEFAULT_PHP_VERSION="8.2"
DEFAULT_DB_VERSION="15"
DEFAULT_REDIS_VERSION="7"
DEFAULT_MEMORY="2G"

# 函数：日志记录
log() {
    local level=$1
    shift
    echo -e "${TIMESTAMP} [$level] $*" | tee -a "$LOGFILE"
}

# 函数：错误处理
error_handler() {
    local line_no=$1
    local error_code=$2
    log "ERROR" "脚本在第 $line_no 行发生错误，错误代码: $error_code"
    exit 1
}

trap 'error_handler ${LINENO} $?' ERR

# 函数：检查系统要求
check_requirements() {
    log "INFO" "检查系统要求..."
    
    # 检查操作系统
    if [[ "$(uname)" != "Linux" && "$(uname)" != "Darwin" ]]; then
        log "ERROR" "不支持的操作系统: $(uname)"
        exit 1
    }
    
    # 检查必要的程序
    local required_commands=("docker" "docker-compose" "curl" "openssl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "缺少必要的程序: $cmd"
            exit 1
        fi
    done
    
    # 检查 Docker 服务状态
    if ! docker info >/dev/null 2>&1; then
        log "ERROR" "Docker 服务未运行"
        exit 1
    }
    
    log "INFO" "系统要求检查通过"
}

# 函数：显示菜单并获取选择
show_menu() {
    local prompt=$1
    shift
    local options=("$@")
    echo -e "${BLUE}$prompt${NC}"
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
    openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16
}

# 函数：安装PHP扩展
install_php_extensions() {
    log "INFO" "开始安装 PHP 扩展..."
    local extensions=("$@")
    for ext in "${extensions[@]}"; do
        log "INFO" "安装扩展: $ext"
        case $ext in
            "redis")
                docker-php-ext-install redis || log "ERROR" "安装 redis 扩展失败"
                ;;
            "memcached")
                docker-php-ext-install memcached || log "ERROR" "安装 memcached 扩展失败"
                ;;
            "mongodb")
                docker-php-ext-install mongodb || log "ERROR" "安装 mongodb 扩展失败"
                ;;
            *)
                docker-php-ext-install "$ext" || log "ERROR" "安装 $ext 扩展失败"
                ;;
        esac
    done
    log "INFO" "PHP 扩展安装完成"
}

# 主程序开始
main() {
    log "INFO" "开始安装 Luxos Web..."
    
    # 检查系统要求
    check_requirements
    
    # 创建必要的目录
    log "INFO" "创建项目目录..."
    mkdir -p www config/{nginx,php,templates} data/{mysql,redis} logs
    
    # 配置选择
    PHP_VERSION=$(show_menu "选择 PHP 版本:" "8.2" "8.1" "8.0" "7.4")
    DB_TYPE=$(show_menu "选择数据库类型:" "PostgreSQL" "MySQL")
    CACHE_SYSTEM=$(show_menu "选择缓存系统:" "Redis" "Memcached" "无")
    
    # 生成随机密码
    DB_PASSWORD=$(generate_secure_password)
    REDIS_PASSWORD=$(generate_secure_password)
    
    # 创建环境变量文件
    log "INFO" "创建环境配置文件..."
    cat > .env << EOF
PHP_VERSION=$PHP_VERSION
DB_TYPE=$DB_TYPE
DB_USER=appuser
DB_PASSWORD=$DB_PASSWORD
DB_NAME=appdb
REDIS_PASSWORD=$REDIS_PASSWORD
EOF
    
    # 生成配置文件
    log "INFO" "生成配置文件..."
    ./scripts/generate_docker_compose.sh
    
    # 启动服务
    log "INFO" "启动服务..."
    docker-compose up -d
    
    # 检查服务状态
    log "INFO" "检查服务状态..."
    sleep 5
    if ! docker-compose ps | grep -q "Up"; then
        log "ERROR" "服务启动失败"
        docker-compose logs
        exit 1
    fi
    
    # 安装完成
    log "INFO" "安装完成"
    echo -e "${GREEN}安装成功！${NC}"
    echo "=============================="
    echo -e "安装信息："
    echo -e "PHP 版本: ${GREEN}$PHP_VERSION${NC}"
    echo -e "数据库类型: ${GREEN}$DB_TYPE${NC}"
    echo -e "缓存系统: ${GREEN}$CACHE_SYSTEM${NC}"
    echo -e "数据库密码: ${GREEN}$DB_PASSWORD${NC}"
    echo -e "Redis 密码: ${GREEN}$REDIS_PASSWORD${NC}"
    echo "=============================="
    
    # 显示下一步建议
    show_recommendations
}

# 函数：显示建议
show_recommendations() {
    echo -e "${YELLOW}系统优化建议：${NC}"
    echo "1. 系统限制优化："
    echo "   - 调整文件描述符限制"
    echo "   - 优化内核参数"
    echo "2. 安全加固："
    echo "   - 配置防火墙规则"
    echo "   - 启用 fail2ban"
    echo "   - 定期更新系统"
    echo "3. 性能优化："
    echo "   - 启用 PHP OPcache"
    echo "   - 配置合适的 PHP-FPM 进程数"
    echo "4. 监控建议："
    echo "   - 设置资源监控"
    echo "   - 配置日志轮转"
    echo "   - 设置告警机制"
}

# 执行主程序
main "$@" 