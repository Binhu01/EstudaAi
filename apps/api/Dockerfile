# syntax=docker/dockerfile:1
FROM node:24-bookworm-slim AS base
WORKDIR /app
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates openssl \
    && rm -rf /var/lib/apt/lists/*

FROM base AS build
COPY package.json package-lock.json ./
COPY apps/api/package.json ./apps/api/package.json
RUN npm ci --ignore-scripts
COPY apps/api ./apps/api
COPY apps/client/assets/study/catalog.json ./apps/client/assets/study/catalog.json
COPY apps/client/assets/contests/bb2026/catalog.json ./apps/client/assets/contests/bb2026/catalog.json
COPY tools/package-catalog.mjs ./tools/package-catalog.mjs
# URL somente para geração. Este passo não se conecta ao banco.
RUN DATABASE_URL=postgresql://build:build@localhost:5432/build npm run db:generate
RUN npm run build

# Mantém a CLI Prisma, que é devDependency, para o job de migração.
FROM build AS migration
USER node
CMD ["npm", "run", "db:deploy"]

FROM build AS production_dependencies
RUN npm prune --omit=dev --ignore-scripts \
    && mkdir -p /app/apps/api/node_modules

FROM base AS runtime
ENV NODE_ENV=production
COPY --from=production_dependencies --chown=node:node /app/package.json /app/package-lock.json ./
COPY --from=production_dependencies --chown=node:node /app/node_modules ./node_modules
COPY --from=production_dependencies --chown=node:node /app/apps/api/package.json ./apps/api/package.json
# O npm pode resolver dependências na raiz ou dentro do workspace.
# Ambos preservam o cliente Prisma gerado durante o build.
COPY --from=production_dependencies --chown=node:node /app/apps/api/node_modules ./apps/api/node_modules
COPY --from=build --chown=node:node /app/apps/api/dist/src ./apps/api/dist/src
USER node
EXPOSE 3001
CMD ["node", "apps/api/dist/src/main.js"]
