Rails.application.routes.draw do
  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount ActionCable.server => "/cable"

  namespace :api do
    resource :session, only: [ :create ]
    post :subscription, to: "subscriptions#show"
    post :war, to: "wars#show"
    post :current_war, to: "current_war#show"

    scope :chat do
      post :rooms, to: "chat_rooms#index", as: :chat_rooms
      post :create_room, to: "chat_rooms#create", as: :chat_create_room
      post :join, to: "chat_rooms#join", as: :chat_join
      post :join_public, to: "chat_rooms#join_public", as: :chat_join_public
      post :leave, to: "chat_rooms#leave", as: :chat_leave
      post :room_members, to: "chat_rooms#members", as: :chat_room_members
      post :suspend, to: "chat_rooms#suspend", as: :chat_suspend
      post :unsuspend, to: "chat_rooms#unsuspend", as: :chat_unsuspend
      post :messages, to: "chat_messages#index", as: :chat_messages
      post :send_message, to: "chat_messages#create", as: :chat_send_message
      post :send_image, to: "chat_messages#create_image", as: :chat_send_image
      post :image, to: "chat_messages#image", as: :chat_image
    end

    scope :recruiter do
      post :matches, to: "recruiter_matches#index", as: :recruiter_matches
      post :status, to: "recruiter_status#show", as: :recruiter_status
      post :submit_key, to: "recruiter_keys#create", as: :recruiter_submit_key
      post :keys, to: "recruiter_keys#index", as: :recruiter_keys
      post :revoke_key, to: "recruiter_keys#destroy", as: :recruiter_revoke_key
    end
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
        patch :save_payout_settings
      end
      resource :settings, only: [ :show ], controller: "factions/leadership/settings"
      resource :api_logs, only: [ :show ], controller: "factions/leadership/api_logs"
      resource :data_coverage, only: [ :show ], controller: "factions/leadership/data_coverage" do
        post :backfill_user
      end
      resource :activity, only: [ :show ], controller: "factions/leadership/activity"

      resource :armory, only: [ :show ], controller: "factions/leadership/armory" do
        post :sync
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
    get "recruiter", to: "recruiter#show"
    get "recruiter/section/:name", to: "recruiter#section", as: :recruiter_section
    post "recruiter/run/:job", to: "recruiter#run", as: :recruiter_run
    resources :stats, only: [ :index ]
    get "stats/section/:name", to: "stats#section", as: :stats_section
    resources :subscriptions, only: [ :index ] do
      collection do
        post :grant
      end
      member do
        patch :update_days
      end
    end
    post "impersonate/:id", to: "impersonation#create", as: :impersonate
    resources :factions, only: [ :index, :new, :create, :edit, :update, :destroy ] do
      member do
        patch :toggle_ssl
        patch :toggle_public_wars
        post :backfill_armory_news
      end
    end
    resources :api_logs, only: [ :index ]
    resources :snapshot_management, only: [ :index ] do
      member do
        post :backfill_user
      end
    end
    resource :recon, only: [ :show ], controller: "recon" do
      post :import
      post :import_file
      get :stats
      post :predict
      post :quick_add
    end
  end

  get "legal", to: "pages#legal", as: :legal
  get "privacy-policy", to: redirect("/legal#privacy-policy")
  get "terms-of-service", to: redirect("/legal#terms-of-service")

  get "key-log", to: "key_log#index", as: :key_log
  post "key-log/show", to: "key_log#show", as: :key_log_show
  get "key-log/show", to: redirect("/key-log")

  get "service-worker" => proc { [ 204, {}, [ "" ] ] }
  get "up" => "rails/health#show", as: :rails_health_check

  root "home#index"
end
