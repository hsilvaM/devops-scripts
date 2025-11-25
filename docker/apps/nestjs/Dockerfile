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

RUN if [ -f ormconfig.ts ]; then \
        npx tsc ormconfig.ts --outDir dist --module commonjs --target ES2021 --moduleResolution node --esModuleInterop --skipLibCheck --resolveJsonModule --baseUrl . --rootDir . && \
        node -e "const fs = require('fs'); if (fs.existsSync('dist/ormconfig.js')) { let c = fs.readFileSync('dist/ormconfig.js', 'utf8'); c = c.replace(/from ['\"]src\//g, \"from './\"); c = c.replace(/'src\/\*\*/g, \"'dist/**\"); c = c.replace(/\"src\/\*\*/g, '\"dist/**'); fs.writeFileSync('dist/ormconfig.js', c); }"; \
    fi

RUN if [ -f ormconfig.migration.ts ]; then \
        npx tsc ormconfig.migration.ts --outDir dist --module commonjs --target ES2021 --moduleResolution node --esModuleInterop --skipLibCheck --resolveJsonModule --baseUrl . --rootDir . && \
        node -e "const fs = require('fs'); if (fs.existsSync('dist/ormconfig.migration.js')) { let c = fs.readFileSync('dist/ormconfig.migration.js', 'utf8'); c = c.replace(/from ['\"]src\//g, \"from './\"); c = c.replace(/'src\/\*\*/g, \"'dist/**\"); c = c.replace(/\"src\/\*\*/g, '\"dist/**'); fs.writeFileSync('dist/ormconfig.migration.js', c); }"; \
    fi

RUN find dist -name "*.js" -type f -exec sed -i "s/from ['\"]ormconfig['\"]/from '.\/ormconfig'/g" {} \;

RUN pnpm prune --prod

EXPOSE 3000

ENV NODE_ENV=production

CMD ["pnpm", "run", "start:prod"]

