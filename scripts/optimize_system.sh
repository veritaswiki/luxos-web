#!/bin/bash

# 导入通用函数库
source "$(dirname "$0")/lib/common.sh"

# 设置错误处理
trap 'error_handler ${LINENO} $? $(basename "$0")' ERR

# 系统优化选项
SYSCTL_OPTIMIZATIONS=(
    "net.core.somaxconn=65535"
    "net.core.netdev_max_backlog=65535"
    "net.ipv4.tcp_max_syn_backlog=65535"
    "net.ipv4.tcp_fin_timeout=30"
    "net.ipv4.tcp_keepalive_time=1200"
    "net.ipv4.tcp_max_tw_buckets=5000"
    "net.ipv4.tcp_fastopen=3"
    "net.ipv4.tcp_rmem=4096 87380 67108864"
    "net.ipv4.tcp_wmem=4096 65536 67108864"
    "net.ipv4.tcp_mtu_probing=1"
    "net.core.rmem_max=67108864"
    "net.core.wmem_max=67108864"
    "fs.file-max=2097152"
    "fs.inotify.max_user_watches=524288"
)

# 函数：优化系统参数
optimize_sysctl() {
    log "INFO" "开始优化系统参数..."
    
    # 备份当前配置
    backup_file "/etc/sysctl.conf"
    
    # 应用优化参数
    for param in "${SYSCTL_OPTIMIZATIONS[@]}"; do
        key=$(echo "$param" | cut -d= -f1)
        value=$(echo "$param" | cut -d= -f2)
        
        log "INFO" "设置 $key = $value"
        sysctl -w "$param" >/dev/null 2>&1 || {
            log "ERROR" "设置 $param 失败"
            continue
        }
        
        # 添加到 sysctl.conf
        if ! grep -q "^$key\s*=" /etc/sysctl.conf; then
            echo "$param" >> /etc/sysctl.conf
        else
            sed -i "s|^$key\s*=.*|$param|" /etc/sysctl.conf
        fi
    done
    
    # 应用更改
    sysctl -p >/dev/null 2>&1 || log "ERROR" "应用 sysctl 更改失败"
    
    log "INFO" "系统参数优化完成"
}

# 函数：优化系统限制
optimize_limits() {
    log "INFO" "开始优化系统限制..."
    
    # 备份当前配置
    backup_file "/etc/security/limits.conf"
    
    # 添加系统限制配置
    cat >> /etc/security/limits.conf << EOF
* soft nofile 1048576
* hard nofile 1048576
* soft nproc 65535
* hard nproc 65535
* soft memlock unlimited
* hard memlock unlimited
EOF
    
    log "INFO" "系统限制优化完成"
}

# 函数：优化磁盘调度器
optimize_disk_scheduler() {
    log "INFO" "开始优化磁盘调度器..."
    
    # 对所有磁盘设备应用优化
    for disk in $(ls /sys/block/ | grep -E '^sd|^nvme'); do
        if [ -f "/sys/block/$disk/queue/scheduler" ]; then
            # 对 SSD 使用 none 调度器，对 HDD 使用 deadline
            if [ -f "/sys/block/$disk/queue/rotational" ] && [ "$(cat /sys/block/$disk/queue/rotational)" = "0" ]; then
                echo "none" > "/sys/block/$disk/queue/scheduler"
                log "INFO" "为 SSD $disk 设置 none 调度器"
            else
                echo "deadline" > "/sys/block/$disk/queue/scheduler"
                log "INFO" "为 HDD $disk 设置 deadline 调度器"
            fi
        fi
    done
    
    log "INFO" "磁盘调度器优化完成"
}

# 函数：优化内存管理
optimize_memory() {
    log "INFO" "开始优化内存管理..."
    
    # 设置 Swappiness
    sysctl -w vm.swappiness=10 >/dev/null 2>&1
    echo "vm.swappiness=10" >> /etc/sysctl.conf
    
    # 设置 VFS 缓存压力
    sysctl -w vm.vfs_cache_pressure=50 >/dev/null 2>&1
    echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
    
    # 设置脏页限制
    sysctl -w vm.dirty_ratio=10 >/dev/null 2>&1
    sysctl -w vm.dirty_background_ratio=5 >/dev/null 2>&1
    echo "vm.dirty_ratio=10" >> /etc/sysctl.conf
    echo "vm.dirty_background_ratio=5" >> /etc/sysctl.conf
    
    log "INFO" "内存管理优化完成"
}

# 函数：优化网络接口
optimize_network_interface() {
    log "INFO" "开始优化网络接口..."
    
    # 获取主要网络接口
    local interface=$(ip route | grep default | awk '{print $5}')
    
    if [ -n "$interface" ]; then
        # 设置网络接口参数
        ethtool -G "$interface" rx 4096 tx 4096 2>/dev/null || log "WARN" "无法设置接收/发送环形缓冲区大小"
        ethtool -K "$interface" tso on gso on gro on 2>/dev/null || log "WARN" "无法启用 TSO/GSO/GRO"
        
        log "INFO" "网络接口 $interface 优化完成"
    else
        log "WARN" "未找到默认网络接口"
    fi
}

# 函数：系统优化状态检查
check_optimization_status() {
    log "INFO" "检查系统优化状态..."
    
    # 检查系统参数
    echo -e "\n${BLUE}系统参数状态：${NC}"
    for param in "${SYSCTL_OPTIMIZATIONS[@]}"; do
        key=$(echo "$param" | cut -d= -f1)
        current_value=$(sysctl -n "$key" 2>/dev/null)
        expected_value=$(echo "$param" | cut -d= -f2)
        
        if [ "$current_value" = "$expected_value" ]; then
            echo -e "${GREEN}✓${NC} $key = $current_value"
        else
            echo -e "${RED}✗${NC} $key = $current_value (应为 $expected_value)"
        fi
    done
    
    # 检查系统限制
    echo -e "\n${BLUE}系统限制状态：${NC}"
    local max_files=$(ulimit -n)
    local max_processes=$(ulimit -u)
    
    echo -e "最大文件描述符: $max_files"
    echo -e "最大进程数: $max_processes"
    
    # 检查磁盘调度器
    echo -e "\n${BLUE}磁盘调度器状态：${NC}"
    for disk in $(ls /sys/block/ | grep -E '^sd|^nvme'); do
        if [ -f "/sys/block/$disk/queue/scheduler" ]; then
            local scheduler=$(cat "/sys/block/$disk/queue/scheduler")
            echo -e "设备 $disk: $scheduler"
        fi
    done
    
    # 检查内存管理
    echo -e "\n${BLUE}内存管理状态：${NC}"
    echo -e "Swappiness: $(sysctl -n vm.swappiness)"
    echo -e "VFS Cache Pressure: $(sysctl -n vm.vfs_cache_pressure)"
    echo -e "Dirty Ratio: $(sysctl -n vm.dirty_ratio)"
    echo -e "Dirty Background Ratio: $(sysctl -n vm.dirty_background_ratio)"
}

# 主函数
main() {
    # 检查权限
    if [ "$(id -u)" != "0" ]; then
        log "ERROR" "此脚本需要 root 权限运行"
        exit 1
    fi
    
    # 显示当前系统状态
    log "INFO" "开始系统优化..."
    check_system_resources
    
    # 执行优化
    optimize_sysctl
    optimize_limits
    optimize_disk_scheduler
    optimize_memory
    optimize_network_interface
    
    # 显示优化后的状态
    check_optimization_status
    
    log "INFO" "系统优化完成"
}

# 执行主函数
main "$@" 