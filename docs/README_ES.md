# Luxos Web

[English](README_EN.md) | [中文](README_CN.md) | [Español](README_ES.md) | [日本語](README_JP.md)

Luxos Web es una plataforma moderna de implementación y gestión de aplicaciones web construida con Docker, que proporciona un entorno de ejecución completo y herramientas de gestión para aplicaciones web.

## Características

- 🚀 Implementación Rápida: Despliegue con un clic del entorno completo de aplicaciones web
- 🛡️ Seguro y Confiable: Configuración de seguridad incorporada y gestión de certificados SSL
- 📊 Monitoreo de Rendimiento: Monitoreo en tiempo real de recursos del sistema y estado de aplicaciones
- 💾 Respaldo Automático: Soporte para respaldo automático de bases de datos y archivos
- 🔄 Balanceo de Carga: Balanceo de carga incorporado y proxy inverso
- 🎛️ Gestión Visual: Proporciona gestión por línea de comandos e interfaz web

## Stack Tecnológico

- Servidor Web: Caddy 2.0
- Proxy Inverso: Pingora
- Base de Datos: PostgreSQL 15
- Caché: Redis 7
- Entorno de Ejecución: PHP 8.2
- Contenedorización: Docker & Docker Compose

## Inicio Rápido

### Requisitos del Sistema

- Docker 20.10+
- Docker Compose 2.0+
- 2GB+ RAM
- 20GB+ Espacio en Disco Disponible

### Pasos de Instalación

1. Clonar repositorio:
   ```bash
   git clone https://github.com/veritaswiki/luxos-web.git
   cd luxos-web
   ```

2. Configurar variables de entorno:
   ```bash
   cp .env.example .env
   # Editar archivo .env para establecer tu configuración
   ```

3. Ejecutar script de instalación:
   ```bash
   chmod +x install.sh
   ./install.sh
   ```

4. Iniciar servicios:
   ```bash
   docker-compose up -d
   ```

### Instrucciones de Uso

1. Gestión de sitios:
   ```bash
   ./scripts/menu.sh
   ```

2. Agregar nuevo sitio:
   ```bash
   ./scripts/add_site.sh
   ```

3. Optimización del sistema:
   ```bash
   ./scripts/optimize_system.sh
   ```

4. Respaldar datos:
   ```bash
   ./scripts/backup.sh
   ```

## Estructura de Directorios

```
luxos-web/
├── caddy/              # Archivos de configuración de Caddy
├── config/             # Archivos de configuración de aplicación
├── php/               # Configuración y extensiones de PHP
├── pingora/           # Configuración de Pingora
├── scripts/           # Scripts de gestión
├── www/               # Archivos del sitio web
├── docker-compose.yml # Configuración de Docker compose
└── install.sh         # Script de instalación
```

## Configuración

### Variables de Entorno

- `POSTGRES_USER`: Nombre de usuario de la base de datos
- `POSTGRES_PASSWORD`: Contraseña de la base de datos
- `POSTGRES_DB`: Nombre de la base de datos
- `REDIS_PASSWORD`: Contraseña de Redis

### Optimización de Rendimiento

El sistema tiene algunas optimizaciones preestablecidas que puedes ajustar según tus necesidades:

1. Configuración de PHP-FPM
2. Parámetros de optimización de PostgreSQL
3. Configuración de caché Redis
4. Parámetros del kernel del sistema

## Problemas Comunes

1. ¿Cómo actualizar el sistema?
   ```bash
   git pull
   docker-compose up -d --build
   ```

2. ¿Cómo ver los logs?
   ```bash
   ./scripts/view_logs.sh
   ```

3. ¿Cómo respaldar datos?
   ```bash
   ./scripts/backup.sh
   ```

## Recomendaciones de Seguridad

1. Actualizar regularmente el sistema y dependencias
2. Usar contraseñas fuertes
3. Habilitar firewall
4. Respaldo regular de datos
5. Monitorear logs del sistema

## Contribuir

1. Fork del proyecto
2. Crear rama de característica
3. Commit de cambios
4. Push a la rama
5. Crear Pull Request

## Licencia

MIT License

## Autor

- veritaswiki
- https://github.com/veritaswiki

## Agradecimientos

¡Gracias a todos los desarrolladores que han contribuido a este proyecto! 