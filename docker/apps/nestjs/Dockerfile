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
        node -e "const ts = require('typescript'); const fs = require('fs'); const content = fs.readFileSync('ormconfig.ts', 'utf8'); const result = ts.transpile(content, {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021, esModuleInterop: true, skipLibCheck: true, experimentalDecorators: true, emitDecoratorMetadata: true}); let fixed = result.replace(/require\(['\"]src\//g, \"require('./\").replace(/from ['\"]src\//g, \"from './\").replace(/'src\/\*\*/g, \"'dist/**\").replace(/\"src\/\*\*/g, '\"dist/**'); fs.writeFileSync('dist/ormconfig.js', fixed);"; \
    fi

RUN if [ -f ormconfig.migration.ts ]; then \
        node -e "const ts = require('typescript'); const fs = require('fs'); const content = fs.readFileSync('ormconfig.migration.ts', 'utf8'); const result = ts.transpile(content, {module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2021, esModuleInterop: true, skipLibCheck: true, experimentalDecorators: true, emitDecoratorMetadata: true}); let fixed = result.replace(/require\(['\"]src\//g, \"require('./\").replace(/from ['\"]src\//g, \"from './\").replace(/'src\/\*\*/g, \"'dist/**\").replace(/\"src\/\*\*/g, '\"dist/**'); fs.writeFileSync('dist/ormconfig.migration.js', fixed);"; \
    fi

RUN find dist -name "*.js" -type f -exec sed -i \
    -e "s/from ['\"]\.\.\/ormconfig['\"]/from '.\/ormconfig'/g" \
    -e "s/from ['\"]ormconfig['\"]/from '.\/ormconfig'/g" \
    -e "s/require(['\"]\.\.\/ormconfig['\"])/require('.\/ormconfig')/g" \
    -e "s/require(['\"]ormconfig['\"])/require('.\/ormconfig')/g" \
    {} \;

RUN pnpm prune --prod

EXPOSE 3000

ENV NODE_ENV=production

CMD ["pnpm", "run", "start:prod"]

