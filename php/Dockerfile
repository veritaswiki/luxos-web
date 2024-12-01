ARG PHP_VERSION=8.2
FROM php:${PHP_VERSION}-fpm

# 安装基础依赖
RUN apt-get update && apt-get install -y \
    libpq-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    && rm -rf /var/lib/apt/lists/*

# 配置 GD
RUN docker-php-ext-configure gd --with-freetype --with-jpeg

# 安装基础扩展
RUN docker-php-ext-install \
    pdo_pgsql \
    pdo_mysql \
    mysqli \
    zip \
    gd \
    opcache \
    intl \
    soap \
    xml \
    mbstring

# 安装 Redis 扩展
RUN pecl install redis && docker-php-ext-enable redis

# 安装 Memcached 扩展
RUN apt-get update && apt-get install -y libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# 安装 Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 配置 OPcache
RUN echo "opcache.enable=1" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.memory_consumption=128" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.interned_strings_buffer=8" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.max_accelerated_files=4000" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.revalidate_freq=60" >> /usr/local/etc/php/conf.d/opcache.ini \
    && echo "opcache.fast_shutdown=1" >> /usr/local/etc/php/conf.d/opcache.ini

WORKDIR /var/www/html