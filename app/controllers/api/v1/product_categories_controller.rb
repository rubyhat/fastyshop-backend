# frozen_string_literal: true

module Api
  module V1
    class ProductCategoriesController < BaseController
      before_action :set_shop
      before_action :set_product_category, only: %i[show update destroy publish archive_preview archive restore]

      # GET /api/v1/shops/:shop_id/product_categories
      def index
        authorize ProductCategory.new(shop: @shop), :index?

        categories = policy_scope(@shop.product_categories.includes(:children))
        categories = categories.where(status: params[:status]) if ProductCategory.statuses.key?(params[:status].to_s)
        categories = categories.order(:position, :created_at)

        render json: categories, each_serializer: ProductCategorySerializer, status: :ok
      end

      # GET /api/v1/shops/:shop_id/product_categories/:id
      def show
        authorize @product_category
        render json: @product_category, serializer: ProductCategorySerializer, status: :ok
      end

      # POST /api/v1/shops/:shop_id/product_categories
      def create
        @product_category = @shop.product_categories.new(product_category_params)
        authorize @product_category

        if @product_category.save
          render json: @product_category, serializer: ProductCategorySerializer, status: :created
        else
          render_validation_errors(@product_category)
        end
      end

      # PATCH /api/v1/shops/:shop_id/product_categories/:id
      def update
        authorize @product_category

        if @product_category.update(product_category_params_for_update)
          render json: @product_category, serializer: ProductCategorySerializer, status: :ok
        else
          render_validation_errors(@product_category)
        end
      end

      # DELETE /api/v1/shops/:shop_id/product_categories/:id
      def destroy
        archive
      end

      # POST /api/v1/shops/:shop_id/product_categories/:id/publish
      def publish
        authorize @product_category, :publish?

        result = ProductCategories::Publish.new(
          category: @product_category,
          actor_user: current_user
        ).call

        render_lifecycle_result(result)
      end

      # POST /api/v1/shops/:shop_id/product_categories/:id/archive_preview
      def archive_preview
        authorize @product_category, :archive_preview?

        render json: ProductCategories::ArchivePreview.new(category: @product_category).call, status: :ok
      end

      # POST /api/v1/shops/:shop_id/product_categories/:id/archive
      def archive
        authorize @product_category, :archive?

        result = ProductCategories::Archive.new(
          category: @product_category,
          actor_user: current_user
        ).call

        if result.success?
          render json: ProductCategorySerializer.new(result.category).as_json.merge(affected: result.preview[:affected]), status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      # POST /api/v1/shops/:shop_id/product_categories/:id/restore
      def restore
        authorize @product_category, :restore?

        result = ProductCategories::Restore.new(
          category: @product_category,
          actor_user: current_user
        ).call

        render_lifecycle_result(result)
      end

      # POST /api/v1/shops/:shop_id/product_categories/reorder
      def reorder
        record = ProductCategory.new(shop: @shop)
        authorize record, :reorder?

        result = ProductCategories::Reorder.new(
          shop: @shop,
          positions: reorder_params[:positions]
        ).call

        if result.success?
          render json: result.categories, each_serializer: ProductCategorySerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      private

      def set_shop
        @shop = Shop.find(params[:shop_id])
      end

      def set_product_category
        @product_category = @shop.product_categories.find(params[:id])
      end

      def render_lifecycle_result(result)
        if result.success?
          render json: result.category, serializer: ProductCategorySerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      def product_category_params
        params.require(:product_category).permit(:title, :parent_id, :position)
      end

      def product_category_params_for_update
        params.require(:product_category).permit(:title, :parent_id, :position)
      end

      def reorder_params
        params.permit(positions: %i[id position])
      end
    end
  end
end
