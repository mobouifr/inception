*This project has been created as part of the 42 curriculum by mobouifr.*

## Description
This repository contains an implementation of the **Inception** project (42 curriculum): a small, production-like web stack fully containerized with **Docker** and orchestrated with **Docker Compose**.

**Goal**
- Run multiple services in isolated containers.
- Connect them through a private Docker network.
- Persist data using volumes/bind mounts.
- Handle secrets safely using Docker secrets.

**Services included**
- **MariaDB**: database backend for WordPress.
- **WordPress (PHP-FPM)**: application container.
- **Nginx**: HTTPS entrypoint (port `443`) and reverse proxy to WordPress.

**Main design choices (as implemented)**
- Docker Compose defines the stack in [srcs/docker-compose.yml](srcs/docker-compose.yml).
- A dedicated bridge network (`my-net`) is used so containers can reach each other by service name.
- Passwords are provided via Docker **secrets** (file-based) from `secrets/`.
- Persistent data is stored on the host under `/home/mobouifr/data/` and mounted into containers.

### Comparisons (required)
#### Virtual Machines vs Docker
- **VMs** virtualize hardware and run full guest OS instances; they are heavier (CPU/RAM), slower to boot, and typically managed per-VM.
- **Docker containers** share the host kernel and package only the app + dependencies; they are lightweight, start fast, and are well-suited for composing multiple services.

#### Secrets vs Environment Variables
- **Environment variables** are convenient for non-sensitive config but can leak through process listings, logs, shell history, crash dumps, or tooling.
- **Docker secrets** keep sensitive values in files managed by the runtime and reduce accidental exposure; in this project, passwords are stored as files in `secrets/` and injected as Compose secrets.

#### Docker Network vs Host Network
- A **Docker bridge network** isolates services from the host, provides internal DNS (service name resolution), and reduces port exposure.
- **Host networking** removes network isolation (container shares host network namespace); it can be faster/simpler in rare cases but reduces separation and increases the blast radius of misconfiguration.

#### Docker Volumes vs Bind Mounts
- **Docker volumes** are managed by Docker (lifecycle and location abstracted), portable across hosts, and often preferred for production data.
- **Bind mounts** map an explicit host path into a container; they are simple and transparent but depend on host filesystem layout.

In this repository, Compose volumes are configured as **bind mounts** (via `driver_opts: { type: none, o: bind }`) to persist data in:
- `/home/mobouifr/data/www` (WordPress files)
- `/home/mobouifr/data/mariadb` (MariaDB data)

## Instructions
### Prerequisites
- Docker Engine
- Docker Compose v2 (`docker compose`)
- GNU Make

### Build and run
All commands are available through the root `Makefile`:

- First run:
	- `make`
- Stop:
	- `make down`
- Restart:
	- `make restart`
- Rebuild (down + init + build + up):
	- `make rebuild`

### Access
- Website (HTTPS): `https://mobouifr.42.fr`
- WordPress admin: `https://mobouifr.42.fr/wp-admin`

If your environment does not resolve `mobouifr.42.fr`, add a local hosts entry:
- `/etc/hosts`: `<IP_ADDRESS> mobouifr.42.fr`

## Resources
### Classic references
- Docker overview: https://docs.docker.com/get-started/
- Docker Compose file reference: https://docs.docker.com/compose/compose-file/
- Docker secrets (Compose): https://docs.docker.com/compose/use-secrets/
- Nginx documentation: https://nginx.org/en/docs/
- WordPress documentation: https://wordpress.org/documentation/
- MariaDB documentation: https://mariadb.com/kb/en/documentation/

### How AI was used
This repository may use AI assistance for:
- Reviewing and improving documentation structure and clarity (README, user/dev docs).
- Explaining design trade-offs (VM vs Docker, secrets vs env vars, networks, volumes).

No AI-generated content is intended to replace understanding of the Docker/Compose configuration; the source of truth remains the files under `srcs/` and `secrets/`.

## More documentation
- User guide: [USER_DOC.md](USER_DOC.md)
- Developer guide: [DEV_DOC.md](DEV_DOC.md)
