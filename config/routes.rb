Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount ActionCable.server => "/cable"

  namespace :api do
    resource :session, only: [ :create ]
    post :subscription, to: "subscriptions#show"
    post :war, to: "wars#show"
    post :current_war, to: "current_war#show"
  end

  resource :session
  resources :stocks, only: [ :index ]
  resources :factions, only: [ :index, :show ], param: :torn_id do
    resource :training, only: [ :show ], controller: "factions/training" do
      get "members/:torn_id", to: "factions/training#member", as: "member"
    end
    resources :ranked_wars, only: [ :index, :show ], controller: "factions/ranked_wars" do
      member do
        get :war_data
      end
    end
    resource :settings, only: [ :show, :update ], controller: "factions/settings" do
      post :import_spies
      post :add_whitelist
      post :share_subscription
      delete :remove_whitelist
      delete :delete_torn_key
      delete :delete_tornstats_key
    end
    resource :spy_stats, only: [ :show ], controller: "factions/spy_stats"
    resource :war_polling, only: [], controller: "factions/war_polling" do
      post :start
      delete :stop
    end
  end
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
    resources :stats, only: [ :index ]
    resources :subscriptions, only: [ :index ] do
      collection do
        post :grant
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
        post :backfill_wars
      end
    end
    resources :api_logs, only: [ :index ]
    resources :snapshot_management, only: [ :index ] do
      member do
        post :backfill_user
      end
    end
  end

  get "roadmap", to: "roadmap#index", as: :roadmap
  post "roadmap", to: "roadmap#create"
  patch "roadmap/:id", to: "roadmap#update", as: :roadmap_item
  delete "roadmap/:id", to: "roadmap#destroy"

  get "privacy-policy", to: "pages#privacy_policy", as: :privacy_policy
  get "terms-of-service", to: "pages#terms_of_service", as: :terms_of_service

  get "key-log", to: "key_log#index", as: :key_log
  post "key-log/show", to: "key_log#show", as: :key_log_show
  get "key-log/show", to: redirect("/key-log")

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
