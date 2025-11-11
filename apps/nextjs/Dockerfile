# Dockerfile para NextJS
FROM node:20-alpine

WORKDIR /app

# Copiar package.json y package-lock.json primero para cachear layers
COPY portal-emetra/package*.json ./

# Instalar TODAS las dependencias (incluye dev dependencies necesarias)
RUN npm install

# Copiar el resto de la aplicacion
COPY portal-emetra/ .

# Build de la aplicacion
RUN npm run build

EXPOSE 3000

# Usar NODE_ENV production pero mantener npm
ENV NODE_ENV=production

CMD ["npm", "run", "start"]