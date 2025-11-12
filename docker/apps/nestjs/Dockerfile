FROM node:20-bookworm

ARG BASIC_ZIP=instantclient-basic-linux.x64-12.1.0.2.0.zip
ARG SDK_ZIP=instantclient-sdk-linux.x64-12.1.0.2.0.zip
ARG INSTANTCLIENT_DIR=instantclient_12_1

ENV ORACLE_HOME=/opt/oracle/instantclient \
    LD_LIBRARY_PATH=/opt/oracle/instantclient \
    PATH=/opt/oracle/instantclient:${PATH}

RUN set -eux; \
    if [ -f /etc/apt/sources.list ]; then \
        sed -i 's|http://deb.debian.org|https://deb.debian.org|g' /etc/apt/sources.list; \
        sed -i 's|http://security.debian.org|https://security.debian.org|g' /etc/apt/sources.list; \
    fi; \
    if [ -f /etc/apt/sources.list.d/debian.sources ]; then \
        sed -i 's|http://deb.debian.org/debian|https://deb.debian.org/debian|g' /etc/apt/sources.list.d/debian.sources; \
        sed -i 's|http://security.debian.org/debian-security|https://security.debian.org/debian-security|g' /etc/apt/sources.list.d/debian.sources; \
    fi; \
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false -o Acquire::https::Verify-Peer=false -o Acquire::https::Verify-Host=false; \
    apt-get install -y --no-install-recommends ca-certificates; \
    apt-get update -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false; \
    apt-get install -y --no-install-recommends libaio1 unzip build-essential python3; \
    rm -rf /var/lib/apt/lists/*

COPY docker/apps/php/instantclient/${BASIC_ZIP} /tmp/${BASIC_ZIP}
COPY docker/apps/php/instantclient/${SDK_ZIP} /tmp/${SDK_ZIP}

RUN set -eux; \
    mkdir -p /opt/oracle; \
    unzip -qo /tmp/${BASIC_ZIP} -d /opt/oracle; \
    unzip -qo /tmp/${SDK_ZIP} -d /opt/oracle; \
    ln -s /opt/oracle/${INSTANTCLIENT_DIR} /opt/oracle/instantclient; \
    echo "/opt/oracle/instantclient" > /etc/ld.so.conf.d/oracle-instantclient.conf; \
    ldconfig; \
    rm -f /tmp/${BASIC_ZIP} /tmp/${SDK_ZIP}

WORKDIR /app

ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

RUN corepack enable && corepack prepare pnpm@9.11.0 --activate

COPY apps/nestjs/api-portal/pnpm-lock.yaml ./pnpm-lock.yaml
COPY apps/nestjs/api-portal/package.json ./package.json

RUN pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

COPY apps/nestjs/api-portal/ .

RUN pnpm run build

EXPOSE 3000

ENV NODE_ENV=production

CMD ["pnpm", "run", "start:prod"]

