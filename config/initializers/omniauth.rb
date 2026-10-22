# Login com Google. Sem GOOGLE_CLIENT_ID/SECRET o botão não aparece (ver OmniauthSessionsController.configured?).
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2, ENV["GOOGLE_CLIENT_ID"], ENV["GOOGLE_CLIENT_SECRET"],
           scope: "email,profile", prompt: "select_account", access_type: "online"
end

# Só POST inicia o fluxo (omniauth-rails_csrf_protection exige o token CSRF).
OmniAuth.config.allowed_request_methods = %i[post]
OmniAuth.config.logger = Rails.logger
