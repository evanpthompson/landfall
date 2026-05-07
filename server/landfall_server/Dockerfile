# Build context must be the repo root so the Dart workspace resolver can find
# pubspec.yaml and the packages/landfall_shared path dependency.
# docker-compose sets: context: ../.. relative to server/landfall_server/

# Build stage
FROM dart:3.8.0 AS build
WORKDIR /app

# Copy workspace root pubspec and only the packages the server needs
COPY pubspec.yaml ./
COPY server/ ./server/
COPY packages/landfall_shared/ ./packages/landfall_shared/

# Resolve dependencies at workspace root so `resolution: workspace` is satisfied
RUN dart pub get

# Compile to a self-contained native executable
RUN dart compile exe server/landfall_server/bin/main.dart \
      -o server/landfall_server/bin/server

# Final stage
FROM alpine:latest

# envsubst (from gettext) renders config templates at startup
RUN apk add --no-cache gettext

WORKDIR /app

# Dart's compile exe bundles the runtime into /runtime/
COPY --from=build /runtime/ /

# Compiled server executable
COPY --from=build /app/server/landfall_server/bin/server /app/server

# Config templates, web assets, migrations, and protocol manifest
COPY --from=build /app/server/landfall_server/config/ /app/config/
COPY --from=build /app/server/landfall_server/web/ /app/web/
COPY --from=build /app/server/landfall_server/migrations/ /app/migrations/
COPY --from=build /app/server/landfall_server/lib/src/generated/protocol.yaml \
                  /app/lib/src/generated/protocol.yaml

# Entrypoint (host COPY from build context = repo root)
COPY server/landfall_server/docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh /app/server

# Run as non-root
RUN adduser -S -H landfall
USER landfall

EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

ENTRYPOINT ["/app/docker-entrypoint.sh"]
