# frozen_string_literal: true

module Api
  module V1
    module Public
      class ShopsController < ApplicationController
        include ApiErrorHandling

        # GET /api/v1/public/shops/catalog
        def catalog
          shops = Shop.active.includes(:shop_category, :legal_profile).order(created_at: :desc)
          render json: shops, each_serializer: PublicShopCatalogSerializer, status: :ok
        end

        # GET /api/v1/public/shops/:slug
        def show
          result = resolve_shop
          return render_not_found unless result.found?

          render json: result.shop,
                 serializer: PublicShopSerializer,
                 requested_slug: result.requested_slug,
                 status: :ok
        end

        # GET /api/v1/public/shops/:slug/legal_details
        def legal_details
          result = resolve_shop
          return render_not_found unless result.found?

          render json: result.shop,
                 serializer: PublicShopLegalDetailsSerializer,
                 status: :ok
        end

        # GET /api/v1/public/shops/:slug/change_history
        def change_history
          result = resolve_shop
          return render_not_found unless result.found?

          events = result.shop.change_events.order(created_at: :desc).limit(50)
          render json: events,
                 each_serializer: PublicShopChangeEventSerializer,
                 status: :ok
        end

        private

        def resolve_shop
          @resolve_shop ||= Shops::ResolvePublicSlug.new(slug: params[:slug]).call
        end
      end
    end
  end
end
