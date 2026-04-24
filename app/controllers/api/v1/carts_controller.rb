# frozen_string_literal: true

module Api
  module V1
    class CartsController < BaseController
      # GET /api/v1/carts
      def index
        carts = policy_scope(Cart).active_state.includes(cart_items: :product)
        render json: carts, each_serializer: CartSerializer, status: :ok
      end

      # GET /api/v1/carts/:shop_id
      def show
        cart = find_or_build_active_cart
        authorize cart

        render json: cart, serializer: CartSerializer, status: :ok
      end

      # POST /api/v1/carts/:shop_id/add
      def add_item
        cart = find_or_build_active_cart
        authorize cart, :add_item?

        product = Product.find(cart_params[:product_id])
        return render_wrong_shop_product unless product.shop_id == cart.shop_id
        return render_self_purchase_error if product.shop.seller_profile.user_id == current_user.id
        return render_unavailable_product(product) unless product.available_for_cart?

        quantity_to_add = cart_params[:quantity].to_i
        return render_invalid_quantity if quantity_to_add <= 0 || quantity_to_add > 100

        return render_validation_errors(cart) unless cart.persisted? || cart.save

        cart_item = cart.cart_items.find_or_initialize_by(product: product)
        cart_item.quantity ||= 0

        if product.physical? && cart_item.quantity + quantity_to_add > product.stock_quantity
          return render_error(
            key: "cart.insufficient_stock",
            message: "Недостаточно товара на складе. Доступно: #{[ product.stock_quantity - cart_item.quantity, 0 ].max}",
            code: :unprocessable_entity,
            status: :unprocessable_entity
          )
        end

        cart_item.quantity += quantity_to_add
        cart_item.price_snapshot = product.price

        if cart_item.save
          render json: cart.reload, serializer: CartSerializer, status: :created
        else
          render_validation_errors(cart_item)
        end
      end

      # POST /api/v1/carts/:shop_id/remove/:product_id
      def remove_item
        cart = current_user.carts.active_state.find_by(shop_id: params[:shop_id])
        return render_not_found("Корзина не найдена", "cart.cart_not_exists") unless cart

        authorize cart, :remove_item?

        cart_item = cart.cart_items.find_by(product_id: cart_params[:product_id])
        return render_not_found("Товар не найден в корзине", "cart_item.cart_item_not_exists_in_cart") unless cart_item

        quantity_to_remove = cart_params[:quantity].to_i
        return render_invalid_quantity unless quantity_to_remove.positive? && quantity_to_remove <= 100

        if cart_item.quantity <= quantity_to_remove
          cart_item.destroy
        else
          cart_item.quantity -= quantity_to_remove
          return render_validation_errors(cart_item) unless cart_item.save
        end

        render json: cart.reload, serializer: CartSerializer, status: :ok
      end

      private

      def cart_params
        params.require(:cart).permit(:product_id, :quantity)
      end

      def find_or_build_active_cart
        current_user.carts.active_state.find_by(shop_id: params[:shop_id]) || current_user.carts.new(
          shop_id: params[:shop_id],
          status: :active
        )
      end

      def render_wrong_shop_product
        render_error(
          key: "cart.add_item_error",
          message: "Товар не принадлежит указанному магазину",
          code: :unprocessable_entity,
          status: :unprocessable_entity
        )
      end

      def render_self_purchase_error
        render_error(
          key: "cart.self_purchase_forbidden",
          message: "Нельзя добавить товары из собственного магазина",
          code: :unprocessable_entity,
          status: :unprocessable_entity
        )
      end

      def render_unavailable_product(product)
        render_error(
          key: "cart.product_unavailable",
          message: product.unavailable_reason[:message],
          code: :unprocessable_entity,
          status: :unprocessable_entity
        )
      end

      def render_invalid_quantity
        render_error(
          key: "cart.invalid_quantity",
          message: "Количество товара должно быть от 1 до 100",
          code: :unprocessable_entity,
          status: :unprocessable_entity
        )
      end
    end
  end
end
