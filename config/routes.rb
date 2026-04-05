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
    member do
      get :setup
      post :setup, action: :create
      get :setup_unavailable
      get :war_data
    end

    resources :ranked_wars, only: [ :show ], controller: "factions/ranked_wars"
    resource :war_history, only: [ :show ], controller: "factions/war_history"

    resource :leadership, only: [ :show ], controller: "factions/leadership" do
      get :war_data

      resource :setup, only: [ :show, :update ], controller: "factions/leadership/setup"

      resource :api_keys, only: [ :update, :destroy ], controller: "factions/leadership/api_keys"
      resource :leadership_access, only: [ :create, :destroy ], controller: "factions/leadership/leadership_access"
      resource :subscriptions, only: [ :create ], controller: "factions/leadership/subscriptions"
      resource :spy_imports, only: [ :create ], controller: "factions/leadership/spy_imports"
      resource :faction_data, only: [ :destroy ], controller: "factions/leadership/faction_data"

      resource :war_history, only: [ :show ], controller: "factions/leadership/war_history" do
        post :refresh
      end
      resource :spy_reports, only: [ :show ], controller: "factions/leadership/spy_reports" do
        patch "/:id", to: "factions/leadership/spy_reports#update", as: :update_report
        delete "/:id", to: "factions/leadership/spy_reports#destroy", as: :destroy_report
        post :fetch_enemy
      end
      resource :war_reports, only: [ :show ], controller: "factions/leadership/war_reports" do
        post :fetch_attacks
      end
      resource :settings, only: [ :show ], controller: "factions/leadership/settings"
      resource :api_logs, only: [ :show ], controller: "factions/leadership/api_logs"
      resource :data_coverage, only: [ :show ], controller: "factions/leadership/data_coverage" do
        post :backfill_user
      end

      resource :war_polling, only: [], controller: "factions/leadership/war_polling" do
        post :start
        delete :stop
      end
    end

    get :public_war, controller: "factions/public_war", action: :show
  end
  resources :public_wars, only: [ :index, :create, :show, :destroy ], param: :slug do
    member do
      post :unlock
      get :war_data
      post :stats
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

  get "userscript",                        to: "userscript#index",    as: :userscript
  get "userscript/tornmanager.user.js",    to: "userscript#download", as: :userscript_download

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
        patch :toggle_ssl
        patch :toggle_public_wars
      end
    end
    resources :api_logs, only: [ :index ]
    resources :script_versions, except: [ :show ]
    resources :snapshot_management, only: [ :index ] do
      member do
        post :backfill_user
      end
    end
    resource :recon, only: [ :show ], controller: "recon" do
      post :import
    end
  end

  get "legal", to: "pages#legal", as: :legal
  get "privacy-policy", to: redirect("/legal#privacy-policy")
  get "terms-of-service", to: redirect("/legal#terms-of-service")

  get "key-log", to: "key_log#index", as: :key_log
  post "key-log/show", to: "key_log#show", as: :key_log_show
  get "key-log/show", to: redirect("/key-log")

  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
