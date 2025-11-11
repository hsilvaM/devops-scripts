FROM php:8.2-apache

ARG BASIC_ZIP=instantclient-basic-linux.x64-12.1.0.2.0.zip
ARG SDK_ZIP=instantclient-sdk-linux.x64-12.1.0.2.0.zip
ARG INSTANTCLIENT_DIR=instantclient_12_1

ENV ORACLE_HOME=/opt/oracle/instantclient \
    LD_LIBRARY_PATH=/opt/oracle/instantclient \
    PATH=/opt/oracle/instantclient:${PATH}

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends libaio1 unzip; \
    rm -rf /var/lib/apt/lists/*

COPY instantclient/${BASIC_ZIP} /tmp/${BASIC_ZIP}
COPY instantclient/${SDK_ZIP} /tmp/${SDK_ZIP}

RUN set -eux; \
    mkdir -p /opt/oracle; \
    unzip -qo /tmp/${BASIC_ZIP} -d /opt/oracle; \
    unzip -qo /tmp/${SDK_ZIP} -d /opt/oracle; \
    ln -s /opt/oracle/${INSTANTCLIENT_DIR} /opt/oracle/instantclient; \
    echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    printf "instantclient,/opt/oracle/instantclient\n" | pecl install oci8-3.2.1; \
    docker-php-ext-enable oci8; \
    rm -f /tmp/${BASIC_ZIP} /tmp/${SDK_ZIP}

COPY php-app/ /var/www/html/

RUN set -eux; \
    { \
        echo 'Alias /php /var/www/html'; \
        echo '<Directory /var/www/html>'; \
        echo '    Options Indexes FollowSymLinks'; \
        echo '    AllowOverride All'; \
        echo '    Require all granted'; \
        echo '</Directory>'; \
    } > /etc/apache2/conf-available/php-app.conf; \
    a2enconf php-app; \
    sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html\n    RedirectMatch ^/$ /php#' /etc/apache2/sites-available/000-default.conf

