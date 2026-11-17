Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      get "meta" => "meta#show"
      resources :drafts, only: %i[create show] do
        resources :rounds, only: :create
        resources :picks, only: :create
      end
      resources :fighters, only: %i[index show]
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
