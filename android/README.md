# Poupinho na Google Play (TWA)

O app da Play é o próprio PWA rodando numa Trusted Web Activity: uma casca
Android que abre `https://poupinho.com.br` em tela cheia, sem barra de endereço.
Não há código de aplicação aqui. Toda mudança de produto sai pelo deploy normal
do Rails e chega ao app sem passar pela loja.

O único arquivo de fonte é o `twa-manifest.json`. Todo o resto do projeto
Android é gerado, e por isso está no `.gitignore`:

```
cd android && npx @bubblewrap/cli update --skipVersionUpgrade
```

## Pré-requisitos já resolvidos nesta máquina

JDK 17 em `~/jdk17` e Android SDK em `~/Android/Sdk`, apontados no
`~/.bubblewrap/config.json`.

## 1. Criar a chave de upload (uma vez, e só você)

A senha da keystore não deve passar por mais ninguém. Guarde a senha no
gerenciador e o arquivo fora do repositório, com backup.

```
cd android
keytool -genkeypair -v -keystore poupinho.keystore -alias poupinho \
  -keyalg RSA -keysize 2048 -validity 10000
```

## 2. Gerar o pacote assinado

```
cd android
export BUBBLEWRAP_KEYSTORE_PASSWORD='...' BUBBLEWRAP_KEY_PASSWORD='...'
npx @bubblewrap/cli build --skipPwaValidation
```

Sai o `app-release-bundle.aab`, que é o arquivo enviado à Play.

## 3. Ligar o app ao domínio

Sem esta etapa o app abre com a barra de endereço do Chrome por cima, que é o
sintoma clássico de Digital Asset Links faltando.

O certificado que assina o que chega no celular é o do Play App Signing, não a
sua chave de upload. Depois do primeiro envio, o SHA-256 dele aparece no Play
Console em Configuração, Integridade do app. Pegue os dois, o do Play App
Signing e o da chave de upload, e coloque em `ANDROID_FINGERPRINTS` no
`config/deploy.yml`, separados por vírgula. Depois faça o deploy do Rails.

Conferir depois do deploy:

```
curl https://poupinho.com.br/.well-known/assetlinks.json
```

Enquanto a variável estiver vazia essa rota responde 404 de propósito, para a
falta de configuração ficar visível em vez de virar uma verificação que falha
em silêncio.

## 4. Versões seguintes

O `versionCode` precisa subir a cada envio. O Bubblewrap cuida disso quando
você roda `update` sem o `--skipVersionUpgrade`.
