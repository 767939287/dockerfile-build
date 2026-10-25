# rsyslog + rsyslog-mysql, managed by supervisord
# 构建: docker build -t rsyslog-loganalyzer .
FROM alpine

LABEL org.opencontainers.image.title="rsyslog" \
      org.opencontainers.image.description="rsyslog with omysql output, supervised by supervisord" \
      org.opencontainers.image.base.name="docker.io/library/alpine:3.20"

# 时区可通过 --build-arg TZ=... 覆盖
ARG TZ=Asia/Shanghai
ENV TZ=${TZ}

# 安装运行时依赖（单层 + 清理 apk 缓存 + 生成时区数据）
# 构建机可直连官方源时，可去掉 sed 这一行使用默认镜像
RUN set -eux; \
    sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories; \
    apk add --no-cache \
        tzdata \
        gettext-envsubst \
        supervisor \
        rsyslog \
        rsyslog-mysql; \
    cp "/usr/share/zoneinfo/${TZ}" /etc/localtime; \
    echo "${TZ}" > /etc/timezone; \
    rm -rf /var/cache/apk/*

# 运行时目录与日志文件
RUN set -eux; \
    mkdir -p /var/spool/rsyslog /var/www/html; \
    touch /var/log/syslog

# 配置文件放在安装之后，修改配置不会触发依赖层重建
# rsyslog.conf 作为模板保存，启动时由 entrypoint 渲染，避免数据库凭据硬编码
COPY config/rsyslog.conf /etc/rsyslog.conf.template
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 514/tcp
EXPOSE 514/udp

STOPSIGNAL SIGTERM

# 健康检查：确认 rsyslogd 存活（不依赖额外安装 curl）
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD pgrep -f "/usr/sbin/rsyslogd" > /dev/null || exit 1

# 默认值可被 docker run -e / compose environment 覆盖
ENV RSYSLOG_DB_HOST=127.0.0.1 \
    RSYSLOG_DB_PORT=3306 \
    RSYSLOG_DB_NAME=Syslog \
    RSYSLOG_DB_USER=rsyslog \
    RSYSLOG_DB_PASSWORD=""

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# ---------------------------------------------------------------------------
# 可选：需要在本镜像内运行 LogAnalyzer (Apache + PHP) 时，取消注释即可
#
# RUN set -eux; \
#     apk add --no-cache apache2 php83 php83-fpm php83-apache2 php83-opcache \
#         php83-mysqli php83-openssl php83-curl php83-zlib php83-xml \
#         php83-session php83-bcmath php83-ctype php83-iconv php83-json \
#         php83-mbstring php83-gd php83-pdo_mysql php83-pdo_sqlite; \
#     rm -rf /var/cache/apk/*
#
# COPY config/fpm-pool.conf /etc/php83/php-fpm.d/www.conf
# COPY config/php.ini /etc/php83/conf.d/custom.ini
# COPY loganalyzer-4.1.13/src /var/www/html/
# COPY config/loganalyzer-config.php /var/www/html/config.php
# COPY config/createDB.sql /etc/createDB.sql
#
# RUN set -eux; \
#     sed -i 's#^DocumentRoot ".*#DocumentRoot "/var/www/html"#g' /etc/apache2/httpd.conf; \
#     sed -i 's#<Directory "/var/www/localhost/htdocs">#<Directory "/var/www/html">#' /etc/apache2/httpd.conf; \
#     sed -i 's#AllowOverride None#AllowOverride All#' /etc/apache2/httpd.conf; \
#     sed -i 's/#LoadModule\ rewrite_module/LoadModule\ rewrite_module/' /etc/apache2/httpd.conf; \
#     sed -i 's/#LoadModule\ deflate_module/LoadModule\ deflate_module/' /etc/apache2/httpd.conf; \
#     sed -i 's/#LoadModule\ expires_module/LoadModule\ expires_module/' /etc/apache2/httpd.conf; \
#     chown -R apache:apache /var/www/html
#
# EXPOSE 80
# ---------------------------------------------------------------------------
