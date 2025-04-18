module Api
  module V1
    class OrdersController < BaseController
      before_action :authenticate_user!

      # /api/v1/orders/from_cart/:shop_id
      def create_from_cart
        user = current_user
        render_unauthorized unless user

        authorize Order

        cart = user&.carts&.find_by(shop_id: params[:shop_id])
        return render_error(
          key: "order.cart_not_found",
          message: "Корзина не найдена",
          code: :not_found,
          status: :not_found
        ) unless cart
         if cart.cart_items.empty?
           return render_error(
             key: "order.empty_cart",
             message: "Невозможно создать заказ с пустой корзиной",
             code: 422,
             status: :unprocessable_entity
           )
         end

        address = user&.user_addresses&.find_by(id: order_params[:user_address_id])
        return render_error(
          key: "order.user_address_not_found",
          message: "Адрес доставки пользователя не найдена",
          code: :not_found,
          status: :not_found
        ) unless address

        order = user.orders.new(
          shop_id: params[:shop_id],
          delivery_method: order_params[:delivery_method],
          payment_method: order_params[:payment_method],
          status: :created,
          contact_name: address.contact_name,
          contact_phone: address.contact_phone,
          delivery_address_text: format_full_address(address),
          delivery_comment: address.description,
          total_price: 0
        )

        cart.cart_items.each do |cart_item|
          order.order_items.build(
            product_id: cart_item.product_id,
            quantity: cart_item.quantity,
            price: cart_item.price_snapshot
          )
        end

        order.total_price = order.order_items.sum(BigDecimal("0")) { |oi| oi.quantity.to_d * oi.price }


        if order.save
          cart.destroy
          render json: order, status: :created
        else
          render_validation_errors(order)
        end
      end

      # GET /api/v1/my/orders
      def my_orders
        user = current_user
        render_unauthorized unless user

        orders = user.orders.includes(:order_items).order(created_at: :desc)
        authorize orders
        render json: orders, each_serializer: OrderSerializer, status: :ok
      end

      # GET /api/v1/shops/:shop_id/orders
      def shop_orders
        shop = Shop.find_by(id: params[:shop_id])
        return render_not_found unless shop

        authorize shop, :manage_orders?

        orders = shop.orders.includes(:order_items).order(created_at: :desc)
        render json: orders, each_serializer: OrderSerializer, status: :ok
      end


      private

      def order_params
        params.required(:order).permit(
        :user_address_id,
        :delivery_method,
        :payment_method
        )
      end

      def format_full_address(address)
        parts = [
          address.country_code,
          address.city,
          address.street,
          address.house,
          ("кв. #{address.apartment}" if address.apartment.present?)
        ]
        parts.compact.join(", ")
      end
    end
  end
end
