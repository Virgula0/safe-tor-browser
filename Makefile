up:
	docker compose up --build -d
.PHONY: up

logs:
	docker logs tor-browser -f
.PHONY: logs