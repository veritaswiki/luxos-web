#!/bin/bash

# 导入通用函数库
source "$(dirname "$0")/lib/common.sh"

# 设置错误处理
trap 'error_handler ${LINENO} $? $(basename "$0")' ERR

# 备份配置
BACKUP_DIR="backups"
BACKUP_RETENTION_DAYS=7
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="backup_${TIMESTAMP}"

# 函数：检查备份目录
check_backup_dir() {
    if [ ! -d "$BACKUP_DIR" ]; then
        log "INFO" "创建备份目录 $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    
    # 检查备份目录权限
    check_directory_permissions "$BACKUP_DIR" 700
}

# 函数：检查备份空间
check_backup_space() {
    local required_space=$1  # MB
    local available_space=$(df -m "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    
    if [ "$available_space" -lt "$required_space" ]; then
        log "ERROR" "备份空间不足 (可用: ${available_space}MB, 需要: ${required_space}MB)"
        return 1
    fi
    
    log "INFO" "备份空间充足"
    return 0
}

# 函数：备份数据库
backup_database() {
    log "INFO" "开始备份数据库..."
    
    local db_container="postgres"  # 或其他数据库容器名
    local db_user="$POSTGRES_USER"
    local db_name="$POSTGRES_DB"
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}_db.sql"
    
    # 检查数据库容器状态
    if ! check_container_health "$db_container"; then
        log "ERROR" "数据库容器未运行或不健康"
        return 1
    fi
    
    # 执行数据库备份
    log "INFO" "导出数据库 $db_name"
    if docker exec "$db_container" pg_dump -U "$db_user" "$db_name" > "$backup_file"; then
        log "INFO" "数据库备份完成: $backup_file"
    else
        log "ERROR" "数据库备份失败"
        return 1
    fi
    
    # 压缩备份文件
    gzip "$backup_file"
    log "INFO" "数据库备份文件已压缩"
}

# 函数：备份网站文件
backup_files() {
    log "INFO" "开始备份网站文件..."
    
    local www_dir="www"
    local config_dir="config"
    local backup_file="${BACKUP_DIR}/${BACKUP_NAME}_files.tar.gz"
    
    # 检查源目录
    if [ ! -d "$www_dir" ] || [ ! -d "$config_dir" ]; then
        log "ERROR" "网站目录或配置目录不存在"
        return 1
    fi
    
    # 创建排除列表
    local exclude_file="/tmp/backup_exclude.txt"
    cat > "$exclude_file" << EOF
*.log
*.tmp
.git
node_modules
vendor
cache
temp
EOF
    
    # 执行文件备份
    log "INFO" "打包网站文件和配置"
    if tar --exclude-from="$exclude_file" -czf "$backup_file" "$www_dir" "$config_dir"; then
        log "INFO" "文件备份完成: $backup_file"
    else
        log "ERROR" "文件备份失败"
        rm -f "$exclude_file"
        return 1
    fi
    
    rm -f "$exclude_file"
}

# 函数：清理旧备份
cleanup_old_backups() {
    log "INFO" "清理旧备份文件..."
    
    # 删除超过保留天数的备份
    find "$BACKUP_DIR" -type f -mtime +"$BACKUP_RETENTION_DAYS" -name "backup_*" -exec rm -f {} \;
    
    # 检查备份目录大小
    local backup_size=$(du -sm "$BACKUP_DIR" | cut -f1)
    log "INFO" "当前备份目录大小: ${backup_size}MB"
}

# 函数：验证备份
verify_backup() {
    log "INFO" "验证备份文件完整性..."
    
    # 检查数据库备份
    local db_backup="${BACKUP_DIR}/${BACKUP_NAME}_db.sql.gz"
    if [ -f "$db_backup" ]; then
        if gzip -t "$db_backup" 2>/dev/null; then
            log "INFO" "数据库备份验证通过"
        else
            log "ERROR" "数据库备份文件损坏"
            return 1
        fi
    fi
    
    # 检查文件备份
    local files_backup="${BACKUP_DIR}/${BACKUP_NAME}_files.tar.gz"
    if [ -f "$files_backup" ]; then
        if tar -tzf "$files_backup" >/dev/null 2>&1; then
            log "INFO" "文件备份验证通过"
        else
            log "ERROR" "文件备份损坏"
            return 1
        fi
    fi
}

# 主函数
main() {
    log "INFO" "开始备份过程..."
    
    # 检查备份环境
    check_backup_dir
    check_backup_space 1024  # 需要至少 1GB 空间
    
    # 停止或暂停相关服务（如果需要）
    # docker-compose stop web
    
    # 执行备份
    backup_database
    backup_files
    
    # 重启服务（如果之前停止了）
    # docker-compose start web
    
    # 验证备份
    verify_backup
    
    # 清理旧备份
    cleanup_old_backups
    
    log "INFO" "备份完成"
    
    # 显示备份信息
    echo -e "\n${GREEN}备份摘要：${NC}"
    echo "------------------------"
    echo "备份时间: $TIMESTAMP"
    echo "备份位置: $BACKUP_DIR"
    echo "数据库备份: ${BACKUP_NAME}_db.sql.gz"
    echo "文件备份: ${BACKUP_NAME}_files.tar.gz"
    echo "------------------------"
}

# 执行主函数
main "$@" 