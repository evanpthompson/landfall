# Build stage
FROM dart:3.8.0 AS build
WORKDIR /app
COPY . .

# Install dependencies and compile the server executable
RUN dart pub get
RUN dart compile exe bin/main.dart -o bin/server

# Final stage
FROM alpine:latest

# envsubst (from gettext) renders config templates at startup
RUN apk add --no-cache gettext

WORKDIR /app

# Copy runtime dependencies
COPY --from=build /runtime/ /

# Copy compiled server executable
COPY --from=build /app/bin/server /app/server

# Copy config templates, web assets, migrations, and protocol manifest
COPY --from=build /app/config/ /app/config/
COPY --from=build /app/web/ /app/web/
COPY --from=build /app/migrations/ /app/migrations/
COPY --from=build /app/lib/src/generated/protocol.yaml /app/lib/src/generated/protocol.yaml

# Copy and wire up the entrypoint
COPY docker-entrypoint.sh /app/docker-entrypoint.sh
RUN chmod +x /app/docker-entrypoint.sh /app/server

# Run as non-root
RUN adduser -S -H landfall
USER landfall

# Expose ports
EXPOSE 8080
EXPOSE 8081
EXPOSE 8082

ENTRYPOINT ["/app/docker-entrypoint.sh"]
