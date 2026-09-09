# Apache HertzBeat server (web UI, API and the built-in collector).
#
# The upstream image is unchanged; this wrapper only bakes the settings that are fixed for a
# Railway deployment, so the deployer never has to supply them. HertzBeat is Spring Boot, and
# environment variables override the packaged application.yml, so no config file is replaced.
FROM apache/hertzbeat:1.8.0

# Listen on the port Railway routes to (the image default is 1157).
# Switch the metadata store from the packaged embedded H2 to PostgreSQL: the driver and the
# Flyway PostgreSQL migrations are already in the image, and the packaged
# `locations: classpath:db/migration/{vendor}` resolves to the postgresql set on its own.
# Switch the metric store from the packaged embedded DuckDB to VictoriaMetrics.
# OTLP/gRPC ingestion needs a raw TCP port, which a Railway HTTP domain cannot carry, so it is
# off by default; the URL and password come from the service variables.
ENV SERVER_PORT=8080 \
    TZ=UTC \
    LANG=en_US.UTF-8 \
    SPRING_DATASOURCE_DRIVER_CLASS_NAME=org.postgresql.Driver \
    SPRING_DATASOURCE_USERNAME=hertzbeat \
    SPRING_JPA_DATABASE=postgresql \
    SPRING_JPA_DATABASE_PLATFORM=org.eclipse.persistence.platform.database.PostgreSQLPlatform \
    WAREHOUSE_STORE_DUCKDB_ENABLED=false \
    WAREHOUSE_STORE_VICTORIA_METRICS_ENABLED=true \
    HERTZBEAT_OTLP_GRPC_ENABLED=false

COPY --chmod=755 entrypoint.sh /railway-entrypoint.sh
ENTRYPOINT ["/railway-entrypoint.sh"]
