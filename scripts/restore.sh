#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 显示可用的备份
show_backups() {
    echo -e "${BLUE}可用的备份文件：${NC}"
    if [ -d "backup" ]; then
        ls -lt backup/*.tar.gz 2>/dev/null | awk '{print $9}'
    else
        echo "没有找到备份文件"
        exit 1
    fi
}

# 解压备份
extract_backup() {
    local backup_file=$1
    local temp_dir="backup/temp_restore"
    
    echo -e "${BLUE}解压备份文件...${NC}"
    mkdir -p "$temp_dir"
    tar -xzf "$backup_file" -C "$temp_dir"
    
    # 获取备份时间戳目录
    local timestamp_dir=$(ls "$temp_dir")
    if [ -z "$timestamp_dir" ]; then
        echo -e "${RED}备份文件格式错误${NC}"
        rm -rf "$temp_dir"
        exit 1
    fi
    
    echo "$temp_dir/$timestamp_dir"
}

# 恢复配置文件
restore_configs() {
    local restore_dir=$1
    
    echo -e "${BLUE}恢复配置文件...${NC}"
    cp -r "$restore_dir/config/"* config/
    cp "$restore_dir/docker-compose.yml" ./
    cp "$restore_dir/.env" ./
}

# 恢复数据库
restore_database() {
    local restore_dir=$1
    
    echo -e "${BLUE}恢复数据库...${NC}"
    
    if [ ! -f "$restore_dir/database.sql" ]; then
        echo -e "${RED}未找到数据库备份文件${NC}"
        return 1
    fi
    
    # 检查数据库类型
    if docker-compose ps | grep -q "postgres"; then
        echo "恢复 PostgreSQL 数据库..."
        docker-compose exec -T postgres psql -U "$POSTGRES_USER" < "$restore_dir/database.sql"
    elif docker-compose ps | grep -q "mysql"; then
        echo "恢复 MySQL 数据库..."
        docker-compose exec -T mysql mysql -u root -p"$MYSQL_ROOT_PASSWORD" < "$restore_dir/database.sql"
    else
        echo -e "${RED}未检测到支持的数据库服务${NC}"
        return 1
    fi
}

# 恢复网站文件
restore_sites() {
    local restore_dir=$1
    
    echo -e "${BLUE}恢复网站文件...${NC}"
    
    if [ -f "$restore_dir/www.tar.gz" ]; then
        rm -rf www/*
        tar -xzf "$restore_dir/www.tar.gz" -C ./
    else
        echo -e "${RED}未找到网站文件备份${NC}"
        return 1
    fi
}

# 清理临时文件
cleanup() {
    local temp_dir=$1
    echo -e "${BLUE}清理临时文件...${NC}"
    rm -rf "$temp_dir"
}

# 主函数
main() {
    echo -e "${YELLOW}警告：恢复操作将覆盖现有数据，请确保已备份重要数据${NC}"
    read -p "是否继续？(y/n): " confirm
    
    if [ "$confirm" != "y" ]; then
        echo "操作已取消"
        exit 0
    fi
    
    # 显示可用备份
    show_backups
    
    # 选择备份文件
    read -p "请输入要恢复的备份文件路径: " backup_file
    
    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}备份文件不存在${NC}"
        exit 1
    fi
    
    # 解压备份
    restore_dir=$(extract_backup "$backup_file")
    
    # 停止服务
    echo -e "${BLUE}停止服务...${NC}"
    docker-compose down
    
    # 执行恢复
    restore_configs "$restore_dir"
    restore_sites "$restore_dir"
    
    # 启动服务
    echo -e "${BLUE}启动服务...${NC}"
    docker-compose up -d
    
    # 恢复数据库
    restore_database "$restore_dir"
    
    # 清理
    cleanup "backup/temp_restore"
    
    echo -e "${GREEN}恢复完成！${NC}"
}

main 