# Poupinho

App para registrar **o que você deixou de gastar** ("economizei R$ 10 no almoço") e acompanhar, em dashboards, quanto economizou no dia, no mês e no ano.

## Funcionalidades

- **Cadastro e login** (autenticação nativa do Rails 8, redefinição de senha por e-mail)
- **Registro rápido** de economias direto no dashboard: descrição, valor, categoria e data
- **Dashboard** com KPIs (hoje / mês / ano / total), meta mensal com barra de progresso, sequência de dias, gráficos dos últimos 12 meses, por categoria e dia a dia
- **Economias**: listagem com busca, filtro por mês e categoria, total do período e paginação; CRUD completo
- **Categorias** personalizáveis (nome, ícone Bootstrap Icons, cor); cada usuário já nasce com 8 categorias padrão
- **Relatórios**: visão anual mês a mês, melhor mês, média mensal e distribuição por categoria
- **Perfil**: nome, e-mail, meta mensal e senha
- Layout Bootstrap 5 com topbar + sidebar, tema claro/escuro persistido, toasts
- **PWA instalável**: manifest com ícones e atalhos, service worker com cache de assets, últimas páginas visitadas e página offline, banner "Instalar app" e aviso de conexão perdida. Em produção a instalação exige HTTPS (domínio + `proxy.ssl: true`).

## Stack

- **Ruby** 3.3 / **Rails** 8.1
- **PostgreSQL** 16
- **Propshaft** + **Importmap** + **Hotwire** (Turbo + Stimulus) — zero Node.js
- **Bootstrap 5.3** vendored + Bootstrap Icons
- **Chartkick** + **Groupdate** para gráficos, **Kaminari** para paginação
- **Solid Queue / Solid Cache / Solid Cable**
- **Minitest** para testes, **Rubocop Omakase** + **Brakeman** para qualidade
- **Docker Compose** para desenvolvimento, **Kamal 2** para deploy

## Pré-requisitos

- Docker >= 20 e Docker Compose v2
- `make` (opcional, atalhos no `Makefile`)

Nenhum Ruby ou Postgres precisa estar instalado no host.

## Setup inicial

```bash
cp .env.example .env          # só necessário para deploy
export UID GID=$(id -g)       # garante que os arquivos criados no container sejam seus
make build                    # builda a imagem de dev
make dbcreate migrate seed    # cria bancos, roda migrations e cria usuário demo
make up                       # http://localhost:3002
```

Usuário demo (seed): `demo@economiza.local` / `trocar-senha-123`.
Ou crie sua conta em **/registration/new**.

## Comandos úteis

| Comando         | O que faz                              |
|-----------------|----------------------------------------|
| `make up`       | Server em foreground (porta 3002)      |
| `make up-d`     | Server em background                   |
| `make logs`     | Logs do container web                  |
| `make shell`    | bash no container `web`                |
| `make console`  | Rails console                          |
| `make dbshell`  | psql no banco de dev                   |
| `make migrate`  | `bin/rails db:migrate`                 |
| `make dbreset`  | drop + create + migrate + seed         |
| `make test`     | Suite Minitest completa                |
| `make rubocop`  | Linter                                 |
| `make brakeman` | Security scan                          |
| `make lint`     | rubocop + brakeman                     |

Teste único: `docker compose run --rm web bin/rails test test/models/saving_test.rb`

## Deploy (Kamal)

Produção: **https://poupinho.com.br** (DNS no Cloudflare, proxied, SSL/TLS "Full"; certificado Let's Encrypt emitido pelo kamal-proxy). Roda em um servidor com Docker; o IP fica em `DEPLOY_HOST` no `.env`, lido por `config/deploy.yml`. Preencha `.env` com `DEPLOY_HOST`, `POSTGRES_PASSWORD` e as chaves `VAPID_*` (ver `.env.example`; as mesmas chaves servem para dev e produção) e exporte `GITHUB_TOKEN` (escopo `write:packages`). Depois:

```bash
make kamal-setup   # primeira vez
make deploy        # deploys seguintes
```

## Licença

[MIT](LICENSE).
