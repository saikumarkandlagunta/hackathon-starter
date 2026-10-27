# Build the application and its CSS assets
FROM node:24-bookworm-slim AS build

WORKDIR /app
ENV HUSKY=0

COPY . .
RUN npm ci
RUN npm run scss
RUN npm prune --omit=dev

# Run the production application
FROM node:24-bookworm-slim AS runtime

WORKDIR /app
ENV NODE_ENV=production \
    PORT=8080

COPY --from=build --chown=node:node /app/ ./
RUN mkdir -p /app/uploads && chown node:node /app/uploads

USER node
EXPOSE 8080

CMD ["node", "app.js"]
