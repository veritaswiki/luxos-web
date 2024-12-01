# Luxos Web

[English](README_EN.md) | [中文](README_CN.md) | [Español](README_ES.md) | [日本語](README_JP.md)

Luxos Web is a modern web application deployment and management platform built with Docker, providing a complete web application runtime environment and management tools.

## Features

- 🚀 Quick Deployment: One-click deployment of complete web application environment
- 🛡️ Secure & Reliable: Built-in security configuration and SSL certificate management
- 📊 Performance Monitoring: Real-time monitoring of system resources and application status
- 💾 Automatic Backup: Support for database and file automatic backup
- 🔄 Load Balancing: Built-in load balancing and reverse proxy
- 🎛️ Visual Management: Provides command-line and web interface management

## Tech Stack

- Web Server: Caddy 2.0
- Reverse Proxy: Pingora
- Database: PostgreSQL 15
- Cache: Redis 7
- Runtime: PHP 8.2
- Containerization: Docker & Docker Compose

## Quick Start

### System Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 20GB+ Available Disk Space

### Installation Steps

1. Clone repository:
   ```bash
   git clone https://github.com/veritaswiki/luxos-web.git
   cd luxos-web
   ```

2. Configure environment variables:
   ```bash
   cp .env.example .env
   # Edit .env file to set your configuration
   ```

3. Run installation script:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

4. Start services:
   ```bash
   docker-compose up -d
   ```

### Usage Instructions

1. Site management:
   ```bash
   ./scripts/menu.sh
   ```

2. Add new site:
   ```bash
   ./scripts/add_site.sh
   ```

3. System optimization:
   ```bash
   ./scripts/optimize_system.sh
   ```

4. Backup data:
   ```bash
   ./scripts/backup.sh
   ```

## Directory Structure

```
luxos-web/
├── caddy/              # Caddy configuration files
├── config/             # Application configuration files
├── php/               # PHP configuration and extensions
├── pingora/           # Pingora configuration
├── scripts/           # Management scripts
├── www/               # Website files
├── docker-compose.yml # Docker compose configuration
└── install.sh         # Installation script
```

## Configuration

### Environment Variables

- `POSTGRES_USER`: Database username
- `POSTGRES_PASSWORD`: Database password
- `POSTGRES_DB`: Database name
- `REDIS_PASSWORD`: Redis password

### Performance Optimization

The system has some preset optimizations that you can adjust according to your needs:

1. PHP-FPM configuration
2. PostgreSQL optimization parameters
3. Redis cache settings
4. System kernel parameters

## Common Issues

1. How to update the system?
   ```bash
   git pull
   docker-compose up -d --build
   ```

2. How to view logs?
   ```bash
   ./scripts/view_logs.sh
   ```

3. How to backup data?
   ```bash
   ./scripts/backup.sh
   ```

## Security Recommendations

1. Regularly update system and dependencies
2. Use strong passwords
3. Enable firewall
4. Regular data backup
5. Monitor system logs

## Contributing

1. Fork the project
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

MIT License

## Author

- veritaswiki
- https://github.com/veritaswiki

## Acknowledgments

Thanks to all developers who have contributed to this project! 