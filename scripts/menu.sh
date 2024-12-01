#!/bin/bash

# 导入通用函数库
source "$(dirname "$0")/lib/common.sh"

# 设置错误处理
trap 'error_handler ${LINENO} $? $(basename "$0")' ERR

# 主菜单选项
MAIN_MENU_OPTIONS=(
    "站点管理"
    "系统优化"
    "备份管理"
    "监控管理"
    "安全管理"
    "退出"
)

# 站点管理菜单选项
SITE_MENU_OPTIONS=(
    "添加新站点"
    "删除站点"
    "启用/禁用站点"
    "配置 SSL"
    "管理数据库"
    "查看配置"
    "返回主菜单"
)

# 系统优化菜单选项
SYSTEM_MENU_OPTIONS=(
    "系统优化"
    "PHP 优化"
    "数据库优化"
    "Web服务器优化"
    "缓存优化"
    "返回主菜单"
)

# 备份管理菜单选项
BACKUP_MENU_OPTIONS=(
    "创建备份"
    "恢复备份"
    "删除备份"
    "配置自动备份"
    "返回主菜单"
)

# 监控管理菜单选项
MONITOR_MENU_OPTIONS=(
    "系统信息"
    "性能监控"
    "查看日志"
    "返回主菜单"
)

# 安全管理菜单选项
SECURITY_MENU_OPTIONS=(
    "防火墙设置"
    "SSL 证书管理"
    "安全审计"
    "更新系统"
    "返回主菜单"
)

# 函数：显示系统状态
show_system_status() {
    echo -e "\n${BLUE}系统状态${NC}"
    echo "------------------------"
    
    # 检查 Docker 服务
    check_docker
    
    # 检查容器状态
    for container in $(docker ps --format '{{.Names}}'); do
        check_container_health "$container"
    done
    
    # 检查系统资源
    check_system_resources
    
    # 检查网络连接
    check_network
    
    echo "------------------------"
}

# 函数：站点管理菜单
site_management_menu() {
    while true; do
        local choice=$(show_menu "站点管理" "${SITE_MENU_OPTIONS[@]}")
        case $choice in
            1) ./scripts/add_site.sh ;;
            2) ./scripts/remove_site.sh ;;
            3) ./scripts/site_control.sh ;;
            4) ./scripts/ssl_manager.sh ;;
            5) ./scripts/db_manager.sh ;;
            6) ./scripts/show_config.sh ;;
            7) return ;;
        esac
    done
}

# 函数：系统优化菜单
system_optimization_menu() {
    while true; do
        local choice=$(show_menu "系统优化" "${SYSTEM_MENU_OPTIONS[@]}")
        case $choice in
            1) ./scripts/optimize_system.sh ;;
            2) ./scripts/optimize_php.sh ;;
            3) ./scripts/optimize_db.sh ;;
            4) ./scripts/optimize_web.sh ;;
            5) ./scripts/optimize_cache.sh ;;
            6) return ;;
        esac
    done
}

# 函数：备份管理菜单
backup_management_menu() {
    while true; do
        local choice=$(show_menu "备份管理" "${BACKUP_MENU_OPTIONS[@]}")
        case $choice in
            1) ./scripts/backup.sh ;;
            2) ./scripts/restore.sh ;;
            3) ./scripts/delete_backup.sh ;;
            4) ./scripts/auto_backup.sh ;;
            5) return ;;
        esac
    done
}

# 函数：监控管理菜单
monitoring_menu() {
    while true; do
        local choice=$(show_menu "监控管理" "${MONITOR_MENU_OPTIONS[@]}")
        case $choice in
            1) ./scripts/system_info.sh ;;
            2) ./scripts/monitor.sh ;;
            3) ./scripts/view_logs.sh ;;
            4) return ;;
        esac
    done
}

# 函数：安全管理菜单
security_menu() {
    while true; do
        local choice=$(show_menu "安全管理" "${SECURITY_MENU_OPTIONS[@]}")
        case $choice in
            1) ./scripts/firewall.sh ;;
            2) ./scripts/ssl_manager.sh ;;
            3) ./scripts/security_audit.sh ;;
            4) ./scripts/system_update.sh ;;
            5) return ;;
        esac
    done
}

# 主函数
main() {
    # 检查脚本运行环境
    check_command docker
    check_command docker-compose
    
    while true; do
        # 显示系统状态
        show_system_status
        
        # 显示主菜单
        local choice=$(show_menu "主菜单" "${MAIN_MENU_OPTIONS[@]}")
        case $choice in
            1) site_management_menu ;;
            2) system_optimization_menu ;;
            3) backup_management_menu ;;
            4) monitoring_menu ;;
            5) security_menu ;;
            6) 
                log "INFO" "退出系统"
                exit 0 
                ;;
        esac
    done
}

# 执行主函数
main "$@" 