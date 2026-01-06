# User Documentation (Inception)

## Overview: What This Stack Provides
This project deploys a small web stack using Docker Compose:

- **Nginx**: TLS termination (HTTPS on port `443`) and reverse proxy.
- **WordPress (PHP-FPM)**: the application (site + admin panel).
- **MariaDB**: the database used by WordPress.

All containers are attached to a dedicated Docker bridge network (`my-net`) so services can reach each other by name (e.g., `mariadb`).

## Start / Stop
All lifecycle operations are exposed through the root `Makefile`.

- Start (first time or after changes):
  - `make`
- Stop containers:
  - `make down`
- Restart containers:
  - `make restart`
- Rebuild images and relaunch:
  - `make rebuild`

Notes:
- `make init` creates the host directories used for persistent storage:
  - `/home/mobouifr/data/www`
  - `/home/mobouifr/data/mariadb`

## Access the Website and Admin Panel
### Website
- HTTPS endpoint is published by Nginx on the host:
  - `https://mobouifr.42.fr` (based on `srcs/.env`)

If DNS is not available in your environment, add a hosts entry pointing to the machine running Docker:
- `/etc/hosts`:
  - `<IP_ADDRESS>  mobouifr.42.fr`

### WordPress Admin
- Admin panel:
  - `https://mobouifr.42.fr/wp-admin`

Credentials are defined through environment variables and Docker secrets (see next section).

## Locate and Manage Credentials
This project uses **Docker secrets** (files) for passwords and **environment variables** for non-sensitive configuration.

### Secrets (passwords)
Stored as files under `secrets/` and mounted into containers by Docker Compose:

- `secrets/db_password.txt` (database user password)
- `secrets/db_root_password.txt` (MariaDB root password)
- `secrets/wp_admin_password.txt` (WordPress admin password)
- `secrets/wp_user_password.txt` (WordPress user password)

To rotate a password:
1. Edit the relevant file in `secrets/`.
2. Recreate containers so the new secret is used:
   - `make down && make up`

### Environment variables (non-sensitive)
The main Compose variables are in `srcs/.env` (domain name, WordPress usernames/emails, DB name/user, certificate subject fields, etc.).

If you change `srcs/.env`, recreate containers:
- `make down && make up`

## Check That Services Are Running Correctly
### Via Docker
- List containers:
  - `docker ps`
- Check logs:
  - `docker logs nginx`
  - `docker logs wordpress`
  - `docker logs mariadb`

### Quick functional checks
- HTTPS responds:
  - `curl -kI https://mobouifr.42.fr`
- WordPress admin reachable:
  - `curl -kI https://mobouifr.42.fr/wp-admin`

If WordPress shows database connection errors, check MariaDB logs first:
- `docker logs mariadb`

## Where Data Lives (Persistence)
This project persists data on the host using bind-mounted directories (declared as Docker “volumes” with `driver_opts: { type: none, o: bind }`):

- WordPress files:
  - Host: `/home/mobouifr/data/www`
  - Container: `/var/www/html`
- MariaDB data:
  - Host: `/home/mobouifr/data/mariadb`
  - Container: `/var/lib/mysql`

To remove *all* persisted data (destructive):
- `make fclean`
