# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project context

**Poupinho** (nome interno/código: `economiza`) — app pessoal (Rails 8 + PostgreSQL 16) onde usuários registram dinheiro que **deixaram de gastar** ("economizei R$ 10 no almoço") e acompanham dashboards por dia/mês/ano. Multiusuário com cadastro público. Todo conteúdo voltado ao usuário em **pt-BR**.

## Development environment

Tudo roda em Docker — **não há Ruby/Postgres no host**. Use o `Makefile` (atalhos sobre `docker compose`). Antes de qualquer comando: `export UID GID=$(id -g)` (o container roda com o seu uid para não criar arquivos como root).

| Comando         | O que faz                              |
|-----------------|----------------------------------------|
| `make build`    | Builda imagem dev                      |
| `make up`       | Server em foreground (porta **3002**)  |
| `make shell`    | bash no container `web`                |
| `make console`  | Rails console                          |
| `make migrate`  | `bin/rails db:migrate`                 |
| `make dbreset`  | drop + create + migrate + seed         |
| `make test`     | Suite Minitest completa                |
| `make lint`     | rubocop + brakeman                     |

Teste único: `docker compose run --rm web bin/rails test test/models/saving_test.rb:12`.
Comandos arbitrários: `docker compose run --rm web <cmd>`.

Postgres de dev exposto na porta **5434** do host (evita conflito com outros projetos).

Usuário demo (seed): `demo@economiza.local` / `trocar-senha-123`.

## Architecture

- **Models** ([app/models/](app/models/)) — `User` (has_secure_password, cria categorias padrão em `after_create`), `Category` (por usuário; nome único por usuário, ícone `bi-*`, cor `#rrggbb`), `Goal` (meta nomeada: `target_amount`, `deadline` opcional, ícone/cor/ordem; a de menor `position` aparece em destaque), `Saving` (a economia: `amount`, `description`, `saved_on`, `category` e `goal` opcionais; valida que categoria e meta pertencem ao mesmo usuário e que a data não é futura).
- **Services** ([app/services/](app/services/)) — cálculos ficam fora dos controllers. `Dashboards::Summary` (KPIs, meta mensal, sequência de dias, séries dos gráficos), `Reports::Annual` (consolidação anual), `Goals::Overview` (metas com o total já economizado, em uma query só) e `Gamification::Score` (pontos e nível derivados dos dados, sem persistência; `SavingsController#create` compara antes/depois para o "+N pontos" e o toast de novo nível). Valores monetários sempre em `BigDecimal`.
- **Foto de perfil** — Active Storage (`User has_one_attached :avatar`, variante `:thumb` 160x160 via libvips; disco local, volume `economiza_storage` no Kamal). Validação de tipo (JPG/PNG/WebP/GIF) e tamanho (5 MB) no model. Upload e remoção no perfil (`profiles/_avatar`, controller Stimulus `avatar-picker` faz a prévia). Helper `user_avatar(user)` mostra a foto ou as iniciais (`user_initials`). No login com Google, `User.from_google` agenda `GoogleAvatarJob` ao criar/vincular a conta; o job baixa a foto em 256px com `Avatars::Download` (só https, imagem, até 5 MB) e nunca sobrescreve uma foto já enviada.
- **Login com Google** — OmniAuth (`omniauth-google-oauth2` + CSRF protection; `config/initializers/omniauth.rb`, env `GOOGLE_CLIENT_ID`/`GOOGLE_CLIENT_SECRET` do `.env`). `OmniauthSessionsController#create` usa `User.from_google` (uid → e-mail → cria sem celular com `from_google`). `ApplicationController#require_phone` leva contas sem celular a `/onboarding/phone`; de lá segue para a primeira meta (`goals/new?onboarding=1`). Botão em `shared/_google_button`, só com as variáveis configuradas.
- **Lembretes push** — Web Push com VAPID (gem `web-push`; chaves em `VAPID_PUBLIC_KEY`/`VAPID_PRIVATE_KEY`, vindas do `.env` para o compose e para o Kamal). `PushSubscription` por navegador (`PushSubscriptionsController`, JSON), controller Stimulus `push` no perfil, handlers `push`/`notificationclick` no service worker (badge da barra de status = `public/badge-96.png`, silhueta branca em fundo transparente gerada do `icon.png`; o Android descarta a cor e usa só o alfa). `DailyReminderJob` roda a cada hora (`config/recurring.yml`, Solid Queue no Puma) e `Reminders::Daily` notifica, no máximo uma vez por dia (`users.last_reminded_on`), quem ainda não registrou economia e cuja hora habitual de registro (`Reminders::BestHour`: moda das horas dos últimos 60 dias, janela 8h–21h, padrão 20h) é a hora corrente. O dashboard convida a ativar num banner (`dashboard/_push_banner`, controller `push` em modo banner).
- **Divulgação** — Conteúdo público indexável em `/dicas` e `/dicas/:slug` (`Tip`, um objeto simples sobre a chave `tips.groups` do locale: slug estável, corpo, passos, estimativa e dicas do mesmo grupo; `tips/_shell` dá cabeçalho e rodapé próprios a quem chega sem login, e dados estruturados de `Article`/`BreadcrumbList` em cada página). Sitemap gerado pelo `SitemapController` a partir das páginas fixas mais cada dica, então dica nova entra sozinha (apontado pelo `robots.txt`; as autenticadas têm `noindex` em `layouts/_seo`). `canonical_url` no `ApplicationHelper` fixa o domínio pelo `APP_HOST`, para o www não duplicar conteúdo. Analytics com Google Analytics 4 (gtag.js) em `layouts/_analytics`, ligado só com `GA_MEASUREMENT_ID` no `.env` (compose e Kamal; vazio em dev); as navegações do Turbo são contadas pela medição aprimorada do GA4, e o `share-card` envia o evento `share_card` (method: share/download, period). O card compartilhável traz um QR code: `Sharing::QrCode` gera a matriz no servidor (gem `rqrcode_core`) e o canvas só pinta os módulos, com o módulo arredondado para pixel inteiro senão a câmera não lê; ele aponta para `/qr` (`SharesController`), endereço curto de propósito, que redireciona para a landing com a marcação `utm_source=share_card`. Consent Mode: cookies começam negados e o banner `layouts/_cookie_banner` (controller `cookie-consent`, escolha em localStorage `economiza-cookies`) libera ao aceitar.
- **App na Google Play** — O app é o próprio PWA numa Trusted Web Activity, gerada pelo Bubblewrap a partir de `android/twa-manifest.json` (único arquivo de fonte; o resto do projeto Android é gerado e está no `.gitignore`). Package `br.com.poupinho`. Mudança de produto chega ao app pelo deploy do Rails, sem passar pela loja. `WellKnownController` serve `/.well-known/assetlinks.json` a partir de `ANDROID_FINGERPRINTS` (SHA-256 dos certificados, separados por vírgula, no `config/deploy.yml`); vazio responde 404 de propósito, para a falta de configuração aparecer em vez de virar verificação que falha em silêncio. Passo a passo de assinatura e publicação em [android/README.md](android/README.md). Textos e imagens da ficha da loja em [android/ficha-da-loja.md](android/ficha-da-loja.md) e `android/loja/`. A Play exige que quem cria conta consiga apagá-la: `ProfilesController#destroy` apaga o usuário e tudo que depende dele, confirmado pelo e-mail digitado (e não pela senha, porque contas do Google não têm uma que o usuário conheça), e `/excluir-conta` explica o processo em público, para quem não tem o app instalado.
- **Admin** — área somente leitura em `/admin` (`Admin::BaseController` exige `user.admin?`; `Admin::Overview` agrega o sistema; usuários com busca e detalhe). Conceder acesso com `bin/rails admin:grant[email]`. Item "Painel do sistema" no menu do usuário só para admins.
- **Controllers** — finos; sempre escopar pelo usuário logado (`current_user.savings`, `current_user.categories`) — nunca `Saving.find`. Autenticação nativa do Rails 8 (`Authentication` concern, `Current.user`). `SavingsController#create` aceita `return_to` (validado com `url_from`) para o registro rápido no dashboard.
- **Views** — ERB + Bootstrap 5 vendored em [app/assets/vendor/](app/assets/vendor/) + Hotwire + Chartkick. Zero Node.js. Classes CSS próprias usam prefixo `ec-` ([app/assets/stylesheets/theme.css](app/assets/stylesheets/theme.css)). Tema claro/escuro via `data-bs-theme` + localStorage (`economiza-theme`).
- **Helpers** — `format_brl` (R$ 1.234,56), `brl_input_value` (valor para input com máscara), `category_badge` / `category_icon`.
- **JS** — Stimulus controllers em [app/javascript/controllers/](app/javascript/controllers/): `theme`, `toasts`, `password-toggle`, `currency-mask` (o campo de valor envia `1234.56` no submit), `phone-mask` (celular "(11) 91234-5678"; o model guarda só dígitos), `network-status`, `pwa-install`, `hscroll` (faixa rolável: roda do mouse e arrastar rolam para o lado), `carousel` (faixa que avança sozinha; depoimentos da landing), `demo` (mini-telas interativas do "Como funciona"), `celebrate` (confete ao aparecer; usado no toast de novo nível), `share-card` (card compartilhável: desenha em canvas 1080x1920 o total do período com nível e sequência, entrega via `navigator.share` com arquivo ou download; modal em `dashboard/_share_card`, botão no card do total). O confete em canvas vive em `app/javascript/confetti.js` (pin `confetti`), compartilhado por `demo` e `celebrate`, `slides` (carrossel de telas do mock do hero), `parallax`/`simulator` (landing).
- **Layout autenticado** — topbar com nav horizontal no desktop (≥768px); no mobile, barra inferior flutuante (`layouts/_bottom_nav`) com o botão `+` central maior, saltando acima da barra (sem FAB separado; no desktop o botão de nova economia fica na topbar). Helpers `main_nav_items`/`nav_link` centralizam os itens. Cores/superfícies em variáveis `--brand-*` e `--ec-*` no topo de theme.css.

## Conventions

- **Idioma:** labels, mensagens, e-mails em pt-BR. I18n em [config/locales/](config/locales/) (`pt-BR.yml` = base Rails + nomes de atributos; `app.pt-BR.yml` = textos das telas).
- **Formatação pt-BR:** moeda `R$ 1.234,56`, data `DD/MM/AAAA`.
- **Sem gem `bootstrap`** (incompatível com Propshaft) — usar os arquivos vendored.
- **Testes:** Minitest com fixtures em [test/fixtures/](test/fixtures/). Integração cobre cada tela; services têm testes próprios em `test/services/`. Rodar `make test` e `make lint` antes de finalizar.
