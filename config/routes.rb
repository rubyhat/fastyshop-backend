Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
  get "up" => "rails/health#show", as: :rails_health_check
  get "status", to: "health#status"


  namespace :api do
    namespace :v1 do
      # Аутентификация
      post "auth/login",   to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout",  to: "auth#logout"

      # Текущий пользователь
      get :me, to: "users#me"

      # Пользователи
      resources :users, only: %i[create update show destroy index] do
        get :seller_profile, to: "seller_profiles#show_by_user"
      end

      # Профиль продавца
      resources :seller_profiles, only: %i[create update show index]

      # Юридические профили
      resources :legal_profiles, only: %i[index show create update] do
        member do
          patch :unverify
        end
      end

      # Магазины
      resources :shops, only: %i[index show create update destroy] do
        collection do
          get :catalog
        end

        # Категории товаров/услуг магазина
        resources :product_categories, only: %i[index show create update destroy]

        # Товары/услуги магазина
        resources :products, only: %i[index show create update destroy] do
          resources :product_property_values, only: %i[index show create update destroy]
        end
      end

      # Категории магазинов
      resources :shop_categories, only: %i[index show]

      # Коллекция свойств для товаров/услуг
      resources :product_properties, only: %i[index show create update destroy]
    end
  end
end
