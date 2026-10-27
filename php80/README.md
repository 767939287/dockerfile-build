# php80 镜像

基于 `php:8.5-fpm-alpine` 的 PHP-FPM 镜像，预装常用扩展与 Composer。
PHP 版本、扩展、时区、软件源全部集中在 `Dockerfile` 顶部的“配置区”，不需要 `.env`。

> 约定：**php80 相关的所有文件都放在 `php80/` 目录下，不放仓库根目录。**
> CI 也是按这个路径找 `Dockerfile` 的。

## 目录

```
php80/
├── Dockerfile          # 镜像定义（只改顶部“配置区”）
├── docker-compose.yml  # 本地单独起一个 php80 服务
└── README.md
```

## 配置区

`Dockerfile` 顶部 ARG，改完重新构建即可：

| 参数 | 默认值 | 说明 |
|---|---|---|
| `PHP_VERSION` | `php:8.5-fpm-alpine` | 基础镜像，必须带 `php:` 前缀和 `-fpm-alpine` 后缀 |
| `PHP_EXTENSIONS` | `pdo_mysql,mysqli,mbstring,gd,curl,opcache` | 逗号分隔；`apcu` 自动附带，不用写 |
| `TZ` | `Asia/Shanghai` | 容器时区，写入 `/etc/localtime` 和 `/etc/timezone` |
| `CONTAINER_PACKAGE_URL` | `mirrors.ustc.edu.cn` | Alpine apk 源；留空则用官方 `dl-cdn.alpinelinux.org` |
| `IPE_VERSION` | `2.12.3` | install-php-extensions 版本，固定版本便于命中缓存 |
| `COMPOSER_MIRROR` | `mirrors.aliyun.com` | Composer 下载源，失败自动回退 `getcomposer.org` |

扩展名写法参考 [install-php-extensions](https://github.com/mlocati/docker-php-extension-installer)。

## 镜像内容

- PHP-FPM（基础镜像默认监听 9000；本仓库 compose 挂载的 `php-fpm.conf` 用 9501）
- 基础工具：`tzdata shadow gnu-libiconv libstdc++`
- 扩展：`apcu` + 配置区里的扩展
- `/usr/bin/composer`，`COMPOSER_HOME=/tmp/composer`
- `www-data` 的 UID/GID 统一为 **1000**，便于与宿主机用户对应
- 工作目录 `/www`

## 本地构建

```bash
cd php80
docker build -t dnmp/php80:latest .
```

临时覆盖配置：

```bash
docker build \
  --build-arg PHP_VERSION=php:8.4-fpm-alpine \
  --build-arg PHP_EXTENSIONS=pdo_mysql,mbstring,redis \
  --build-arg TZ=Asia/Shanghai \
  -t dnmp/php80:8.4 .
```

## 用 compose 启动

```bash
cd php80
docker-compose up -d --build
```

不构建，直接用 CI 产出的镜像：

```bash
PHP80_IMAGE=ghcr.io/<owner>/<repo>/php80 PHP80_TAG=latest \
  docker-compose up -d --no-build
```

compose 支持的环境变量（默认值均相对于本目录）：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `PHP80_IMAGE` | `dnmp/php80` | 镜像名 |
| `PHP80_TAG` | `latest` | 镜像 tag |
| `PHP80_SOURCE_DIR` | `../www` | 代码目录 → `/www` |
| `PHP80_INI_FILE` | `../services/php80/php.ini` | php.ini |
| `PHP80_FPM_FILE` | `../services/php80/php-fpm.conf` | php-fpm 池配置 |
| `PHP80_LOG_PATH` | `../logs/php80` | 日志目录 → `/var/log/php` |
| `PHP80_COMPOSER_PATH` | `../data/composer` | Composer 缓存 → `/tmp/composer` |
| `COMPOSE_PROJECT_NAME` | `dnmp` | 与根 compose 同 project 时容器/网络互通 |

## CI（GitHub Actions）

工作流：`.github/workflows/build-php80.yml`，构建上下文固定为 `php80/`。

自动触发：

- 每周一 **02:00（北京时间）** 定时重建（cron `0 18 * * 0`，即周日 18:00 UTC）
- 推送到 `main` / `master` 且改动 `php80/**` 时
- PR 中只构建、不推送

手动触发：Actions → `build-php80` → Run workflow，可填 `platforms`（如 `linux/amd64,linux/arm64`）、`force`（`true` = 忽略 digest 比对强制重建）。

### 构建前检查：基础镜像 digest 未变化则跳过

每次运行会先比对基础镜像（配置区的 `ARG PHP_VERSION`）在 registry 上的 digest：

- digest + `Dockerfile` 内容 + 目标平台 与**上次成功构建**完全一致 → 跳过构建（绿色通过，不推送）
- 任意一项变化（上游重新发布了该 tag、改了配置区、换了平台）→ 正常构建并推送
- 上次记录保存在 Actions Cache 里；缓存过期或首次运行时会照常构建（只是少了一次优化）
- 手动触发时填 `force: true` 可强制重建

产出镜像：`ghcr.io/<owner>/<repo>/php80`

| tag | 说明 |
|---|---|
| `8.5` | 取自 `ARG PHP_VERSION` 的版本号 |
| `8.5-20251027` | 版本 + 构建日期，便于留档回滚 |
| `latest` | 最近一次成功构建 |

可选仓库 Variables：

| Variable | 说明 |
|---|---|
| `GHCR_IMAGE` | 覆盖镜像地址，例如 `abc/php80` |
| `PHP80_PLATFORMS` | 默认目标平台，例如 `linux/amd64,linux/arm64` |

首次推送后，到仓库 Packages 页面把该包可见性改为 public（默认 private）。

## 注意

- Composer 缓存在 `/tmp/composer`，容器重启即丢；需要保留就挂载该目录
- `www-data` 固定为 `1000:1000`，宿主机用户 UID 不同时注意挂载文件的读写权限
- 改监听端口、进程数请改挂载进来的 `php-fpm.conf`，不要改 `Dockerfile`
- 定时任务使用 UTC，且只在**默认分支**生效；仓库连续 60 天无提交会被自动停用，需在 Actions 页面重新启用
