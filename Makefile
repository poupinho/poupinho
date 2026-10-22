.PHONY: help build up up-d down stop logs ps shell console dbshell bundle dbcreate dbdrop migrate rollback seed dbreset test rubocop rubocop-fix brakeman lint

COMPOSE = docker compose
RUN = $(COMPOSE) run --rm web
RUN_NO_DEPS = $(COMPOSE) run --rm --no-deps web

help: ## Exibe esta ajuda
	@awk 'BEGIN {FS = ":.*##"; printf "\nComandos disponíveis:\n"} /^[a-zA-Z_-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

## --- Lifecycle ---

build: ## Builda (ou rebuilda) a imagem de desenvolvimento
	$(COMPOSE) build web

up: ## Sobe o servidor Rails em primeiro plano (http://localhost:3002)
	$(COMPOSE) up web

up-d: ## Sobe o servidor Rails em background
	$(COMPOSE) up -d web

down: ## Derruba todos os containers (mantém volumes)
	$(COMPOSE) down

stop: ## Para os containers sem removê-los
	$(COMPOSE) stop

logs: ## Mostra logs do servidor web (acompanha)
	$(COMPOSE) logs -f web

ps: ## Lista os containers
	$(COMPOSE) ps

## --- Shell e console ---

shell: ## Abre um shell bash no container web
	$(RUN) bash

console: ## Abre o Rails console
	$(RUN) bin/rails console

dbshell: ## Abre psql conectado ao banco de desenvolvimento
	$(RUN) bin/rails dbconsole

## --- Bundler ---

bundle: ## Executa bundle install
	$(RUN_NO_DEPS) bundle install

## --- Banco de dados ---

dbcreate: ## Cria os bancos development e test
	$(RUN) bin/rails db:create

dbdrop: ## Dropa os bancos development e test
	$(RUN) bin/rails db:drop

migrate: ## Roda migrations pendentes
	$(RUN) bin/rails db:migrate

rollback: ## Faz rollback da última migration
	$(RUN) bin/rails db:rollback

seed: ## Roda db:seed
	$(RUN) bin/rails db:seed

dbreset: ## Drop + create + migrate + seed
	$(RUN) bin/rails db:reset

## --- Qualidade ---

test: ## Roda a suite de testes
	$(RUN) bin/rails test

rubocop: ## Roda o linter rubocop
	$(RUN_NO_DEPS) bin/rubocop

rubocop-fix: ## Aplica correções automáticas do rubocop
	$(RUN_NO_DEPS) bin/rubocop -a

brakeman: ## Roda análise de segurança brakeman
	$(RUN_NO_DEPS) bin/brakeman --no-pager

lint: rubocop brakeman ## Roda rubocop + brakeman

## --- Deploy (Kamal 2) ---

# IP do servidor de produção, lido do .env (fora do repositório).
DEPLOY_HOST ?= $(shell grep '^DEPLOY_HOST=' .env 2>/dev/null | head -1 | cut -d= -f2-)
export DEPLOY_HOST

# Roda o Kamal via container oficial (não exige Ruby no host).
KAMAL_TTY := $(shell tty -s && echo -t)
KAMAL = @docker run --rm -i $(KAMAL_TTY) \
	-v "$(PWD):/workdir" \
	-v "/var/run/docker.sock:/var/run/docker.sock" \
	-v "$(SSH_AUTH_SOCK):/ssh-agent" \
	-e "SSH_AUTH_SOCK=/ssh-agent" \
	-e GITHUB_TOKEN \
	-e POSTGRES_PASSWORD \
	-e DEPLOY_HOST \
	-w /workdir \
	ghcr.io/basecamp/kamal:latest

.PHONY: kamal deploy redeploy kamal-setup kamal-logs kamal-console kamal-shell kamal-dbc kamal-rollback kamal-status
kamal: ## Roda comando Kamal arbitrário (uso: make kamal CMD="app logs")
	$(KAMAL) $(CMD)

kamal-setup: ## Setup inicial: instala Docker no server, sobe accessories, primeiro deploy
	$(KAMAL) setup

deploy: ## Build + push + deploy de uma nova versão
	$(KAMAL) deploy

redeploy: ## Re-deploy da imagem atual sem rebuild (mais rápido)
	$(KAMAL) redeploy

kamal-logs: ## Acompanha logs da app em produção
	$(KAMAL) app logs -f

kamal-console: ## Abre Rails console em produção
	$(KAMAL) console

kamal-shell: ## Abre bash no container da app em produção
	$(KAMAL) shell

kamal-dbc: ## Abre dbconsole em produção
	$(KAMAL) dbc

kamal-rollback: ## Volta para a versão anterior (uso: make kamal-rollback VERSION=<sha>)
	$(KAMAL) rollback $(VERSION)

kamal-status: ## Mostra status dos containers em produção
	$(KAMAL) details

.PHONY: ssh
ssh: ## SSH no servidor de produção (Digital Ocean)
	ssh root@$(DEPLOY_HOST)
