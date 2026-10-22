Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resource :registration, only: [ :new, :create ]
  resource :profile, only: [ :edit, :update, :destroy ]
  resource :push_subscription, only: [ :create, :destroy ]

  # Login com Google (OmniAuth) e onboarding do celular.
  get "auth/:provider/callback", to: "omniauth_sessions#create", as: :omniauth_callback
  get "auth/failure", to: "omniauth_sessions#failure"
  get "onboarding/phone", to: "onboarding#phone", as: :onboarding_phone
  patch "onboarding/phone", to: "onboarding#save_phone"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  resources :savings
  resources :categories, except: [ :show ]
  resources :goals, except: [ :show ]

  get "reports", to: "reports#index", as: :reports
  # Dicas para poupar: páginas públicas, indexáveis, listadas no sitemap.
  get "dicas", to: "tips#index", as: :tips
  get "dicas/:slug", to: "tips#show", as: :tip

  get "sitemap.xml", to: "sitemap#show", as: :sitemap, format: :xml

  # Endereço curto do QR code do card compartilhável (redireciona para a landing).
  get "qr", to: "shares#qr", as: :share_qr

  # Digital Asset Links do app Android (TWA). O ".json" faz parte do caminho que
  # o Android busca, então não é o formato da resposta: daí o format: false.
  get ".well-known/assetlinks.json", to: "well_known#assetlinks", as: :assetlinks, format: false

  get "dashboard", to: "dashboard#index", as: :dashboard

  # Área administrativa (somente leitura), para usuários com admin: true.
  namespace :admin do
    root "dashboard#index"
    resources :users, only: [ :index, :show ]
  end

  # Páginas legais públicas.
  get "privacidade", to: "legal#privacy", as: :privacy
  get "termos", to: "legal#terms", as: :terms
  # Exigência da Google Play: quem não tem o app instalado precisa achar, pela
  # web, como pedir a exclusão da conta.
  get "excluir-conta", to: "legal#account_deletion", as: :account_deletion

  # Landing pública (logado ou não). O app em si vive em /dashboard.
  root "home#index"
end
