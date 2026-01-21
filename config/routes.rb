# frozen_string_literal: true

require "sidekiq/web"

Rails.application.routes.draw do
  # ============================================
  # Health Check
  # ============================================
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ============================================
  # Sidekiq Web UI (protected in production)
  # ============================================
  # In development, Sidekiq UI is open
  # In production, it requires admin authentication (configure after Devise setup)
  if Rails.env.development?
    mount Sidekiq::Web => "/sidekiq"
  else
    # After Devise is configured, uncomment and use this:
    # authenticate :user, ->(user) { user.admin? } do
    #   mount Sidekiq::Web => "/sidekiq"
    # end
    mount Sidekiq::Web => "/sidekiq"
  end

  # ============================================
  # PWA (Progressive Web App)
  # ============================================
  # Render dynamic PWA files from app/views/pwa/*
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # ============================================
  # API Routes (will be configured in Phase 4)
  # ============================================
  # namespace :api do
  #   namespace :v1 do
  #     # API routes here
  #   end
  # end

  # ============================================
  # Admin Routes (will be configured in Phase 5)
  # ============================================
  # namespace :admin do
  #   # Administrate routes will be added here
  # end

  # ============================================
  # Root Path
  # ============================================
  # root "home#index"
end
