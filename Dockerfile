FROM alpine:3.20 AS builder
LABEL maintainer Naba Das <hello@get-deck.com>

# Persistent runtime dependencies
ARG DEPS="\
        nginx \
        php83 \
        php83-phar \
        php83-bcmath \
        php83-calendar \
        php83-mbstring \
        php83-exif \
        php83-ftp \
        # composer \
        php83-openssl \
        php83-zip \
        php83-sysvsem \
        php83-sysvshm \
        php83-sysvmsg \
        php83-shmop \
        php83-sockets \
        php83-zlib \
        php83-bz2 \
	php83-gd \
        php83-curl \
        php83-simplexml \
        php83-xml \
        php83-opcache \
        php83-dom \
        php83-xmlreader \
        php83-xmlwriter \
        php83-tokenizer \
        php83-ctype \
        php83-session \
        php83-fileinfo \
        php83-iconv \
        php83-json \
        php83-posix \
        php83-pdo \
        php83-pdo_dblib \
        php83-pdo_mysql \
        php83-pdo_odbc \
        php83-pdo_pgsql\
        php83-pdo_sqlite \
        php83-mysqli \
        php83-mysqlnd \
        php83-dev \
        php83-fpm \
        php83-pear \
	git \
        curl \
        ca-certificates \
        runit \
        php83-intl \
	    snappy \
        bash \
"
RUN set -x \
    #&& echo "https://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories \
    && apk add --no-cache $DEPS \
    && mkdir -p /run/nginx \
    && ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log


COPY nginx /
COPY default.conf /etc/nginx/conf.d/default.conf
ARG SERVER_ROOT
RUN sed -i "s#{SERVER_ROOT}#${SERVER_ROOT}#g" /etc/nginx/conf.d/default.conf
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
WORKDIR /var/www
COPY php_ini/php.ini /etc/php83/php.ini
RUN apk add curl nodejs npm
RUN apk add --no-cache php83-pecl-mongodb
RUN apk upgrade

FROM scratch
COPY --from=builder / /
WORKDIR /var/www
EXPOSE 80
EXPOSE 443
RUN chmod +x /sbin/runit-wrapper
RUN chmod +x /sbin/runsvdir-start
RUN chmod +x /etc/service/nginx/run
RUN chmod +x /etc/service/php-fpm/run

CMD ["/sbin/runit-wrapper"]
