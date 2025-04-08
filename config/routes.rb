Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  namespace :api do
    namespace :v1 do
      post "auth/login",   to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout",  to: "auth#logout"

      get :me, to: "users#me"

      resources :users, only: %i[create update show destroy index]
      resources :seller_profiles, only: %i[create update show index]

      # Просмотр seller_profile по user_id
      get "users/:user_id/seller_profile", to: "seller_profiles#show_by_user"
    end
  end
end
