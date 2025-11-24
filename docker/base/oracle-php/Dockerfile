FROM php:8.2-apache-bookworm

ARG BASIC_ZIP=instantclient-basic-linux.x64-12.2.0.1.0.zip
ARG SDK_ZIP=instantclient-sdk-linux.x64-12.2.0.1.0.zip
ARG INSTANTCLIENT_DIR=instantclient_12_2

ENV ORACLE_HOME=/opt/oracle/instantclient \
    LD_LIBRARY_PATH=/opt/oracle/instantclient:${LD_LIBRARY_PATH} \
    PATH=/opt/oracle/instantclient:${PATH}

RUN set -eux; \
    printf '%s\n' \
      'deb http://deb.debian.org/debian bookworm main' \
      'deb http://deb.debian.org/debian bookworm-updates main' \
      'deb http://deb.debian.org/debian-security bookworm-security main' \
      > /etc/apt/sources.list; \
    apt-get update \
      -o Acquire::Check-Valid-Until=false \
      -o Acquire::Check-Date=false \
      -o Acquire::AllowInsecureRepositories=true \
      -o Acquire::AllowDowngradeToInsecureRepositories=true; \
    apt-get install -y --no-install-recommends \
      libaio1 unzip \
      -o Acquire::AllowInsecureRepositories=true \
      -o Acquire::AllowDowngradeToInsecureRepositories=true \
      --allow-unauthenticated; \
    rm -rf /var/lib/apt/lists/*

WORKDIR /tmp

# Colocar los ZIPs en docker/base/oracle-php/instantclient antes de construir
COPY docker/base/oracle-php/instantclient/${BASIC_ZIP} /tmp/${BASIC_ZIP}
COPY docker/base/oracle-php/instantclient/${SDK_ZIP} /tmp/${SDK_ZIP}

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

WORKDIR /var/www/html

CMD ["php", "-v"]

