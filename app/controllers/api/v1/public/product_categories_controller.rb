# frozen_string_literal: true

module Api
  module V1
    module Public
      class ProductCategoriesController < ApplicationController
        include ApiErrorHandling

        # GET /api/v1/public/shops/:shop_slug/categories
        def index
          result = resolve_shop
          return render_not_found unless result.found? && result.shop.active?

          categories = result.shop.product_categories.published
                             .where(parent_id: nil)
                             .includes(children: :children)
                             .order(:position, :created_at)

          render json: categories,
                 each_serializer: PublicProductCategorySerializer,
                 status: :ok
        end

        private

        def resolve_shop
          @resolve_shop ||= Shops::ResolvePublicSlug.new(slug: params[:shop_slug]).call
        end
      end
    end
  end
end
