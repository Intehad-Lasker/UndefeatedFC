Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/admin/jobs"

  namespace :admin do
    root "dashboard#show"
    resources :fighters, only: %i[index show edit update]
    resources :weight_classes, only: %i[index update]
    resources :eras, only: %i[index edit update]
    resources :ingestion_runs, only: :index do
      post :refresh_ratings, on: :collection
    end
  end

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "meta" => "meta#show"
      resource :session, only: %i[show create destroy]
      resources :users, only: :create
      resources :passwords, only: :create
      resources :drafts, only: %i[index create show] do
        resources :rounds, only: :create
        resources :picks, only: :create
      end
      resources :fighters, only: %i[index show]
      get "leaderboards/daily" => "leaderboards#daily"
      get "leaderboards/all_time" => "leaderboards#all_time"
      resource :daily_challenge, only: :show do
        resource :attempt, only: :create, controller: "daily_challenge_attempts"
      end
    end
  end

  # Any other extension-less path is a page in the React app. Paths with an
  # extension (a missing .png) and Rails' own namespaces still 404 normally.
  root "spa#show"
  get "*path", to: "spa#show", format: false,
    constraints: ->(request) {
      File.extname(request.path).empty? && !request.path.start_with?("/api/", "/rails/", "/admin", "/cable")
    }
end
