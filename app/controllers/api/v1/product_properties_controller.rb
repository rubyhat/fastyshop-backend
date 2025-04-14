# frozen_string_literal: true

module Api
  module V1
    class ProductPropertiesController < BaseController
      before_action :set_product_property, only: %i[show update destroy]

      def index
        authorize ProductProperty, :index?

        product_properties = policy_scope(ProductProperty)
        render json: product_properties, status: :ok
      end

      def show
        authorize @product_property, :show?
        render json: @product_property, status: :ok
      end

      def create
        user = current_user
        return unless user

        product_property = user.product_properties.new(
          product_property_params.merge(source_type: :user)
        )

        authorize product_property, :create?

        if product_property.save
          render json: product_property, status: :created
        else
          render_validation_errors product_property
        end
      end

      def update
        authorize @product_property, :update?

        if @product_property.update(product_property_params)
          render json: @product_property, status: :ok
        else
          render_validation_errors @product_property
        end
      end

      def destroy
        authorize @product_property, :destroy?

        if @product_property.destroy
          render_success(
            key: "product_property.destroyed",
            message: "Свойство успешно удалено",
            code: 200
          )
        else
          render_validation_errors @product_property
        end
      end

      private

      def set_product_property
        @product_property = ProductProperty.find(params[:id])
      end

      def product_property_params
        params.require(:product_property)
              .permit(:title, :value_type)
      end
    end
  end
end
