# Dockerfile para NextJS Portal Emetra
FROM node:20-bullseye-slim

WORKDIR /app

# Habilitar pnpm via corepack
ENV PNPM_HOME=/usr/local/share/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"
RUN corepack enable && corepack prepare pnpm@10.11.0 --activate

# Copiar archivos de dependencias primero para cachear layers
COPY pnpm-lock.yaml ./pnpm-lock.yaml
COPY package.json ./package.json

# Instalar dependencias (incluye dev dependencies necesarias para build)
RUN pnpm install --prefer-frozen-lockfile || pnpm install --no-frozen-lockfile

# Copiar el resto de la aplicacion
COPY . .

# Build de la aplicacion
RUN pnpm run build

EXPOSE 3000

# Usar NODE_ENV production pero mantener npm
ENV NODE_ENV=production

CMD ["pnpm", "run", "start"]