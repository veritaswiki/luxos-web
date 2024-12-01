#!/bin/bash

generate_docker_compose() {
    local php_version=$1
    local db_type=$2
    local db_version=$3
    local cache_system=$4

    cat > docker-compose.yml << EOF
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

  php:
    build:
      context: ./php
      dockerfile: Dockerfile
      args:
        PHP_VERSION: ${php_version}
    volumes:
      - ./www:/var/www/html
      - ./php/conf.d:/usr/local/etc/php-fpm.d
    networks:
      - app_network
    restart: unless-stopped
EOF

    # 添加数据库服务
    if [[ "$db_type" == "PostgreSQL" ]]; then
        cat >> docker-compose.yml << EOF

  postgres:
    image: postgres:${db_version}-alpine
    environment:
      POSTGRES_USER: \${POSTGRES_USER:-appuser}
      POSTGRES_PASSWORD: \${POSTGRES_PASSWORD:-secretpassword}
      POSTGRES_DB: \${POSTGRES_DB:-appdb}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    networks:
      - app_network
    restart: unless-stopped
EOF
    elif [[ "$db_type" == "MySQL" ]]; then
        cat >> docker-compose.yml << EOF

  mysql:
    image: mysql:${db_version}
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD:-rootpassword}
      MYSQL_USER: \${MYSQL_USER:-appuser}
      MYSQL_PASSWORD: \${MYSQL_PASSWORD:-secretpassword}
      MYSQL_DATABASE: \${MYSQL_DATABASE:-appdb}
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "3306:3306"
    networks:
      - app_network
    restart: unless-stopped
EOF
    fi

    # 添加缓存服务
    if [[ "$cache_system" == *"Redis"* ]]; then
        cat >> docker-compose.yml << EOF

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - app_network
    restart: unless-stopped
EOF
    fi

    if [[ "$cache_system" == *"Memcached"* ]]; then
        cat >> docker-compose.yml << EOF

  memcached:
    image: memcached:latest
    ports:
      - "11211:11211"
    networks:
      - app_network
    restart: unless-stopped
EOF
    fi

    # 添加网络和卷配置
    cat >> docker-compose.yml << EOF

networks:
  app_network:
    driver: bridge

volumes:
  caddy_data:
  caddy_config:
EOF

    if [[ "$db_type" == "PostgreSQL" ]]; then
        echo "  postgres_data:" >> docker-compose.yml
    elif [[ "$db_type" == "MySQL" ]]; then
        echo "  mysql_data:" >> docker-compose.yml
    fi

    if [[ "$cache_system" == *"Redis"* ]]; then
        echo "  redis_data:" >> docker-compose.yml
    fi
} 