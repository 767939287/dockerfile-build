# syntax=docker/dockerfile:1
# ================================================================
# ★★★  配 置 区 ：只改这里，不需要 .env  ★★★
# ----------------------------------------------------------------
# 基础镜像（必须带 php: 前缀和 -fpm-alpine 后缀）
ARG PHP_VERSION=php:8.5-fpm-alpine

# 要安装的 PHP 扩展，逗号分隔（apcu 会自动附带，无需写）
ARG PHP_EXTENSIONS=pdo_mysql,mysqli,mbstring,gd,curl,opcache

# 容器时区
ARG TZ=Asia/Shanghai

# Alpine 软件源镜像（留空 = 官方源 dl-cdn.alpinelinux.org）
ARG CONTAINER_PACKAGE_URL=mirrors.ustc.edu.cn

# install-php-extensions 版本（https://github.com/mlocati/docker-php-extension-installer）
ARG IPE_VERSION=2.12.3

# Composer 下载源，失败会自动回退 getcomposer.org
ARG COMPOSER_MIRROR=mirrors.aliyun.com
# ================================================================
#  配 置 区 结 束 —— 下面不需要改动
# ================================================================

FROM ${PHP_VERSION}

# 把配置区的 ARG 传进构建阶段
ARG PHP_EXTENSIONS
ARG TZ
ARG CONTAINER_PACKAGE_URL
ARG IPE_VERSION
ARG COMPOSER_MIRROR

USER root

# 1. 换源 + 基础工具 + 时区
RUN set -eux; \
    if [ -n "${CONTAINER_PACKAGE_URL}" ]; then \
        sed -i "s/dl-cdn.alpinelinux.org/${CONTAINER_PACKAGE_URL}/g" /etc/apk/repositories; \
    fi; \
    apk add --no-cache tzdata shadow gnu-libiconv libstdc++; \
    cp "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone

# 2. install-php-extensions（固定版本，单独一层便于缓存）
RUN set -eux; \
    curl -fsSL -o /usr/local/bin/install-php-extensions \
        "https://github.com/mlocati/docker-php-extension-installer/releases/download/${IPE_VERSION}/install-php-extensions"; \
    chmod uga+x /usr/local/bin/install-php-extensions

# 3. 安装扩展：apcu 必装，其余来自 .env 的 PHP80_EXTENSIONS（逗号分隔）
RUN set -eux; \
    ext_list="apcu"; \
    if [ -n "${PHP_EXTENSIONS}" ]; then \
        ext_list="${ext_list} $(echo "${PHP_EXTENSIONS}" | tr ',' ' ')"; \
    fi; \
    install-php-extensions ${ext_list}; \
    rm -rf /tmp/* /var/cache/apk/*

# 4. Composer + 统一 www-data 的 UID/GID 为 1000
RUN set -eux; \
    if ! curl -fsSL -o /usr/bin/composer "https://${COMPOSER_MIRROR}/composer/composer.phar"; then \
        curl -fsSL -o /usr/bin/composer https://getcomposer.org/composer-stable.phar; \
    fi; \
    chmod +x /usr/bin/composer; \
    usermod -u 1000 www-data; \
    groupmod -g 1000 www-data

ENV COMPOSER_HOME=/tmp/composer
WORKDIR /www
