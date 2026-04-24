# frozen_string_literal: true

module Api
  module V1
    class ShopsController < BaseController
      skip_before_action :authenticate_user!, only: [ :catalog ]

      # GET /api/v1/shops
      def index
        shops = ShopPolicy::Scope.new(current_user, Shop.includes(:seller_profile, :legal_profile, :shop_category)).resolve_owner_view
        authorize Shop
        render json: shops, each_serializer: ShopSerializer, status: :ok
      end

      # GET /api/v1/shops/catalog
      #
      # Backward-compatible alias. New platform code should use:
      # GET /api/v1/public/shops/catalog
      def catalog
        shops = ShopPolicy::Scope.new(current_user, Shop.includes(:shop_category, :legal_profile)).resolve_catalog
        render json: shops, each_serializer: PublicShopCatalogSerializer, status: :ok
      end

      # GET /api/v1/shops/:id
      def show
        shop = find_shop
        return render_not_found unless shop

        authorize shop, :show?
        render json: shop, serializer: ShopSerializer, status: :ok
      end

      # POST /api/v1/shops
      def create
        seller_profile = seller_profile_for_create
        return render_no_seller_profile unless seller_profile

        shop = seller_profile.shops.build(shop_params)
        authorize shop, :create?

        result = Shops::Create.new(
          seller_profile: seller_profile,
          actor_user: current_user,
          attributes: shop_params
        ).call

        if result.success?
          render json: result.shop, serializer: ShopSerializer, status: :created
        else
          render_validation_errors(result.error_record)
        end
      end

      # PATCH /api/v1/shops/:id
      def update
        shop = find_shop
        return render_not_found unless shop

        authorize shop, :update?

        result = Shops::Update.new(
          shop: shop,
          actor_user: current_user,
          attributes: shop_params
        ).call

        if result.success?
          render json: result.shop, serializer: ShopSerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      # DELETE /api/v1/shops/:id
      def destroy
        disable
      end

      # POST /api/v1/shops/:id/disable
      def disable
        shop = find_shop
        return render_not_found unless shop

        authorize shop, :disable?
        change_status(shop, :disabled_by_owner)
      end

      # POST /api/v1/shops/:id/activate
      def activate
        shop = find_shop
        return render_not_found unless shop

        authorize shop, :activate?
        change_status(shop, :active)
      end

      # POST /api/v1/shops/:id/suspend
      def suspend
        shop = find_shop
        return render_not_found unless shop

        authorize shop, :suspend?
        change_status(shop, :suspended_by_admin, comment: status_params[:comment])
      end

      private

      def find_shop
        Shop.includes(:seller_profile, :legal_profile, :shop_category).find_by(id: params[:id])
      end

      def seller_profile_for_create
        if current_user&.seller?
          current_user.seller_profile
        elsif current_user&.admin?
          SellerProfile.find_by(id: params[:seller_profile_id])
        end
      end

      def render_no_seller_profile
        render_error(
          key: "shops.no_seller_profile",
          message: "Для создания магазина необходим профиль продавца",
          status: :forbidden,
          code: 403
        )
      end

      def change_status(shop, target_status, comment: nil)
        result = Shops::ChangeStatus.new(
          shop: shop,
          actor_user: current_user,
          target_status: target_status,
          comment: comment
        ).call

        if result.success?
          render json: result.shop, serializer: ShopSerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      def shop_params
        params.permit(
          :title,
          :slug,
          :description,
          :logo_url,
          :contact_phone,
          :contact_email,
          :shop_category_id,
          :legal_profile_id,
          :physical_address,
          :shop_type
        )
      end

      def status_params
        params.permit(:comment)
      end
    end
  end
end
