# Deploy and Host Apache HertzBeat on Railway

[Apache HertzBeat](https://hertzbeat.apache.org) is an open-source, real-time monitoring
system. It watches websites, APIs, databases, operating systems, middleware and cloud services
without installing an agent on the target, shows the results on a live dashboard, and raises
alerts through email, webhooks, Slack, Discord, Telegram and more.

## About Hosting Apache HertzBeat

HertzBeat needs two kinds of storage, and this template provides both rather than falling back
to the embedded defaults: PostgreSQL holds its configuration, monitors and alert history, and
VictoriaMetrics holds the collected metrics with three months of retention. The template
deploys three services, gives HertzBeat a public HTTPS domain, keeps the two data stores on
Railway's private network with a volume each, and generates every credential. Nothing needs to
be filled in before deploying. HertzBeat builds its own database schema with Flyway on first
start, so there is no migration step, and its built-in collector runs inside the same service,
so a single deployment monitors everything you point it at.

One thing is specific to hosting it: HertzBeat reads its login accounts from a file inside its
image rather than from the database, and upstream ships a well-known default password. This
template generates an admin password instead and writes it into that file at every start, so
the deployment is not publicly accessible with a default credential.

## Common Use Cases

- Monitor your own websites, APIs and TLS certificate expiry, with alerts when they break.
- Watch databases, message brokers and Linux hosts across several providers from one dashboard.
- Give a small team a self-hosted status and alerting system instead of a paid SaaS plan.

## Dependencies for Apache HertzBeat Hosting

- PostgreSQL for configuration and alert history.
- VictoriaMetrics for the time-series metric history.
- Outbound network access from the deployment to whatever you want to monitor.

### Deployment Dependencies

- [Apache HertzBeat](https://github.com/apache/hertzbeat) — the upstream project (Apache-2.0).
- [HertzBeat documentation](https://hertzbeat.apache.org/docs/) — monitor types, alerting and
  the full configuration reference.
- [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics) — the metric store
  (Apache-2.0).

### Implementation Details

Three services build from this template's repository, each from its own directory:

- **hertzbeat** — `apache/hertzbeat:1.8.0`. A thin wrapper bakes the Railway-fixed settings:
  the listen port, PostgreSQL instead of the packaged embedded H2, and VictoriaMetrics instead
  of the packaged embedded DuckDB. Its entrypoint writes the generated admin password into
  `config/sureness.yml` and opens `/actuator/health` for the platform healthcheck, leaving the
  metrics and Prometheus endpoints behind authentication.
- **postgres** — `postgres:15`, database and user baked, data in a subdirectory of the volume
  because a Railway volume root holds a root-owned `lost+found` that `initdb` refuses.
- **victoria-metrics** — `victoriametrics/victoria-metrics:v1.95.1`, listening on the private
  network with a three-month retention and its data likewise in a subdirectory of the volume.

After deploying, open the `hertzbeat` service's URL and log in as `admin` with the generated
`HERTZBEAT_ADMIN_PASSWORD` from that service's variables. Distributed collection through remote
collectors is not supported here, because it needs a raw TCP port that a Railway HTTP domain
cannot carry; the built-in collector covers everything else.

## Why Deploy Apache HertzBeat on Railway?

Railway is a singular platform to deploy your infrastructure stack. Railway will host your
infrastructure so you don't have to deal with configuration, while allowing you to vertically
and horizontally scale it.

By deploying Apache HertzBeat on Railway, you are one step closer to supporting a complete
full-stack application with minimal burden. Host your servers, databases, AI agents, and more
on Railway.
