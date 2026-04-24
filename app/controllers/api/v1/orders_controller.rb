# frozen_string_literal: true

module Api
  module V1
    class OrdersController < BaseController
      # GET /api/v1/orders
      def index
        authorize Order

        orders = policy_scope(Order).includes(:order_items).order(created_at: :desc)
        orders = orders.where(status: params[:status]) if Order.statuses.key?(params[:status].to_s)
        orders = orders.where(shop_id: params[:shop_id]) if current_user.admin? && params[:shop_id].present?

        render json: orders, each_serializer: OrderListSerializer, status: :ok
      end

      # GET /api/v1/orders/:id
      def show
        order = Order.includes(:order_items).find(params[:id])
        authorize order, :show?

        render json: order, serializer: OrderSerializer, status: :ok
      end

      # GET /api/v1/orders/:id/events
      def events
        order = Order.includes(:order_events).find(params[:id])
        authorize order, :events?

        render json: order.order_events.order(created_at: :asc), each_serializer: OrderEventSerializer, status: :ok
      end

      # POST /api/v1/orders/from_cart/:shop_id
      def create_from_cart
        authorize Order, :create_from_cart?

        shop = Shop.find(params[:shop_id])
        cart = current_user.carts.active_state.find_by(shop_id: shop.id)

        result = Orders::CreateFromCart.new(
          user: current_user,
          shop: shop,
          cart: cart,
          idempotency_key: request.headers["Idempotency-Key"],
          contact_name: order_create_params[:contact_name],
          contact_phone: order_create_params[:contact_phone],
          customer_comment: order_create_params[:customer_comment]
        ).call

        if result.success?
          render json: {
            order: OrderSerializer.new(result.order).as_json,
            checkout_summary: result.checkout_summary,
            cart: result.cart_payload
          }, status: result.replayed ? :ok : :created
        elsif result.error_record
          render_validation_errors(result.error_record)
        else
          render_error(
            key: result.error_key,
            message: result.error_message,
            code: Rack::Utils.status_code(result.error_status),
            status: result.error_status
          )
        end
      end

      # GET /api/v1/my/orders
      def my_orders
        authorize Order, :my_orders?

        orders = current_user.orders.includes(:order_items).order(created_at: :desc)
        orders = orders.where(status: params[:status]) if Order.statuses.key?(params[:status].to_s)

        render json: orders, each_serializer: OrderListSerializer, status: :ok
      end

      # GET /api/v1/shops/:shop_id/orders
      def shop_orders
        shop = Shop.find(params[:shop_id])
        authorize shop, :manage_orders?

        orders = shop.orders.includes(:order_items).order(created_at: :desc)
        orders = orders.where(status: params[:status]) if Order.statuses.key?(params[:status].to_s)

        render json: orders, each_serializer: OrderListSerializer, status: :ok
      end

      # PATCH /api/v1/orders/:id/status
      def update_status
        order = Order.find(params[:id])
        authorize order, :update_status?

        result = Orders::ChangeStatus.new(
          order: order,
          actor_user: current_user,
          new_status: order_update_status_params[:status],
          comment: order_update_status_params[:comment]
        ).call

        if result.success?
          render json: result.order, serializer: OrderSerializer, status: :ok
        else
          render_validation_errors(result.error_record)
        end
      end

      private

      def order_create_params
        params.fetch(:order, {}).permit(:contact_name, :contact_phone, :customer_comment)
      end

      def order_update_status_params
        params.require(:order).permit(:status, :comment)
      end
    end
  end
end
