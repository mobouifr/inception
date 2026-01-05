COMPOSE_FILE = srcs/docker-compose.yml
DOCKER_COMPOSE = docker compose -f $(COMPOSE_FILE)


all: init build up

init:
	mkdir -p /home/mobouifr/data/www
	mkdir -p /home/mobouifr/data/mariadb

build:
	$(DOCKER_COMPOSE) build

up:
	$(DOCKER_COMPOSE) up -d

down:
	$(DOCKER_COMPOSE) down

rebuild: down init build up

restart:
	$(DOCKER_COMPOSE) restart

clean: down
	docker volume prune -f

fclean: clean
	docker volume prune -f
	sudo rm -rf /home/mobouifr/data/www/*
	sudo rm -rf /home/mobouifr/data/mariadb/*
