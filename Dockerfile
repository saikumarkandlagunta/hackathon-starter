# Build the application and its CSS assets
FROM node:24-trixie-slim AS build

WORKDIR /app
ENV HUSKY=0

COPY . .
RUN npm ci
RUN npm run scss
RUN npm prune --omit=dev
RUN mkdir -p /app/uploads

# Run the app in a minimal, nonroot runtime image
FROM gcr.io/distroless/nodejs24-debian13:nonroot AS runtime

WORKDIR /app
ENV NODE_ENV=production \
    PORT=8080

COPY --from=build --chown=65532:65532 /app/ ./

EXPOSE 8080

CMD ["app.js"]
