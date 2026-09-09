# Changelog

## 2026-09-09 — initial release

Three services for a self-hosted Apache HertzBeat, all pinned and each built from its own
directory in this repository:

- `hertzbeat` — `apache/hertzbeat:1.8.0`. The wrapper bakes the settings that are fixed for
  Railway so they are never deployment inputs: `SERVER_PORT=8080`, the PostgreSQL driver and
  EclipseLink platform in place of the packaged embedded H2, and VictoriaMetrics in place of
  the packaged embedded DuckDB. Flyway's packaged `classpath:db/migration/{vendor}` resolves to
  the PostgreSQL migrations on its own once the driver changes, so no migration path is set.
  The entrypoint refuses to start without an admin password of at least 12 characters from
  `A-Z a-z 0-9 _ -`, writes it into the admin account in the image's own `config/sureness.yml`
  (patched in place, so a version bump keeps upstream's file), and adds
  `/actuator/health` to that file's unauthenticated list for the platform healthcheck.
- `postgres` — `postgres:15` with the `hertzbeat` database and user baked and `PGDATA` in a
  subdirectory of the mount point, because a Railway volume root holds a root-owned
  `lost+found` that `initdb` refuses.
- `victoria-metrics` — `victoriametrics/victoria-metrics:v1.95.1`, private only, listening on
  the port Railway routes to, three-month retention, storage path in a subdirectory of the
  mount point.

Wiring: the database URL, the database password and the VictoriaMetrics URL are Railway service
references; the admin password and the database password are generated with `secret()`. The
template therefore deploys with no values to fill in. Volumes on `postgres` and
`victoria-metrics`; healthcheck `/actuator/health` on `hertzbeat`, which is the only public
service.

### Upgrading

Bump the tag in `hertzbeat/Dockerfile` and redeploy that service. Flyway applies any new
migrations at startup and both volumes are kept. Read upstream's release notes before crossing
a major version.
