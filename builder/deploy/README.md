# JidoBuilder Deployment Guide

## Quick Start

```bash
# Set required environment variables
export SECRET_KEY_BASE=$(mix phx.gen.secret)

# Start the application
docker compose up -d

# With monitoring (Prometheus + Grafana)
docker compose --profile monitoring up -d
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | Yes | - | Phoenix secret key (min 64 chars) |
| `PHX_HOST` | No | `localhost` | Public hostname |
| `PORT` | No | `4000` | HTTP port |
| `GRAFANA_PASSWORD` | No | `admin` | Grafana admin password |

## Data Persistence

Application data (SQLite database) is stored in the `app_data` Docker volume at `/var/lib/jido_builder/`.

## Health Check

The app exposes `GET /healthz` for container health monitoring.

## Monitoring Stack

Enable with `--profile monitoring`:

- **Prometheus** at `http://localhost:9090` - scrapes `/metrics` every 15s
- **Grafana** at `http://localhost:3000` - dashboards (login: admin / `$GRAFANA_PASSWORD`)
