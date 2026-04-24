Rails.application.routes.draw do
  if Rails.env.development? || Rails.env.test?
    mount Rswag::Ui::Engine => "/api-docs"
    mount Rswag::Api::Engine => "/api-docs"
  end

  get "up" => "rails/health#show", as: :rails_health_check
  get "status", to: "health#status"


  namespace :api do
    namespace :v1 do
      # Аутентификация
      post "auth/signup",  to: "auth#signup"
      post "auth/login",   to: "auth#login"
      post "auth/refresh", to: "auth#refresh"
      post "auth/logout",  to: "auth#logout"

      # Текущий пользователь
      get :me, to: "users#me"

      # Пользователи
      resources :users, only: %i[create update show destroy index] do
        member do
          patch :account_status, to: "users#update_account_status"
        end

        get :seller_profile, to: "seller_profiles#show_by_user"
      end

      # Адреса пользователей
      resources :user_addresses, only: %i[index show create update destroy]

      # Профиль продавца
      resources :seller_profiles, only: %i[create update show index]

      post "seller_onboarding", to: "seller_onboarding#create"

      # Юридические профили
      resources :legal_profiles, only: %i[index show create update] do
        member do
          post :submit_verification
          post :approve
          post :reject
          get :verification_events
        end
      end

      namespace :public do
        resources :legal_profiles, only: [] do
          member do
            get :transparency
          end
        end

        get "shops/catalog", to: "shops#catalog"
        get "shops/:shop_slug/categories", to: "product_categories#index"
        get "shops/:shop_slug/products", to: "products#index"
        get "shops/:shop_slug/products/:product_slug", to: "products#show"
        get "shops/:slug", to: "shops#show"
        get "shops/:slug/legal_details", to: "shops#legal_details"
        get "shops/:slug/change_history", to: "shops#change_history"
      end

      # Магазины
      resources :shops, only: %i[index show create update destroy] do
        collection do
          get :catalog
        end

        member do
          post :disable
          post :activate
          post :suspend
        end

        # Категории товаров/услуг магазина
        resources :product_categories, only: %i[index show create update destroy] do
          member do
            post :publish
            post :archive_preview
            post :archive
            post :restore
          end

          collection do
            post :reorder
          end
        end

        # Товары/услуги магазина
        resources :products, only: %i[index show create update destroy] do
          member do
            post :publish
            post :archive
            post :restore
          end

          resources :product_property_values, only: %i[index show create update destroy]
        end

        resources :customers, only: %i[index show], controller: "shop_customers", param: :user_id
      end

      # Категории магазинов
      resources :shop_categories, only: %i[index show]

      # Коллекция свойств для товаров/услуг
      resources :product_properties, only: %i[index show create update destroy]

      # Корзины пользователя в магазине
      resources :carts, only: %i[index show], param: :shop_id do
        member do
          post "add", to: "carts#add_item"
          post "remove/:product_id", to: "carts#remove_item"
        end
      end

      # Заказы
      resources :orders, only: %i[index show] do
        member do
          get :events
        end

        collection do
          post "from_cart/:shop_id", to: "orders#create_from_cart"
        end
      end
      get "/my/orders", to: "orders#my_orders"
      get "/shops/:shop_id/orders", to: "orders#shop_orders"
      patch "/orders/:id/status", to: "orders#update_status"
    end
  end
end
