# frozen_string_literal: true

module Api
  module V1
    class ShopCustomersController < BaseController
      # GET /api/v1/shops/:shop_id/customers
      def index
        shop = Shop.find(params[:shop_id])
        authorize shop, :manage_orders?

        render json: ShopCustomers::List.new(shop: shop).call, status: :ok
      end

      # GET /api/v1/shops/:shop_id/customers/:user_id
      def show
        shop = Shop.find(params[:shop_id])
        authorize shop, :manage_orders?

        result = ShopCustomers::Show.new(shop: shop, user_id: params[:user_id]).call
        return render_not_found("Покупатель не найден", "shop_customer.not_found") unless result

        render json: result.merge(
          orders: ActiveModelSerializers::SerializableResource.new(
            result[:orders],
            each_serializer: OrderListSerializer
          ).as_json
        ), status: :ok
      end
    end
  end
end
