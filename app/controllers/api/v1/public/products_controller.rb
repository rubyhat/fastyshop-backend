# frozen_string_literal: true

module Api
  module V1
    module Public
      class ProductsController < ApplicationController
        include ApiErrorHandling

        # GET /api/v1/public/shops/:shop_slug/products
        def index
          result = resolve_shop
          return render_not_found unless result.found? && result.shop.active?

          products = result.shop.products.published.includes(:product_category).order(:position, :created_at)
          products = filter_by_category(products, result.shop)

          render json: products,
                 each_serializer: PublicProductSerializer,
                 status: :ok
        end

        # GET /api/v1/public/shops/:shop_slug/products/:product_slug
        def show
          result = resolve_shop
          return render_not_found unless result.found? && result.shop.active?

          product = result.shop.products.published.includes(:product_category).find_by(slug: params[:product_slug])
          return render_not_found unless product

          render json: product,
                 serializer: PublicProductSerializer,
                 status: :ok
        end

        private

        def resolve_shop
          @resolve_shop ||= Shops::ResolvePublicSlug.new(slug: params[:shop_slug]).call
        end

        def filter_by_category(products, shop)
          if params[:category_slug].present?
            category = shop.product_categories.published.find_by(slug: params[:category_slug])
            return products.none unless category

            products.where(product_category_id: [ category.id ] + category.descendant_ids)
          elsif ActiveModel::Type::Boolean.new.cast(params[:include_uncategorized])
            products
          else
            products
          end
        end
      end
    end
  end
end
