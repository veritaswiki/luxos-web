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
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [$level] $*" | tee -a "$LOGFILE"
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
    fi
    
    # 检查必要的程序
    local required_commands=("docker" "docker-compose" "curl" "openssl")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR" "缺少必要的程序: $cmd"
            if [[ "$cmd" == "docker" || "$cmd" == "docker-compose" ]]; then
                if [[ "$(uname)" == "Linux" ]]; then
                    log "INFO" "检测到缺少Docker..."
                    if prompt_user "是否要安装Docker？" "y"; then
                        # 检查是否为root用户
                        if [ "$EUID" -ne 0 ]; then
                            log "ERROR" "安装 Docker 需要root权限，请使用sudo运行此脚本"
                            exit 1
                        fi
                        # 运行Docker安装脚本
                        bash install_docker.sh
                        # 检查Docker安装结果
                        if ! command -v docker >/dev/null 2>&1; then
                            log "ERROR" "Docker安装失败"
                            exit 1
                        fi
                        log "INFO" "Docker安装成功"
                    else
                        log "ERROR" "Docker是必需的，无法继续安装"
                        exit 1
                    fi
                else
                    log "ERROR" "请手动安装 Docker"
                    exit 1
                fi
            else
                log "ERROR" "请安装必要的程序: $cmd"
                exit 1
            fi
        fi
    done
    
    # 检查 Docker 服务状态
    if ! docker info >/dev/null 2>&1; then
        log "ERROR" "Docker 服务未运行"
        if [[ "$(uname)" == "Linux" ]]; then
            log "INFO" "尝试启动 Docker 服务..."
            systemctl start docker
            if ! docker info >/dev/null 2>&1; then
                log "ERROR" "无法启动 Docker 服务"
                exit 1
            fi
        else
            exit 1
        fi
    fi
    
    log "INFO" "系统要求检查通过"
}

# 函数：用户交互
prompt_user() {
    local question=$1
    local default=${2:-"y"}
    
    while true; do
        read -p "$question [y/n] ($default): " answer
        case ${answer:-$default} in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "请输入 y 或 n";;
        esac
    done
}

# 函数：显示菜单并获取选择
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
            echo "${options[$((choice-1))]}"
            break
        fi
        echo -e "${RED}无效的选择，请重试${NC}"
    done
}

# 函数：生成安全的随机密码
generate_secure_password() {
    local length=${1:-16}
    openssl rand -base64 48 | tr -dc 'a-zA-Z0-9' | head -c "$length"
}

# 函数：生成 Docker Compose 配置
generate_docker_compose() {
    log "INFO" "生成 Docker Compose 配置..."
    
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  pingora:
    build:
      context: ./pingora
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    networks:
      - app_network
    depends_on:
      - caddy
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  caddy:
    image: caddy:2-alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./caddy/Caddyfile:/etc/caddy/Caddyfile
      - ./www:/var/www/html
      - caddy_data:/data
      - caddy_config:/config
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:80"]
      interval: 30s
      timeout: 10s
      retries: 3

  php:
    build:
      context: ./php
      dockerfile: Dockerfile
      args:
        PHP_VERSION: ${PHP_VERSION}
    volumes:
      - ./www:/var/www/html
      - ./php/custom.ini:/usr/local/etc/php/conf.d/custom.ini
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "php-fpm", "-t"]
      interval: 30s
      timeout: 10s
      retries: 3

  postgres:
    image: postgres:${DB_VERSION:-15}-alpine
    environment:
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_MAX_CONNECTIONS: 100
      POSTGRES_SHARED_BUFFERS: 256MB
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:5432:5432"
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${DB_USER} -d ${DB_NAME}"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:${REDIS_VERSION:-7}-alpine
    command: redis-server --requirepass ${REDIS_PASSWORD} --maxmemory 384mb --maxmemory-policy allkeys-lru --appendonly yes --appendfsync everysec
    ports:
      - "127.0.0.1:6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app_network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  app_network:
    driver: bridge

volumes:
  caddy_data:
  caddy_config:
  postgres_data:
  redis_data:
EOF
}

# 函数：生成 PHP Dockerfile
generate_php_dockerfile() {
    log "INFO" "生成 PHP Dockerfile..."
    
    mkdir -p php
    cat > php/Dockerfile << 'EOF'
FROM php:${PHP_VERSION}-fpm

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    git \
    && rm -rf /var/lib/apt/lists/*

# 安装 PHP 扩展
RUN docker-php-ext-install \
    pdo_pgsql \
    pgsql \
    zip \
    opcache

# 安装 Redis 扩展
RUN pecl install redis && docker-php-ext-enable redis

# 配置 OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /var/www/html
EOF
}

# 函数：生成 Pingora Dockerfile
generate_pingora_dockerfile() {
    log "INFO" "生成 Pingora Dockerfile..."
    
    mkdir -p pingora
    cat > pingora/Dockerfile << 'EOF'
FROM rust:latest as builder

WORKDIR /usr/src/pingora
RUN git clone https://github.com/cloudflare/pingora.git .
RUN cargo build --release

FROM debian:bullseye-slim
COPY --from=builder /usr/src/pingora/target/release/pingora /usr/local/bin/
EXPOSE 8080
CMD ["pingora"]
EOF
}

# 函数：生成 Caddy 配置
generate_caddy_config() {
    log "INFO" "生成 Caddy 配置..."
    
    mkdir -p caddy
    cat > caddy/Caddyfile << 'EOF'
{
    email admin@example.com
}

:80 {
    root * /var/www/html
    php_fastcgi php:9000
    file_server
    encode gzip
    log {
        output file /var/log/caddy/access.log
        format json
    }
}
EOF
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

# 主函数
main() {
    log "INFO" "开始安装 Luxos Web..."
    
    # 检查系统要求
    check_requirements
    
    # 创建必要的目录
    log "INFO" "创建项目目录..."
    mkdir -p www config/{nginx,php,templates} data/{mysql,redis} logs
    
    # 配置选择
    PHP_VERSION=$(show_menu "选择 PHP 版本" "8.2" "8.1" "8.0" "7.4")
    DB_TYPE=$(show_menu "选择数据库类型" "PostgreSQL" "MySQL")
    CACHE_SYSTEM=$(show_menu "选择缓存系统" "Redis" "Memcached" "无")
    
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
    generate_docker_compose
    generate_php_dockerfile
    generate_pingora_dockerfile
    generate_caddy_config
    
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

# 执行主程序
main "$@" 