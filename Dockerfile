FROM alpine:3.21
LABEL Maintainer="Renan A Bernordi <altendorfme@gmail.com>" \
  Description="Lightweight ClassicPress container with Nginx 1.26 & PHP-FPM 8.4 based on Alpine Linux."

# Install packages
RUN apk --no-cache add \
  php84 \
  php84-fpm \
  php84-mysqli \
  php84-json \
  php84-openssl \
  php84-curl \
  php84-zlib \
  php84-xml \
  php84-phar \
  php84-intl \
  php84-dom \
  php84-xmlreader \
  php84-xmlwriter \
  php84-exif \
  php84-fileinfo \
  php84-sodium \
  php84-gd \
  php84-simplexml \
  php84-ctype \
  php84-mbstring \
  php84-zip \
  php84-opcache \
  php84-iconv \
  php84-pecl-imagick \
  php84-session \
  php84-tokenizer \
  php84-pecl-redis \
  php84-pecl-memcached \
  nginx \
  supervisor \
  curl \
  bash \
  less

# Configure nginx
COPY config/nginx.conf /etc/nginx/nginx.conf

# Configure PHP-FPM
COPY config/fpm-pool.conf /etc/php84/php-fpm.d/zzz_custom.conf
COPY config/php.ini /etc/php84/conf.d/zzz_custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN ln -s /usr/bin/php84 /usr/bin/php

# wp-content volume
VOLUME /var/www/wp-content
WORKDIR /var/www/wp-content
RUN chown -R nobody:nobody /var/www

# ClassicPress
ENV CLASSICPRESS_VERSION 2.4.1
ENV CLASSICPRESS_SHA1 7649225404b8757e7b2c2940ea3fcb98067e0001

RUN mkdir -p /usr/src

# Upstream tarballs include ./classicpress/ so this gives us /usr/src/classicpress
RUN curl -o ${CLASSICPRESS_VERSION}.tar.gz -SL https://github.com/ClassicPress/ClassicPress-release/archive/refs/tags/${CLASSICPRESS_VERSION}.tar.gz \
  && echo "$CLASSICPRESS_SHA1 *$CLASSICPRESS_VERSION.tar.gz" | sha1sum -c - \
  && tar -xzf ${CLASSICPRESS_VERSION}.tar.gz -C /usr/src/ \
  && rm ${CLASSICPRESS_VERSION}.tar.gz \
  && mv /usr/src/ClassicPress-release-${CLASSICPRESS_VERSION} /usr/src/classicpress \
  && chown -R nobody:nobody /usr/src/classicpress

# Add WP CLI
ENV WP_CLI_CONFIG_PATH /usr/src/classicpress/wp-cli.yml
RUN curl -o /usr/local/bin/wp https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x /usr/local/bin/wp
COPY --chown=nobody:nobody wp-cli.yml /usr/src/classicpress/

# WP config
COPY --chown=nobody:nobody wp-config.php /usr/src/classicpress
RUN chmod 640 /usr/src/classicpress/wp-config.php

# Link wp-secrets to location on wp-content
RUN ln -s /var/www/wp-content/wp-secrets.php /usr/src/classicpress/wp-secrets.php

# Entrypoint to copy wp-content
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/wp-login.php
