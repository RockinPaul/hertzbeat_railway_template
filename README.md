# Apache HertzBeat on Railway

Self-host [Apache HertzBeat](https://hertzbeat.apache.org), an open-source real-time
monitoring system. It monitors websites, APIs, databases, operating systems, middleware and
cloud services without installing agents on the targets, and sends alerts by email, webhook,
Slack, Discord, Telegram and more.

This template deploys HertzBeat with a proper production storage split: PostgreSQL for its
configuration and alert history, and VictoriaMetrics for the collected metrics.

## What gets deployed

| Service | Image | Public | Purpose |
|---|---|---|---|
| `hertzbeat` | `apache/hertzbeat:1.8.0` (thin wrapper) | yes | Web UI, API and the built-in collector |
| `postgres` | `postgres:15` (thin wrapper) | no | Monitors, alert rules, users, tokens |
| `victoria-metrics` | `victoriametrics/victoria-metrics:v1.95.1` (thin wrapper) | no | Metric history, 3-month retention |

All three are thin wrappers over the upstream images. The wrappers only bake settings that are
fixed for Railway, so you are not asked to supply them: the listen port, switching the metadata
store from the packaged embedded H2 to PostgreSQL and the metric store from embedded DuckDB to
VictoriaMetrics, and the storage paths. HertzBeat builds its own database schema with Flyway on
first start, so there is no migration step.

## First run

1. Deploy the template. The first boot takes a minute or two while PostgreSQL initialises and
   HertzBeat runs its migrations.
2. Open the `hertzbeat` service's URL.
3. Log in as **`admin`**. The password is generated for you: copy `HERTZBEAT_ADMIN_PASSWORD`
   from the `hertzbeat` service's variables.
4. Add your first monitor from the UI, or through the API.

## Why the password comes from a variable

HertzBeat reads its login accounts from a `sureness.yml` file inside the image rather than from
the database, and upstream ships a well-known default of `admin` / `hertzbeat`. On a public URL
that is not acceptable, so this template generates a password and the entrypoint writes it into
that file at every start. Change it by editing `HERTZBEAT_ADMIN_PASSWORD` on the `hertzbeat`
service and redeploying. The username stays `admin`.

Because the accounts live in a file, changing the password from inside the web UI does not
survive a redeploy. Use the variable.

## Variables

Everything is wired for you. The two values you might touch are on the `hertzbeat` service.

| Variable | Default | Purpose |
|---|---|---|
| `HERTZBEAT_ADMIN_PASSWORD` | generated (24 chars) | The `admin` login password. At least 12 characters from `A-Z a-z 0-9 _ -`, or the container refuses to start. |
| `HERTZBEAT_OTLP_GRPC_ENABLED` | `false` | OpenTelemetry ingestion. It needs a raw TCP port, which a Railway HTTP domain cannot carry. |

The database URL and password and the VictoriaMetrics URL are set from Railway's service
references, and `POSTGRES_PASSWORD` is generated, so none of them need attention.

To send alert emails, set the standard Spring mail variables on the `hertzbeat` service:
`SPRING_MAIL_HOST`, `SPRING_MAIL_PORT`, `SPRING_MAIL_USERNAME` and `SPRING_MAIL_PASSWORD`. The
image ships placeholder values that do not work.

## How it fits together

- The browser reaches `hertzbeat` over its public HTTPS domain. The other two services are on
  Railway's private network only and are never exposed.
- HertzBeat's built-in collector polls your monitored targets from inside the container, writes
  metrics to VictoriaMetrics and its own configuration to PostgreSQL.
- Data lives on two volumes, one per storage service, and survives redeploys. Both keep their
  data in a subdirectory of the mount point, because a Railway volume root holds a root-owned
  `lost+found` that PostgreSQL's `initdb` would refuse and VictoriaMetrics should not scan.
- The healthcheck uses `/actuator/health`. HertzBeat protects `/actuator/**` by default, so the
  entrypoint opens just the health endpoint; metrics and Prometheus endpoints stay behind auth,
  and Spring hides health details, so it reports a status and nothing more.

## Limitations

- **Remote collectors are not supported.** Distributed collection needs the manager transport
  on TCP port 1158, which a Railway HTTP domain cannot carry. The built-in collector handles
  everything from this one service, which is what most deployments need.
- **Monitoring Oracle and DB2** needs their JDBC drivers, which upstream expects you to drop
  into a mounted `ext-lib` directory. Add them to the `hertzbeat` image if you need those.
- HertzBeat is a Java service and polls continuously, so it is always-on and wants roughly a
  gigabyte of memory.

## Component licenses

The wrapper files here are MIT licensed (see `LICENSE`). The deployed images carry their own:
Apache HertzBeat is Apache-2.0, VictoriaMetrics is Apache-2.0, and PostgreSQL uses the
PostgreSQL licence.
