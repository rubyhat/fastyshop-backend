# frozen_string_literal: true

module Api
  module V1
    class ProductCategoriesController < BaseController
      skip_before_action :authenticate_user!, only: %i[index show]

      before_action :set_shop
      before_action :set_product_category, only: %i[show update destroy]
      before_action :authorize_product_category!, only: %i[create update destroy]

      # GET /shops/:shop_id/product_categories
      def index
        categories = policy_scope(@shop.product_categories.includes(:children))
        render json: categories, status: :ok
      end

      # GET /shops/:shop_id/product_categories/:id
      def show
        render json: @product_category, status: :ok
      end

      # POST /shops/:shop_id/product_categories
      def create
        @product_category = @shop.product_categories.new(product_category_params)
        authorize @product_category

        if @product_category.save
          render json: @product_category, status: :created
        else
          render_validation_errors(@product_category)
        end
      end

      # PATCH /shops/:shop_id/product_categories/:id
      def update
        authorize @product_category

        if @product_category.update(product_category_params_for_update)
          render json: @product_category, status: :ok
        else
          render_validation_errors(@product_category)
        end
      end

      # DELETE /shops/:shop_id/product_categories/:id
      def destroy
        authorize @product_category

        if @product_category.destroy
          render_success(
            key: "product_category.deleted",
            message: "Категория, все вложенные категории и товары успешно удалёны",
            code: 200
          )
        else
          render_validation_errors(@product_category)
        end
      end

      private

      def set_shop
        @shop = Shop.find(params[:shop_id])
      end

      def set_product_category
        @product_category = @shop.product_categories.find(params[:id])
      end

      def authorize_product_category!
        authorize @product_category || ProductCategory.new(shop: @shop)
      end

      def product_category_params
        params.require(:product_category).permit(:title, :parent_id)
      end

      def product_category_params_for_update
        params.require(:product_category).permit(:title, :parent_id, :position, :is_active)
      end
    end
  end
end
