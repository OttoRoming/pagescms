# syntax=docker/dockerfile:1

FROM node:24-alpine AS base
WORKDIR /app
ENV NEXT_TELEMETRY_DISABLED=1

RUN apk add --no-cache libc6-compat

FROM base AS dependencies
COPY package.json package-lock.json ./
RUN npm ci --no-audit --no-fund

FROM dependencies AS builder
# Enable the standalone server output used by the runner stage.
ENV NEXT_OUTPUT=standalone
# BASE_URL is needed when Next.js prerenders pages (for example the 404 page).
# It is only a build-time default; the runtime value comes from the container
# environment.
ARG BASE_URL=http://localhost:3000
ENV BASE_URL=$BASE_URL
COPY . .
RUN npm run build

FROM base AS runner
ENV NODE_ENV=production
ENV HOSTNAME=0.0.0.0
ENV PORT=3000

RUN addgroup --system --gid 1001 nodejs \
  && adduser --system --uid 1001 --ingroup nodejs nextjs

# Next.js standalone server (includes the minimal production node_modules).
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
COPY --from=builder --chown=nextjs:nodejs /app/public ./public

# Migration runner and migration files. The full drizzle-orm and postgres
# packages are copied because the standalone output only traces modules used
# by the Next.js server itself.
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/drizzle-orm ./node_modules/drizzle-orm
COPY --from=builder --chown=nextjs:nodejs /app/node_modules/postgres ./node_modules/postgres
COPY --from=builder --chown=nextjs:nodejs /app/db/migrations ./db/migrations
COPY --from=builder --chown=nextjs:nodejs /app/scripts/migrate.mjs ./scripts/migrate.mjs

COPY --chown=nextjs:nodejs docker/entrypoint.sh /usr/local/bin/pagescms-entrypoint
RUN chmod +x /usr/local/bin/pagescms-entrypoint

USER nextjs
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
  CMD node -e "fetch('http://127.0.0.1:' + (process.env.PORT || 3000) + '/', { redirect: 'manual' }).then((response) => process.exit(response.status < 500 ? 0 : 1)).catch(() => process.exit(1))"

ENTRYPOINT ["/usr/local/bin/pagescms-entrypoint"]
CMD ["node", "server.js"]
