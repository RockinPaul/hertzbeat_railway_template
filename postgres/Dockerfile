# PostgreSQL for HertzBeat's metadata (monitors, alert rules, users, tokens).
# HertzBeat builds its own schema with Flyway at startup, so no init SQL is needed.
# PGDATA is a SUBDIRECTORY of the mount point: a Railway volume root contains a
# root-owned `lost+found`, and initdb refuses a non-empty data directory.
FROM postgres:15
ENV POSTGRES_DB=hertzbeat \
    POSTGRES_USER=hertzbeat \
    PGDATA=/var/lib/postgresql/data/pgdata
