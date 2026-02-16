Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount ActionCable.server => "/cable"

  resource :session
  resources :progress, only: [ :index ]
  resources :faction, only: [ :index ] do
    collection do
      get "members/:torn_id", to: "faction#member", as: "member"
    end
  end
  resources :ranked_war, only: [ :index ]
  resources :welcome, only: [ :index ]

  get "hall-of-famers", to: "hall_of_famers#index", as: :hall_of_famers

  get "user/api-calls", to: "user_api_calls#index", as: :user_api_calls

  get "settings", to: "settings#index", as: :settings
  get "settings/api_key_card", to: "settings#api_key_card", as: :settings_api_key_card
  delete "settings/purge_data", to: "settings#purge_data", as: :settings_purge_data
  post "settings/refresh_subscription", to: "settings#refresh_subscription", as: :settings_refresh_subscription
  patch "settings/update_api_key", to: "settings#update_api_key", as: :settings_update_api_key
  get "settings/export_data", to: "settings#export_data", as: :settings_export_data

  namespace :admin do
    get "/", to: "dashboard#index", as: :dashboard
    resources :subscriptions, only: [ :index ] do
      collection do
        get :faction_grant
        post :create_faction_grant
      end
      member do
        patch :update_days
      end
    end
    resources :factions, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :toggle_tracking
        post :sync_members
        post :backfill_stats
        post :backfill_user_stats
      end
    end
    resources :api_logs, only: [ :index ]
  end

  get "privacy-policy", to: "pages#privacy_policy", as: :privacy_policy
  get "terms-of-service", to: "pages#terms_of_service", as: :terms_of_service

  get "key-log", to: "key_log#index", as: :key_log
  post "key-log/show", to: "key_log#show", as: :key_log_show
  get "key-log/show", to: redirect("/key-log")

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
