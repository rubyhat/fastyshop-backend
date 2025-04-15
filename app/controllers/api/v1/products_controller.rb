# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      skip_before_action :authenticate_user!, only: %i[index show]

      before_action :set_shop
      before_action :set_product, only: %i[show update destroy]

      def index
        products = policy_scope(@shop.products.includes(:product_category, product_property_values: :product_property))
        render json: products, status: 200
      end

      def show
        authorize @product, :show?
        render json: @product, status: 200
      end

      def create
        @product = @shop.products.new(product_create_params)
        authorize @product, :create?

        if @product.save
          render json: @product, status: 201
        else
          render_validation_errors(@product)
        end
      end

      def update
        authorize @product, :update?

        if @product.update(product_update_params)
          render json: @product, status: 200
        else
          render_validation_errors(@product)
        end
      end

      def destroy
        authorize @product, :destroy?

        if @product.destroy
          render_success(
            key: "product.deleted",
            message: "Успешно удалено",
            code: 200
          )
        else
          render_validation_errors(@product)
        end
      end

      private

      def set_shop
        @shop = Shop.find(params[:shop_id])
      end

      def set_product
        @product = Product.find(params[:id])
      end

      def product_create_params
        params.require(:product).permit(
          :title,
          :description,
          :price,
          :product_type,
          :product_category_id
        )
      end

      def product_update_params
        params.require(:product).permit(
          :title,
          :description,
          :price,
          :product_type,
          :product_category_id,
          :is_active,
          :position
        )
      end
    end
  end
end
