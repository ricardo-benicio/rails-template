# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # ============================================
  # Devise Routes (Web)
  # ============================================
  devise_for :users,
    skip: [ :sessions, :registrations, :passwords, :confirmations ],
    controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }

  devise_scope :user do
    # Sessions
    get "login", to: "devise/sessions#new", as: :new_user_session
    post "login", to: "devise/sessions#create", as: :user_session
    delete "logout", to: "devise/sessions#destroy", as: :destroy_user_session

    # Registrations
    get "signup", to: "devise/registrations#new", as: :new_user_registration
    post "signup", to: "devise/registrations#create", as: :user_registration
    get "account", to: "devise/registrations#edit", as: :edit_user_registration
    patch "account", to: "devise/registrations#update"
    put "account", to: "devise/registrations#update"
    delete "account", to: "devise/registrations#destroy"

    # Password recovery
    get "password/new", to: "devise/passwords#new", as: :new_user_password
    post "password", to: "devise/passwords#create", as: :user_password
    get "password/edit", to: "devise/passwords#edit", as: :edit_user_password
    patch "password", to: "devise/passwords#update"
    put "password", to: "devise/passwords#update"

    # Confirmation
    get "confirmation/new", to: "devise/confirmations#new", as: :new_user_confirmation
    post "confirmation", to: "devise/confirmations#create", as: :user_confirmation
    get "confirmation", to: "devise/confirmations#show"
  end

  # ============================================
  # Health Check
  # ============================================
  get "up" => "rails/health#show", as: :rails_health_check

  # ============================================
  # API Documentation (Swagger)
  # ============================================
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"

  # ============================================
  # Sidekiq Web UI (protected)
  # ============================================
  authenticate :user, ->(user) { user.admin? } do
    mount Sidekiq::Web => "/sidekiq"
  end

  # ============================================
  # API Routes (v1)
  # ============================================
  namespace :api do
    namespace :v1 do
      # Authentication
      namespace :auth do
        post "sign_in", to: "sessions#create"
        delete "sign_out", to: "sessions#destroy"
        post "sign_up", to: "registrations#create"
        post "password", to: "passwords#create"
        put "password", to: "passwords#update"
        post "confirmation", to: "confirmations#create"
        get "confirmation", to: "confirmations#show"
      end

      # Current user
      get "users/me", to: "users#me"
      patch "users/me", to: "users#update_me"
    end
  end

  # ============================================
  # PWA (Progressive Web App)
  # ============================================
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ============================================
  # Admin Dashboard (Administrate)
  # ============================================
  namespace :admin do
    resources :users do
      member do
        patch :restore
        delete :permanently_destroy
      end
    end

    root to: "users#index"
  end

  # ============================================
  # Root Path
  # ============================================
  root "home#index"

  # Flipper feature flags UI (admin only)
  constraints(->(req) { req.session[:user_id].present? }) do
    mount Flipper::UI.app(Flipper) => '/admin/flipper', as: :flipper
  end
end
