# Luxos Web

Luxos Web 是一个现代化的 Web 应用部署和管理平台，基于 Docker 构建，提供了完整的 Web 应用程序运行环境和管理工具。

## 功能特点

- 🚀 快速部署：一键部署完整的 Web 应用环境
- 🛡️ 安全可靠：内置安全配置和 SSL 证书管理
- 📊 性能监控：实时监控系统资源和应用状态
- 💾 自动备份：支持数据库和文件的自动备份
- 🔄 负载均衡：内置负载均衡和反向代理
- 🎛️ 可视化管理：提供命令行和 Web 界面管理

## 技术栈

- Web 服务器：Caddy 2.0
- 反向代理：Pingora
- 数据库：PostgreSQL 15
- 缓存：Redis 7
- 运行环境：PHP 8.2
- 容器化：Docker & Docker Compose

## 快速开始

### 系统要求

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 20GB+ 可用磁盘空间

### 安装步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/yourusername/luxos-web.git
   cd luxos-web
   ```

2. 配置环境变量：
   ```bash
   cp .env.example .env
   # 编辑 .env 文件，设置你的配置
   ```

3. 运行安装脚本：
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

4. 启动服务：
   ```bash
   docker-compose up -d
   ```

### 使用说明

1. 站点管理：
   ```bash
   ./scripts/menu.sh
   ```

2. 添加新站点：
   ```bash
   ./scripts/add_site.sh
   ```

3. 系统优化：
   ```bash
   ./scripts/optimize_system.sh
   ```

4. 备份数据：
   ```bash
   ./scripts/backup.sh
   ```

## 目录结构

```
luxos-web/
├── caddy/              # Caddy 配置文件
├── config/             # 应用配置文件
├── php/               # PHP 配置和扩展
├── pingora/           # Pingora 配置
├── scripts/           # 管理脚本
├── www/               # 网站文件
├── docker-compose.yml # Docker 编排配置
└── install.sh         # 安装脚本
```

## 配置说明

### 环境变量

- `POSTGRES_USER`: 数据库用户名
- `POSTGRES_PASSWORD`: 数据库密码
- `POSTGRES_DB`: 数据库名称
- `REDIS_PASSWORD`: Redis 密码

### 性能优化

系统已经预置了一些优化配置，你可以根据实际需求调整：

1. PHP-FPM 配置
2. PostgreSQL 优化参数
3. Redis 缓存设置
4. 系统内核参数

## 常见问题

1. 如何更新系统？
   ```bash
   git pull
   docker-compose up -d --build
   ```

2. 如何查看日志？
   ```bash
   ./scripts/view_logs.sh
   ```

3. 如何备份数据？
   ```bash
   ./scripts/backup.sh
   ```

## 安全建议

1. 定期更新系统和依赖
2. 使用强密码
3. 启用防火墙
4. 定期备份数据
5. 监控系统日志

## 贡献指南

1. Fork 项目
2. 创建特性分支
3. 提交变更
4. 推送到分支
5. 创建 Pull Request

## 许可证

MIT License

## 作者

- 作者名字
- 联系方式

## 致谢

感谢所有为本项目做出贡献的开发者！