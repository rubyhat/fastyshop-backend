# frozen_string_literal: true

module Api
  module V1
    class ProductsController < BaseController
      before_action :set_shop
      before_action :set_product, only: %i[show update destroy publish archive restore]

      # GET /api/v1/shops/:shop_id/products
      def index
        authorize Product.new(shop: @shop), :index?

        products = policy_scope(@shop.products.includes(:product_category, product_property_values: :product_property))
        products = products.where(status: params[:status]) if Product.statuses.key?(params[:status].to_s)
        products = products.order(:position, :created_at)

        render json: products, each_serializer: ProductSerializer, status: :ok
      end

      # GET /api/v1/shops/:shop_id/products/:id
      def show
        authorize @product, :show?
        render json: @product, serializer: ProductSerializer, status: :ok
      end

      # POST /api/v1/shops/:shop_id/products
      def create
        @product = @shop.products.new(product_create_params)
        authorize @product, :create?

        if @product.save
          render json: @product, serializer: ProductSerializer, status: :created
        else
          render_validation_errors(@product)
        end
      end

      # PATCH /api/v1/shops/:shop_id/products/:id
      def update
        authorize @product, :update?

        if @product.update(product_update_params)
          render json: @product, serializer: ProductSerializer, status: :ok
        else
          render_validation_errors(@product)
        end
      end

      # DELETE /api/v1/shops/:shop_id/products/:id
      def destroy
        archive
      end

      # POST /api/v1/shops/:shop_id/products/:id/publish
      def publish
        authorize @product, :publish?

        result = Products::Publish.new(product: @product, actor_user: current_user).call
        render_lifecycle_result(result)
      end

      # POST /api/v1/shops/:shop_id/products/:id/archive
      def archive
        authorize @product, :archive?

        result = Products::Archive.new(product: @product, actor_user: current_user).call
        render_lifecycle_result(result)
      end

      # POST /api/v1/shops/:shop_id/products/:id/restore
      def restore
        authorize @product, :restore?

        result = Products::Restore.new(product: @product, actor_user: current_user).call
        render_lifecycle_result(result)
      end

      private

      def set_shop
        @shop = Shop.find(params[:shop_id])
      end

      def set_product
        @product = @shop.products.find(params[:id])
      end

      def render_lifecycle_result(result)
        if result.success?
          render json: result.product, serializer: ProductSerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      def product_create_params
        params.require(:product).permit(
          :title,
          :description,
          :price,
          :product_type,
          :product_category_id,
          :stock_quantity,
          :sku,
          :image_url
        )
      end

      def product_update_params
        params.require(:product).permit(
          :title,
          :description,
          :price,
          :product_type,
          :product_category_id,
          :position,
          :stock_quantity,
          :sku,
          :image_url
        )
      end
    end
  end
end
