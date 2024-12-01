#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# 检查必要的目录和文件
check_structure() {
    local missing=0
    
    # 检查必要的目录
    directories=(
        "www"
        "php"
        "php/conf.d"
        "caddy"
        "caddy/sites"
        "pingora"
        "config"
        "config/templates"
        "scripts"
        "backup"
        "logs"
    )
    
    echo -e "${BLUE}检查目录结构...${NC}"
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            echo -e "${RED}缺少目录: $dir${NC}"
            mkdir -p "$dir"
            echo -e "${GREEN}已创建目录: $dir${NC}"
            missing=1
        fi
    done
    
    # 检查必要的文件
    files=(
        "docker-compose.yml"
        ".env"
        "php/Dockerfile"
        "pingora/Dockerfile"
        "caddy/Caddyfile"
        "config/templates/php-fpm.conf.template"
        "config/templates/sysctl.conf.template"
        "config/php-extensions.json"
        "scripts/generate_docker_compose.sh"
        "scripts/add_site.sh"
        "README.md"
    )
    
    echo -e "${BLUE}检查必要文件...${NC}"
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            echo -e "${RED}缺少文件: $file${NC}"
            missing=1
        fi
    done
    
    # 检查文件权限
    echo -e "${BLUE}检查文件权限...${NC}"
    if [ ! -x "scripts/add_site.sh" ]; then
        echo -e "${RED}add_site.sh 缺少执行权限${NC}"
        chmod +x scripts/add_site.sh
        echo -e "${GREEN}已添加执行权限${NC}"
    fi
    
    if [ ! -x "scripts/generate_docker_compose.sh" ]; then
        echo -e "${RED}generate_docker_compose.sh 缺少执行权限${NC}"
        chmod +x scripts/generate_docker_compose.sh
        echo -e "${GREEN}已添加执行权限${NC}"
    fi
    
    # 检查 www 目录权限
    if [ -d "www" ]; then
        current_perm=$(stat -c %a www)
        if [ "$current_perm" != "755" ]; then
            echo -e "${RED}www 目录权限不正确${NC}"
            chmod 755 www
            echo -e "${GREEN}已修正 www 目录权限${NC}"
        fi
    fi
    
    return $missing
}

# 检查配置文件完整性
check_configs() {
    local error=0
    
    echo -e "${BLUE}检查配置文件完整性...${NC}"
    
    # 检查 .env 文件必要变量
    if [ -f ".env" ]; then
        required_vars=(
            "POSTGRES_USER"
            "POSTGRES_PASSWORD"
            "POSTGRES_DB"
            "PHP_VERSION"
        )
        
        for var in "${required_vars[@]}"; do
            if ! grep -q "^$var=" .env; then
                echo -e "${RED}.env 文件缺少 $var 配置${NC}"
                error=1
            fi
        done
    fi
    
    # 检查 docker-compose.yml 必要服务
    if [ -f "docker-compose.yml" ]; then
        required_services=(
            "pingora:"
            "caddy:"
            "php:"
            "postgres:"
            "redis:"
        )
        
        for service in "${required_services[@]}"; do
            if ! grep -q "^[[:space:]]*$service" docker-compose.yml; then
                echo -e "${RED}docker-compose.yml 缺少 $service 服务${NC}"
                error=1
            fi
        done
    fi
    
    return $error
}

# 检查网络连接
check_network() {
    echo -e "${BLUE}检查网络连接...${NC}"
    
    if ! docker network ls | grep -q "app_network"; then
        echo -e "${RED}缺少 Docker 网络: app_network${NC}"
        docker network create app_network
        echo -e "${GREEN}已创建 Docker 网络${NC}"
    fi
}

# 主函数
main() {
    echo -e "${BLUE}开始系统检查...${NC}"
    
    local has_error=0
    
    # 检查目录结构
    check_structure
    has_error=$((has_error + $?))
    
    # 检查配置文件
    check_configs
    has_error=$((has_error + $?))
    
    # 检查网络
    check_network
    has_error=$((has_error + $?))
    
    if [ $has_error -eq 0 ]; then
        echo -e "${GREEN}系统检查完成，未发现问题${NC}"
    else
        echo -e "${RED}系统检查完成，发现 $has_error 个问题需要处理${NC}"
    fi
}

main 