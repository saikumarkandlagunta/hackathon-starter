# Build the application and its CSS assets
FROM node:24-trixie-slim AS build

WORKDIR /app
ENV HUSKY=0

COPY . .
RUN npm ci
RUN npm run scss
RUN npm prune --omit=dev

# Run the production application
FROM node:24-trixie-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production \
    PORT=8080

# Install available OS security updates.
# npm and npx are build tools; the runtime only needs Node.js.
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/local/lib/node_modules/npm \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx

COPY --from=build --chown=node:node /app/ ./
RUN mkdir -p /app/uploads && chown node:node /app/uploads

USER node
EXPOSE 8080

CMD ["node", "app.js"]