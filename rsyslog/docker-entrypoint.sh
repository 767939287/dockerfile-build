#!/bin/sh
# 用环境变量渲染 rsyslog 配置模板，避免数据库凭据硬编码在镜像里
set -eu

TEMPLATE=/etc/rsyslog.conf.template
CONFIG=/etc/rsyslog.conf

# 默认值（与 Dockerfile 中的 ENV 保持一致，便于单独运行脚本时也能工作）
RSYSLOG_DB_HOST="${RSYSLOG_DB_HOST:-127.0.0.1}"
RSYSLOG_DB_PORT="${RSYSLOG_DB_PORT:-3306}"
RSYSLOG_DB_NAME="${RSYSLOG_DB_NAME:-Syslog}"
RSYSLOG_DB_USER="${RSYSLOG_DB_USER:-rsyslog}"
RSYSLOG_DB_PASSWORD="${RSYSLOG_DB_PASSWORD:-}"
export RSYSLOG_DB_HOST RSYSLOG_DB_PORT RSYSLOG_DB_NAME RSYSLOG_DB_USER RSYSLOG_DB_PASSWORD

# ---------------- 参数校验 ----------------
: "${RSYSLOG_DB_HOST:?RSYSLOG_DB_HOST 不能为空}"
: "${RSYSLOG_DB_NAME:?RSYSLOG_DB_NAME 不能为空}"
: "${RSYSLOG_DB_USER:?RSYSLOG_DB_USER 不能为空}"

case "${RSYSLOG_DB_PORT}" in
    '' | *[!0-9]*)
        echo "ERROR: RSYSLOG_DB_PORT 必须是纯数字, 当前为 '${RSYSLOG_DB_PORT}'" >&2
        exit 1
        ;;
esac

# 双引号/反斜杠会破坏 rsyslog 配置语法，直接拒绝
for _v in "${RSYSLOG_DB_HOST}" "${RSYSLOG_DB_NAME}" "${RSYSLOG_DB_USER}" "${RSYSLOG_DB_PASSWORD}"; do
    case "${_v}" in
        *'"'* | *'\'*)
            echo "ERROR: 数据库相关环境变量不能包含双引号或反斜杠" >&2
            exit 1
            ;;
    esac
done

if [ -z "${RSYSLOG_DB_PASSWORD}" ]; then
    echo "WARN: RSYSLOG_DB_PASSWORD 为空，将使用空密码连接 MySQL" >&2
fi

# 只替换指定的变量，避免误改配置里的 $ActionFileDefaultTemplate 等 rsyslog 语法
envsubst '${RSYSLOG_DB_HOST} ${RSYSLOG_DB_PORT} ${RSYSLOG_DB_NAME} ${RSYSLOG_DB_USER} ${RSYSLOG_DB_PASSWORD}' \
    < "${TEMPLATE}" > "${CONFIG}"

echo "INFO: rsyslog 日志输出到 mysql://${RSYSLOG_DB_USER}@${RSYSLOG_DB_HOST}:${RSYSLOG_DB_PORT}/${RSYSLOG_DB_NAME}" >&2

exec "$@"
