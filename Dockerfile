FROM ubuntu:20.04 as base

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=8.1.15
ARG COMPOSER_VERSION=2.3.7
ARG SWOOLE_VERSION="v5.1.1"
ARG PHPREDIS_VERSION="6.0.2"

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates build-essential pkg-config autoconf bison re2c libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libpng-dev libjpeg-dev libonig-dev libfreetype6-dev libzip-dev libtidy-dev libwebp-dev git && curl https://www.php.net/distributions/php-${PHP_VERSION}.tar.gz -o php-${PHP_VERSION}.tar.gz \
    && update-ca-certificates \
    && tar -xzf php-${PHP_VERSION}.tar.gz \
    && cd php-${PHP_VERSION} \
    && ./buildconf --force \
    && ./configure \
        --with-config-file-path=/etc/php8.1 \
        --with-config-file-scan-dir=/etc/php8.1/conf.d \
        --disable-cgi \
        --with-zlib \
        --with-zip \
        --with-openssl \
        --with-curl \
        --enable-mysqlnd \
        --enable-opcache \
        --with-mysqli=mysqlnd \
        --with-pdo-mysql=mysqlnd \
        --enable-gd \
        --enable-exif \
        --with-jpeg \
        --with-freetype \
        --with-webp \
        --enable-bcmath \
        --enable-mbstring \
        --enable-calendar \
        --with-tidy \
        --enable-zts \
        --enable-xml \
        --enable-sysvshm \
        --enable-sysvsem \
        --enable-sysvmsg \
    && make -j"$(nproc)" \
    && make install \
    && curl -sS -L -o "/usr/local/bin/composer" \
      "https://github.com/composer/composer/releases/download/${COMPOSER_VERSION}/composer.phar" \
    && chmod 0755 "/usr/local/bin/composer" \
    && cd /tmp \
    && git clone -b "${SWOOLE_VERSION}" --depth 1 https://github.com/swoole/swoole-src.git \
    && cd swoole-src \
    && phpize \
    && ./configure --enable-swoole-curl --enable-openssl \
    && make -j"$(nproc)" \
    && make install \
    && mkdir -p /etc/php8.1/conf.d && touch /etc/php8.1/conf.d/swoole.ini && \
    echo 'extension=swoole.so' > /etc/php8.1/conf.d/swoole.ini \
    && cd /tmp \
    && git clone --depth 1 https://github.com/crazyxman/simdjson_php.git \
    && cd simdjson_php \
    && phpize \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && mkdir -p /etc/php8.1/conf.d && touch /etc/php8.1/conf.d/simdjson.ini && \
    echo 'extension=simdjson.so' > /etc/php8.1/conf.d/simdjson.ini \
    && cd /tmp \
    && git clone -b ${PHPREDIS_VERSION} --depth 1 https://github.com/phpredis/phpredis.git \
    && cd phpredis \
    && phpize \
    && ./configure \
    && make -j"$(nproc)" \
    && make install \
    && mkdir -p /etc/php8.1/conf.d && touch /etc/php8.1/conf.d/redis.ini  \
    && echo 'extension=redis.so' > /etc/php8.1/conf.d/redis.ini \
    && git clone --depth 1 https://github.com/xdebug/xdebug \
    && cd xdebug \
    && phpize \
    && ./configure -enable-xdebug \
    && make -j"$(nproc)" \
    && make install \
    && mkdir -p /etc/php8.1/conf.d && touch /etc/php8.1/conf.d/xdebug.ini  \
    && apt-get remove -y build-essential pkg-config autoconf bison re2c \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm /php-${PHP_VERSION}.tar.gz \
    && rm -rf /tmp/*
