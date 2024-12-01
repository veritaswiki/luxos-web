#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 默认值
DEFAULT_ROOT_DIR="./www"
DEFAULT_PHP_VERSION="8.2"

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
    read -p "请选择 [1-${#options[@]}]: " choice
    echo "$choice"
}

# 函数：验证域名格式
validate_domain() {
    local domain=$1
    if [[ ! $domain =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
        echo -e "${RED}无效的域名格式${NC}"
        return 1
    fi
    return 0
}

# 函数：创建网站目录结构
create_site_structure() {
    local site_root=$1
    local site_type=$2
    
    mkdir -p "$site_root"/{public,logs,config,backup}
    
    case $site_type in
        "static")
            mkdir -p "$site_root/public"
            ;;
        "php")
            mkdir -p "$site_root"/{public,cache,sessions,uploads}
            ;;
        "laravel")
            composer create-project laravel/laravel "$site_root"
            ;;
        "wordpress")
            wget https://wordpress.org/latest.tar.gz -P "$site_root"
            tar -xzf "$site_root/latest.tar.gz" -C "$site_root/public" --strip-components=1
            rm "$site_root/latest.tar.gz"
            ;;
    esac
    
    chmod -R 755 "$site_root"
    chown -R www-data:www-data "$site_root"
}

# 函数：生成数据库配置
generate_db_config() {
    local site_root=$1
    local db_type=$2
    local db_name=$3
    local db_user=$4
    local db_pass=$5
    
    cat > "$site_root/config/database.php" << EOF
<?php
return [
    'type' => '$db_type',
    'host' => '${db_type,,}',
    'database' => '$db_name',
    'username' => '$db_user',
    'password' => '$db_pass',
];
EOF
}

# 函数：生成 Caddy 配置
generate_caddy_config() {
    local domain=$1
    local site_root=$2
    local site_type=$3
    local config_file="caddy/sites/$domain.Caddyfile"
    
    mkdir -p caddy/sites
    
    cat > "$config_file" << EOF
$domain {
    root * $site_root/public
    encode gzip
    tls {
        protocols tls1.2 tls1.3
        curves x25519
        alpn http/1.1 h2
    }
    
    @static {
        file
        path *.ico *.css *.js *.gif *.jpg *.jpeg *.png *.svg *.woff *.woff2
    }
    
    handle @static {
        file_server
    }
EOF
    
    case $site_type in
        "static")
            cat >> "$config_file" << EOF
    
    handle {
        file_server
    }
EOF
            ;;
        "php"|"wordpress"|"laravel")
            cat >> "$config_file" << EOF
    
    php_fastcgi php:9000 {
        resolve_root_symlink
        try_files {path} {path}/index.php
    }
    
    handle {
        try_files {path} {path}/ /index.php?{query}
    }
EOF
            ;;
    esac
    
    echo "}" >> "$config_file"
    
    # 更新主 Caddyfile
    echo "import sites/*.Caddyfile" >> caddy/Caddyfile
}

# 主菜单
echo -e "${BLUE}添加新网站${NC}"
echo "================="

# 1. 输入域名
while true; do
    read -p "请输入域名: " domain
    if validate_domain "$domain"; then
        break
    fi
done

# 2. 选择网站类型
SITE_TYPES=("静态网站" "PHP 网站" "Laravel 项目" "WordPress 站点")
site_type_choice=$(show_menu "选择网站类型:" "${SITE_TYPES[@]}")
case $site_type_choice in
    1) site_type="static" ;;
    2) site_type="php" ;;
    3) site_type="laravel" ;;
    4) site_type="wordpress" ;;
esac

# 3. 设置网站根目录
read -p "网站根目录 (默认: $DEFAULT_ROOT_DIR/$domain): " site_root
site_root=${site_root:-"$DEFAULT_ROOT_DIR/$domain"}

# 4. 选择 PHP 版本（如果需要）
if [[ "$site_type" != "static" ]]; then
    PHP_VERSIONS=("8.2" "8.1" "8.0" "7.4")
    php_choice=$(show_menu "选择 PHP 版本:" "${PHP_VERSIONS[@]}")
    php_version=${PHP_VERSIONS[$((php_choice-1))]}
fi

# 5. 数据库配置
if [[ "$site_type" != "static" ]]; then
    echo -e "${BLUE}数据库配置${NC}"
    DB_TYPES=("MySQL" "PostgreSQL" "无")
    db_choice=$(show_menu "选择数据库类型:" "${DB_TYPES[@]}")
    
    if [[ $db_choice != 3 ]]; then
        read -p "数据库名 (默认: ${domain//./_}_db): " db_name
        db_name=${db_name:-"${domain//./_}_db"}
        
        read -p "数据库用户名 (默认: ${domain//./_}_user): " db_user
        db_user=${db_user:-"${domain//./_}_user"}
        
        read -s -p "数据库密码: " db_pass
        echo
        db_pass=${db_pass:-$(openssl rand -base64 12)}
    fi
fi

# 6. 缓存配置
if [[ "$site_type" != "static" ]]; then
    CACHE_TYPES=("Redis" "Memcached" "无")
    cache_choice=$(show_menu "选择缓存系统:" "${CACHE_TYPES[@]}")
fi

# 7. SSL 配置
SSL_TYPES=("自动 (Let's Encrypt)" "自签名" "无 SSL")
ssl_choice=$(show_menu "选择 SSL 配置:" "${SSL_TYPES[@]}")

# 开始配置
echo -e "${BLUE}开始配置网站...${NC}"

# 1. 创建目录结构
echo "创建目录结构..."
create_site_structure "$site_root" "$site_type"

# 2. 配置数据库
if [[ "$site_type" != "static" && $db_choice != 3 ]]; then
    echo "配置数据库..."
    generate_db_config "$site_root" "${DB_TYPES[$((db_choice-1))]}" "$db_name" "$db_user" "$db_pass"
fi

# 3. 生成 Caddy 配置
echo "生成 Web 服务器配置..."
generate_caddy_config "$domain" "$site_root" "$site_type"

# 4. 更新 Docker Compose 配置
echo "更新 Docker 配置..."
./scripts/generate_docker_compose.sh "$php_version" "${DB_TYPES[$((db_choice-1))]}" "$db_version" "${CACHE_TYPES[$((cache_choice-1))]}"

# 5. 重启服务
echo "重启服务..."
docker-compose restart caddy

echo -e "${GREEN}网站配置完成！${NC}"
echo "=============================="
echo -e "网站信息："
echo -e "域名: ${GREEN}$domain${NC}"
echo -e "类型: ${GREEN}${SITE_TYPES[$((site_type_choice-1))]}${NC}"
echo -e "根目录: ${GREEN}$site_root${NC}"
if [[ "$site_type" != "static" ]]; then
    echo -e "PHP 版本: ${GREEN}$php_version${NC}"
    if [[ $db_choice != 3 ]]; then
        echo -e "数据库类型: ${GREEN}${DB_TYPES[$((db_choice-1))]}${NC}"
        echo -e "数据库名: ${GREEN}$db_name${NC}"
        echo -e "数据库用户: ${GREEN}$db_user${NC}"
        echo -e "数据库密码: ${GREEN}$db_pass${NC}"
    fi
fi
echo "=============================="

# 显示下一步操作建议
echo -e "${YELLOW}下一步操作建议：${NC}"
echo "1. 配置 DNS 记录指向服务器 IP"
echo "2. 等待 SSL 证书自动配置（约 1-5 分钟）"
if [[ "$site_type" == "wordpress" ]]; then
    echo "3. 访问 https://$domain 完成 WordPress 安装"
elif [[ "$site_type" == "laravel" ]]; then
    echo "3. 配置 Laravel .env 文件"
    echo "4. 运行数据库迁移"
fi
echo "5. 定期备份网站数据和数据库" 