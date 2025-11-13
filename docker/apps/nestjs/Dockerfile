FROM hsilv/oracle-node-base:latest

WORKDIR /app

ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

RUN corepack enable && corepack prepare pnpm@9.11.0 --activate

COPY apps/nestjs/api-portal/pnpm-lock.yaml ./pnpm-lock.yaml
COPY apps/nestjs/api-portal/package.json ./package.json

RUN pnpm install --frozen-lockfile || pnpm install --no-frozen-lockfile

COPY apps/nestjs/api-portal/ .

RUN pnpm run build

RUN pnpm prune --prod

EXPOSE 3000

ENV NODE_ENV=production

CMD ["node", "dist/src/main"]

