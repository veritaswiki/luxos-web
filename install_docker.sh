#!/bin/bash

# 日志颜色
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 日志函数
log() {
    local level=$1
    shift
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') [$level] $*"
}

# 用户交互函数
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

# 检测Linux发行版
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$NAME
        VER=$VERSION_ID
    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        OS=$DISTRIB_ID
        VER=$DISTRIB_RELEASE
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
        VER=$(cat /etc/debian_version)
    else
        OS=$(uname -s)
        VER=$(uname -r)
    fi
}

# 检查系统资源
check_system_resources() {
    log "INFO" "检查系统资源..."
    
    # 检查CPU核心数
    CPU_CORES=$(nproc)
    # 检查可用内存（MB）
    AVAILABLE_MEM=$(free -m | awk '/^Mem:/{print $7}')
    # 检查磁盘空间（GB）
    AVAILABLE_DISK=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    
    log "INFO" "系统资源情况："
    log "INFO" "CPU核心数: $CPU_CORES"
    log "INFO" "可用内存: ${AVAILABLE_MEM}MB"
    log "INFO" "可用磁盘空间: ${AVAILABLE_DISK}GB"
    
    # 检查最低要求
    if [ "$CPU_CORES" -lt 2 ]; then
        log "WARN" "CPU核心数较少，可能会影响性能"
    fi
    if [ "$AVAILABLE_MEM" -lt 2048 ]; then
        log "WARN" "可用内存不足2GB，可能会影响性能"
    fi
    if [ "$AVAILABLE_DISK" -lt 20 ]; then
        log "WARN" "可用磁盘空间不足20GB，建议清理磁盘"
    fi
}

# 函数：修复 Docker 服务
fix_docker_service() {
    log "INFO" "尝试修复 Docker 服务..."
    
    # 检查并修复 containerd
    if ! systemctl is-active containerd >/dev/null 2>&1; then
        log "INFO" "正在重启 containerd 服务..."
        systemctl stop containerd
        rm -rf /run/containerd/containerd.sock
        systemctl start containerd
        sleep 2
    fi
    
    # 检查 Docker 目录权限
    log "INFO" "检查 Docker 目录权限..."
    mkdir -p /var/lib/docker
    chown root:root /var/lib/docker
    chmod 701 /var/lib/docker
    
    # 检查并清理 Docker 系统文件
    log "INFO" "清理 Docker 系统文件..."
    rm -rf /var/lib/docker/runtimes
    rm -f /var/run/docker.sock
    rm -f /var/run/docker.pid
    
    # 重置 Docker daemon 配置
    log "INFO" "重置 Docker daemon 配置..."
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://registry.docker-cn.com",
        "https://docker.mirrors.ustc.edu.cn"
    ]
}
EOF
    
    # 重新加载 systemd 配置
    log "INFO" "重新加载 systemd 配置..."
    systemctl daemon-reload
    
    # 重启 Docker 服务
    log "INFO" "重启 Docker 服务..."
    systemctl stop docker
    sleep 2
    systemctl start docker
    sleep 5
    
    # 验证服务状态
    if ! systemctl is-active docker >/dev/null 2>&1; then
        log "ERROR" "Docker 服务仍然无法启动"
        log "INFO" "请检查系统日志获取详细信息："
        log "INFO" "1. journalctl -xe"
        log "INFO" "2. dmesg | tail"
        return 1
    fi
    
    log "INFO" "Docker 服务修复完成"
    return 0
}

# 函数：安装基础依赖
install_prerequisites() {
    log "INFO" "安装基础依赖..."
    case $OS in
        *Ubuntu*|*Debian*)
            # 完全卸载旧版本
            apt-get remove -y docker docker-engine docker.io containerd runc || true
            apt-get update
            apt-get install -y \
                apt-transport-https \
                ca-certificates \
                curl \
                gnupg \
                lsb-release \
                iptables \
                python3-pip \
                systemd \
                apparmor \
                libseccomp2
            ;;
        *CentOS*|*Red*Hat*|*Rocky*|*AlmaLinux*)
            yum install -y \
                yum-utils \
                device-mapper-persistent-data \
                lvm2 \
                iptables \
                python3-pip
            ;;
        *SUSE*|*openSUSE*)
            zypper install -y \
                ca-certificates \
                curl \
                gnupg2 \
                python3-pip
            ;;
        *Fedora*)
            dnf install -y \
                dnf-plugins-core \
                device-mapper-persistent-data \
                lvm2 \
                iptables \
                python3-pip
            ;;
        *)
            log "ERROR" "不支持的Linux发行版: $OS"
            exit 1
            ;;
    esac
}

# 添加Docker仓库
add_docker_repo() {
    log "INFO" "添加Docker仓库..."
    case $OS in
        *Ubuntu*|*Debian*)
            curl -fsSL https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]')/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(lsb_release -is | tr '[:upper:]' '[:lower:]') $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
            apt-get update
            ;;
        *CentOS*|*Red*Hat*|*Rocky*|*AlmaLinux*)
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            ;;
        *SUSE*|*openSUSE*)
            zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
            ;;
        *Fedora*)
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            ;;
    esac
}

# 安装Docker
install_docker() {
    log "INFO" "安装Docker..."
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            ;;
        *CentOS*|*Red*Hat*|*Rocky*|*AlmaLinux*)
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            ;;
        *SUSE*|*openSUSE*)
            zypper install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            ;;
        *Fedora*)
            dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin
            ;;
    esac
}

# 函数：配置 Docker
configure_docker() {
    log "INFO" "配置 Docker..."
    
    # 停止现有服务
    systemctl stop docker || true
    systemctl stop containerd || true
    
    # 清理旧配置
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    
    # 创建必要的目录
    mkdir -p /etc/docker
    mkdir -p /var/lib/docker
    mkdir -p /var/lib/containerd
    
    # 设置目录权限
    chown root:root /var/lib/docker
    chown root:root /var/lib/containerd
    chmod 701 /var/lib/docker
    chmod 701 /var/lib/containerd
    
    # 配置 Docker daemon
    cat > /etc/docker/daemon.json <<EOF
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "registry-mirrors": [
        "https://mirror.ccs.tencentyun.com",
        "https://registry.docker-cn.com",
        "https://docker.mirrors.ustc.edu.cn"
    ],
    "exec-opts": ["native.cgroupdriver=systemd"],
    "features": {
        "buildkit": true
    },
    "experimental": false,
    "debug": false
}
EOF
    
    # 创建 systemd 目录
    mkdir -p /etc/systemd/system/docker.service.d
    
    # 重新加载配置
    systemctl daemon-reload
    
    # 启动服务
    systemctl enable containerd
    systemctl start containerd
    sleep 2
    systemctl enable docker
    systemctl start docker
    sleep 5
    
    # 如果服务启动失败，尝试修复
    if ! systemctl is-active docker >/dev/null 2>&1; then
        fix_docker_service
    fi
}

# 安装Docker扩展工具
install_docker_tools() {
    if prompt_user "是否安装Docker扩展工具（如：Portainer、Lazydocker等）？" "y"; then
        log "INFO" "安装Docker扩展工具..."
        
        # 安装Portainer
        if prompt_user "是否安装Portainer（Docker可视化管理工具）？" "y"; then
            docker volume create portainer_data
            docker run -d \
                --name portainer \
                --restart=always \
                -p 9000:9000 \
                -v /var/run/docker.sock:/var/run/docker.sock \
                -v portainer_data:/data \
                portainer/portainer-ce:latest
            log "INFO" "Portainer已安装，请访问 http://localhost:9000"
        fi
        
        # 安装Lazydocker
        if prompt_user "是否安装Lazydocker（终端Docker管理工具）？" "y"; then
            curl https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
            log "INFO" "Lazydocker已安装，运行 'lazydocker' 启动"
        fi
        
        # 安装Docker插件
        if prompt_user "是否安装常用Docker插件？" "y"; then
            docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
            log "INFO" "Loki日志驱动插件已安装"
        fi
    fi
}

# 配置安全设置
configure_security() {
    if prompt_user "是否配置Docker安全设置？" "y"; then
        log "INFO" "配置Docker安全设置..."
        
        # 配置防火墙规则
        if command -v ufw >/dev/null 2>&1; then
            ufw allow 2375/tcp comment 'Docker Remote API'
            ufw allow 2376/tcp comment 'Docker Remote API (SSL)'
            ufw allow 9000/tcp comment 'Portainer'
        fi
        
        # 配置SELinux（如果存在）
        if command -v semanage >/dev/null 2>&1; then
            semanage port -a -t docker_port_t -p tcp 2375
            semanage port -a -t docker_port_t -p tcp 2376
        fi
        
        # 配置AppArmor配置文件（如果存在）
        if command -v apparmor_parser >/dev/null 2>&1; then
            log "INFO" "正在配置AppArmor..."
        fi
    fi
}

# 验证安装
verify_installation() {
    log "INFO" "验证Docker安装..."
    if docker --version && docker compose version; then
        log "INFO" "Docker安装成功！"
        docker --version
        docker compose version
        docker buildx version
        
        # 测试Docker功能
        log "INFO" "测试Docker功能..."
        docker run --rm hello-world
        
        # 显示Docker信息
        log "INFO" "Docker系统信息："
        docker info
    else
        log "ERROR" "Docker安装可能存在问题，请检查以上输出内容"
        exit 1
    fi
}

# 清理安装
cleanup() {
    log "INFO" "清理安装文件..."
    case $OS in
        *Ubuntu*|*Debian*)
            apt-get clean
            ;;
        *CentOS*|*Red*Hat*|*Rocky*|*AlmaLinux*)
            yum clean all
            ;;
        *SUSE*|*openSUSE*)
            zypper clean
            ;;
        *Fedora*)
            dnf clean all
            ;;
    esac
}

# 主函数
main() {
    echo -e "${BLUE}Docker 安装向导${NC}"
    echo "=============================="
    
    # 检查是否为root用户
    if [ "$EUID" -ne 0 ]; then
        log "ERROR" "请使用root权限运行此脚本"
        exit 1
    fi
    
    # 检测系统发行版
    detect_distro
    log "INFO" "检测到系统: $OS $VER"
    
    # 检查系统资源
    check_system_resources
    
    # 询问用户是否继续安装
    if ! prompt_user "是否继续安装Docker？" "y"; then
        log "INFO" "安装已取消"
        exit 0
    fi
    
    # 执行安装步骤
    install_prerequisites
    add_docker_repo
    install_docker
    configure_docker
    install_docker_tools
    configure_security
    verify_installation
    cleanup
    
    log "INFO" "Docker安装完成！"
    echo -e "${GREEN}Docker已成功安装并配置。${NC}"
    echo -e "${YELLOW}请注意：您需要重新登录以使docker组成员身份生效。${NC}"
    
    # 显示后续步骤
    echo -e "\n${BLUE}后续步骤：${NC}"
    echo "1. 重新登录以使docker组成员身份生效"
    echo "2. 运行 'docker run hello-world' 测试Docker安装"
    if docker ps | grep -q "portainer"; then
        echo "3. 访问 http://localhost:9000 配置Portainer"
    fi
    echo "4. 查看 Docker 文档了解更多信息：https://docs.docker.com"
}

# 执行主程序
main "$@" 