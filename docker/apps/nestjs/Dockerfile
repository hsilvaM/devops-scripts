FROM hsilv/oracle-node-base:latest

ARG APP_NAME=api-portal

WORKDIR /app

ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

RUN corepack enable && corepack prepare pnpm@9.11.0 --activate

COPY apps/nestjs/${APP_NAME}/pnpm-lock.yaml ./pnpm-lock.yaml
COPY apps/nestjs/${APP_NAME}/package.json ./package.json

RUN pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

COPY apps/nestjs/${APP_NAME}/ .

RUN pnpm run build && \
    if [ -d dist/src ]; then cp -r dist/src/* dist/ && rm -rf dist/src; fi

RUN pnpm prune --prod

EXPOSE 3000

ENV NODE_ENV=production

CMD ["pnpm", "run", "start:prod"]

