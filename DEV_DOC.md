# Developer Documentation (Inception)

## Environment Setup From Scratch
### Prerequisites
- Docker Engine
- Docker Compose v2 (`docker compose`)
- GNU Make
- A Linux environment matching the project paths used in the Makefile:
  - `/home/mobouifr/data/www`
  - `/home/mobouifr/data/mariadb`

### Configuration Files
- Compose file: `srcs/docker-compose.yml`
- Environment variables file: `srcs/.env`
- Secrets directory: `secrets/`

### Secrets
Passwords are provided via Docker secrets (file-based):
- `secrets/db_password.txt`
- `secrets/db_root_password.txt`
- `secrets/wp_admin_password.txt`
- `secrets/wp_user_password.txt`

Keep these out of logs and avoid committing real credentials.

## Build and Launch
Use the root `Makefile` as the single entry-point:

- Initialize host directories (persistence paths):
  - `make init`
- Build images:
  - `make build`
- Launch in detached mode:
  - `make up`
- Full pipeline (init + build + up):
  - `make`

The Makefile uses:
- `docker compose -f srcs/docker-compose.yml ...`

## Container / Volume Management Commands
### Containers
- Status:
  - `docker ps`
- Logs:
  - `docker logs -f nginx`
  - `docker logs -f wordpress`
  - `docker logs -f mariadb`
- Shell inside a container:
  - `docker exec -it nginx sh`
  - `docker exec -it wordpress sh`
  - `docker exec -it mariadb sh`

### Compose
- View resolved config (handy for debugging env/secrets):
  - `docker compose -f srcs/docker-compose.yml config`
- Restart a single service:
  - `docker compose -f srcs/docker-compose.yml restart wordpress`

### Volumes and persistent data
This project declares volumes with `driver: local` and bind-mounts them to host paths:

- `wordpress_data` → `/home/mobouifr/data/www` (mounted to `/var/www/html`)
- `db_data` → `/home/mobouifr/data/mariadb` (mounted to `/var/lib/mysql`)

Inspect volume metadata:
- `docker volume inspect wordpress_data`
- `docker volume inspect db_data`

Clean-up commands are available:
- `make clean` (stops stack, prunes unused volumes)
- `make fclean` (full prune + deletes `/home/mobouifr/data/*` content; destructive)

## Data Persistence Model
- **Database persistence**: MariaDB keeps data under `/var/lib/mysql` which is bind-mounted to `/home/mobouifr/data/mariadb`.
- **WordPress persistence**: WP files under `/var/www/html` are bind-mounted to `/home/mobouifr/data/www`.

Because persistence is on the host filesystem, rebuilding images does not wipe site content unless you run `make fclean`.

## Project Layout
- `srcs/`:
  - `docker-compose.yml`: service definitions (nginx, wordpress, mariadb)
  - `.env`: environment variables used by Compose
  - `requirements/`: Docker build contexts for each service
- `secrets/`:
  - password files loaded as Docker secrets

## Design Notes (as implemented)
- **Network**: a dedicated bridge network (`my-net`) isolates the stack and allows service discovery by container name.
- **Secrets**: passwords are supplied via secrets files rather than inline environment variables.
- **Storage**: bind-mounted host directories are used for persistence to make data easy to inspect and survive container recreation.
