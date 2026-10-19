
# Etapa 1: instalar dependencias
FROM node:22-alpine AS dependencies

WORKDIR /app

COPY package*.json ./

RUN npm ci --omit=dev && npm cache clean --force


# Etapa 2: imagen de ejecución
FROM node:22-alpine

WORKDIR /app

# Eliminar herramientas de desarrollo innecesarias
RUN rm -rf /usr/local/lib/node_modules/npm \
           /usr/local/lib/node_modules/corepack \
           /opt/yarn-v*

COPY --from=dependencies /app/node_modules ./node_modules

COPY package*.json ./
COPY index.js ./

ENV NODE_ENV=production

EXPOSE 3000

USER node

CMD ["node", "index.js"]

