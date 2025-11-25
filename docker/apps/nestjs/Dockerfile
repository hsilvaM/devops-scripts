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
        node -e "const ts=require('typescript');const fs=require('fs');const c=fs.readFileSync('ormconfig.ts','utf8');const r=ts.transpile(c,{module:1,target:8,esModuleInterop:1,skipLibCheck:1,experimentalDecorators:1,emitDecoratorMetadata:1});fs.writeFileSync('dist/ormconfig.js',r);" && \
        sed -i \
            -e "s/require(\"src\\//require(\".\//g" \
            -e "s/require('src\\//require('.\//g" \
            -e "s/from \"src\\//from \".\//g" \
            -e "s/from 'src\\//from '.\//g" \
            -e "s/'src\\/\\*\\*/'dist\\/\\*\\*/g" \
            -e "s/\"src\\/\\*\\*/\"dist\\/\\*\\*/g" \
            dist/ormconfig.js; \
    fi

RUN if [ -f ormconfig.migration.ts ]; then \
        node -e "const ts=require('typescript');const fs=require('fs');const c=fs.readFileSync('ormconfig.migration.ts','utf8');const r=ts.transpile(c,{module:1,target:8,esModuleInterop:1,skipLibCheck:1,experimentalDecorators:1,emitDecoratorMetadata:1});fs.writeFileSync('dist/ormconfig.migration.js',r);" && \
        sed -i \
            -e "s/require(\"src\\//require(\".\//g" \
            -e "s/require('src\\//require('.\//g" \
            -e "s/from \"src\\//from \".\//g" \
            -e "s/from 'src\\//from '.\//g" \
            -e "s/'src\\/\\*\\*/'dist\\/\\*\\*/g" \
            -e "s/\"src\\/\\*\\*/\"dist\\/\\*\\*/g" \
            dist/ormconfig.migration.js; \
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

