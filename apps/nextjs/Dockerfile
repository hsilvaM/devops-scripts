# Dockerfile para NextJS Portal Emetra
FROM node:20-bullseye-slim

WORKDIR /app

# Habilitar pnpm via corepack
ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate

# Copiar archivos de dependencias primero para cachear layers
COPY pnpm-lock.yaml* ./
COPY package.json ./

# Configurar pnpm para usar estructura hoisted (compatible con TypeScript)
RUN echo "shamefully-hoist=true" > .npmrc && \
    echo "node-linker=hoisted" >> .npmrc

# Instalar dependencias
RUN pnpm install --prefer-frozen-lockfile || pnpm install --no-frozen-lockfile

# Copiar el resto de la aplicacion
COPY . .

# Asegurar configuracion de pnpm
RUN echo "shamefully-hoist=true" > .npmrc && \
    echo "node-linker=hoisted" >> .npmrc

# Reinstalar dependencias despues de copiar codigo
RUN pnpm install --prefer-frozen-lockfile || pnpm install --no-frozen-lockfile

# Build de la aplicacion
RUN pnpm run build

EXPOSE 3000

# Usar NODE_ENV production pero mantener npm
ENV NODE_ENV=production

CMD ["pnpm", "run", "start"]