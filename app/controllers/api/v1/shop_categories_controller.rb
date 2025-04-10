# frozen_string_literal: true


module Api
  module V1
    class ShopCategoriesController < BaseController
      skip_before_action :authenticate_user!

      def index
        shop_categories = ShopCategory.all
        render json: shop_categories, status: :ok
      end

      def show
        shop_category = ShopCategory.find_by(id: params[:id])
        render_not_found unless shop_category
        render json: shop_category, status: :ok
      end
    end
  end
end
