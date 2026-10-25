# rsyslog-loganalyzer
rsyslog - MultiArch DockerAppliance (Alpine-based) with loganalyzer Web-UI

Default-Webport: 8080
SysLOG-Port: 514 TCP/UDP

Based on https://github.com/TrafeX/docker-php-nginx and https://loganalyzer.adiscon.com/

## 数据库连接配置（环境变量）

`config/rsyslog.conf` 以模板形式打进镜像（`/etc/rsyslog.conf.template`），
容器启动时由 `docker-entrypoint.sh` 用环境变量渲染成 `/etc/rsyslog.conf`，
镜像内不含任何数据库地址与密码。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `RSYSLOG_DB_HOST` | `127.0.0.1` | MySQL 主机名/IP（compose 中可填服务名，如 `mysql`） |
| `RSYSLOG_DB_PORT` | `3306` | MySQL 端口（纯数字） |
| `RSYSLOG_DB_NAME` | `Syslog` | 数据库名 |
| `RSYSLOG_DB_USER` | `rsyslog` | 数据库用户 |
| `RSYSLOG_DB_PASSWORD` | 空 | 数据库密码，为空时启动会打印 WARN |
| `TZ` | `Asia/Shanghai` | 时区（构建期 `--build-arg TZ=` 或运行时 `-e TZ=`） |

```bash
docker build -t rsyslog-loganalyzer .

docker run -d --name rsyslog \
  -p 514:514/tcp -p 514:514/udp \
  -e RSYSLOG_DB_HOST=mysql \
  -e RSYSLOG_DB_PORT=3306 \
  -e RSYSLOG_DB_NAME=Syslog \
  -e RSYSLOG_DB_USER=rsyslog \
  -e RSYSLOG_DB_PASSWORD='change-me' \
  rsyslog-loganalyzer
```

> 建议用 compose 的 `env_file` 或 Docker/K8s Secret 注入密码，不要写在 Dockerfile 或镜像里。

