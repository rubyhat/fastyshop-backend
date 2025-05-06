module Api
  module V1
    class ShopsController < BaseController
      skip_before_action :authenticate_user!, only: [ :catalog, :show ]

      # GET /api/v1/shops
      # Панель продавца: отображает ВСЕ его магазины
      def index
        # todo: Подумать, нужно ли сделать запрос завязанный на user id, чтобы другие пользователи могли бы смотреть все магазины этого пользователя.
        # Чтобы админ мог заходить к пользователю и видеть все магазины? Или это вынести в админку?
        shops = ShopPolicy::Scope.new(current_user, Shop).resolve_owner_view
        authorize Shop
        render json: shops, status: :ok
      end

      # GET /api/v1/catalog/shops
      # Публичный каталог: только активные магазины
      def catalog
        shops = ShopPolicy::Scope.new(current_user, Shop).resolve_catalog
        render json: shops, status: :ok
      end

      # GET /api/v1/shops/:id
      def show
        shop = Shop.find_by(id: params[:id])
        return render_not_found unless shop

        render json: shop, status: :ok
      end

      # POST /api/v1/shops
      def create
        user = current_user
        render_unauthorized unless user

        seller_profile = if user&.seller?
                           user.seller_profile
        elsif user&.superadmin? || user&.supermanager?
                           SellerProfile.find_by(id: params[:seller_profile_id])
        end

        unless seller_profile
          return render_error(
            key: "shops.no_seller_profile",
            message: "Для создания магазина необходим профиль продавца",
            status: :forbidden,
            code: 403
          )
        end

        shop = seller_profile.shops.build(shop_params)
        shop.legal_profile_id = params[:legal_profile_id].to_s.presence

        authorize shop, :create?

        if shop.save
          render json: shop, status: :created
        else
          render_validation_errors(shop)
        end
      end

      # PATCH /api/v1/shops/:id
      def update
        shop = Shop.find_by(id: params[:id])
        render_not_found unless shop

        authorize shop, :update?
        shop.legal_profile_id = params[:legal_profile_id].to_s.presence if params[:legal_profile_id].present?

        if shop.update(shop_params)
          render json: shop, status: :ok
        else
          render_validation_errors(shop)
        end
      end

      # DELETE /api/v1/shops/:id
      def destroy
        shop = Shop.find_by(id: params[:id])
        render_not_found unless shop

        authorize shop, :destroy?

        if shop.update(is_active: false)
          render_success(
            key: "shops.deleted",
            message: "Магазин успешно удален",
            code: 200
          )
        else
          render_validation_errors(shop)
        end
      end

      private

      def shop_params
        params.permit(
        :title,
        :contact_phone,
        :contact_email,
        :shop_category_id,
        :physical_address,
        :shop_type
        )
      end
    end
  end
end
