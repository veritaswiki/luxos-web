#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PLAIN='\033[0m'

# 检查参数
if [ $# -lt 1 ]; then
    echo -e "${RED}使用方法: $0 [enable|disable] [domain]${PLAIN}"
    exit 1
fi

ACTION=$1
DOMAIN=$2

# 如果没有提供域名，显示可用的网站列表
if [ -z "$DOMAIN" ]; then
    echo -e "${BLUE}可用的网站：${PLAIN}"
    ls -1 caddy/sites/ | grep "\.Caddyfile$" | sed 's/\.Caddyfile$//'
    echo
    read -p "请输入要操作的域名: " DOMAIN
fi

# 检查域名是否存在
if [ ! -f "caddy/sites/$DOMAIN.Caddyfile" ]; then
    echo -e "${RED}错误: 网站 $DOMAIN 不存在${PLAIN}"
    exit 1
fi

# 启用网站
enable_site() {
    local domain=$1
    
    # 检查网站配置
    if [ -f "caddy/sites/$domain.Caddyfile.disabled" ]; then
        mv "caddy/sites/$domain.Caddyfile.disabled" "caddy/sites/$domain.Caddyfile"
        echo -e "${GREEN}网站 $domain 已启用${PLAIN}"
        
        # 重启 Caddy 服务
        docker-compose restart caddy
    else
        echo -e "${YELLOW}网站 $domain 已经是启用状态${PLAIN}"
    fi
}

# 停用网站
disable_site() {
    local domain=$1
    
    # 检查网站配置
    if [ -f "caddy/sites/$domain.Caddyfile" ]; then
        mv "caddy/sites/$domain.Caddyfile" "caddy/sites/$domain.Caddyfile.disabled"
        echo -e "${GREEN}网站 $domain 已停用${PLAIN}"
        
        # 重启 Caddy 服务
        docker-compose restart caddy
    else
        echo -e "${YELLOW}网站 $domain 已经是停用状态${PLAIN}"
    fi
}

# 执行操作
case "$ACTION" in
    "enable")
        enable_site "$DOMAIN"
        ;;
    "disable")
        disable_site "$DOMAIN"
        ;;
    *)
        echo -e "${RED}错误: 无效的操作，请使用 enable 或 disable${PLAIN}"
        exit 1
        ;;
esac 