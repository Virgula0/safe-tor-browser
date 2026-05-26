up:
	docker compose up --build -d
.PHONY: up

up:
	docker compose down
.PHONY: up

logs:
	docker logs tor-browser -f
.PHONY: logs