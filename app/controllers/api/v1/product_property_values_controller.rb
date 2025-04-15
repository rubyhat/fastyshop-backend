# frozen_string_literal: true

module Api
  module V1
    class ProductPropertyValuesController < BaseController
      before_action :set_product
      before_action :set_value, only: %i[show update destroy]

      # GET /api/v1/shops/SHOP_UUID/products/PRODUCT_UUID/product_property_values
      def index
        @values = @product.product_property_values.where(product: @product)

        authorize ProductPropertyValue

        if @values
          render json: @values, status: :ok
        else
          render_validation_errors @values
        end
      end

      def show
        authorize @value

        if @value
          render json: @value, status: :ok
        else
          render_validation_errors @value
        end
      end

      # POST /api/v1/shops/SHOP_UUID/products/PRODUCT_UUID/product_property_values
      def create
        @value = @product.product_property_values.new(property_value_params)
        authorize @value, :create?

        if @value.save
          render json: @value, status: :created
        else
          render_validation_errors @value
        end
      end

      # PATCH /api/v1/shops/SHOP_UUID/products/PRODUCT_UUID/product_property_values/PRODUCT_PROPERTY_VALUE_ID
      def update
        authorize @value, :update?

        if @value.update(property_value_params)
          render json: @value, status: :ok
        else
          render_validation_errors @value
        end
      end

      # DELETE /api/v1/shops/SHOP_UUID/products/PRODUCT_UUID/product_property_values/PRODUCT_PROPERTY_VALUE_ID
      def destroy
        authorize @value, :destroy?

        if @value.destroy
          render_success(
            key: "property_value.deleted",
            message: "Значение успешно удалено",
            code: 200
          )
        else
          render_validation_errors @value
        end
      end

      private

      def set_product
        @product = Product.find(params[:product_id])
      end

      def set_value
        @value = @product.product_property_values.find(params[:id])
      end

      def property_value_params
        params.require(:product_property_value).permit(:value, :product_property_id)
      end
    end
  end
end
