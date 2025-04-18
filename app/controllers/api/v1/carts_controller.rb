# frozen_string_literal: true

module Api
  module V1
    class CartsController < BaseController
      before_action :authenticate_user!

      # Получить все активные корзины текущего пользователя
      def index
        carts = policy_scope(Cart).active.includes(:cart_items)
        render json: carts, each_serializer: CartSerializer, status: :ok
      end

      # Получить содержимое корзины по магазину
      def show
        cart = find_or_initialize_cart
        return render_error(
          key: "cart.cart_not_exists",
          message: "Корзина не найдена",
          code: :not_found,
          status: :not_found
        ) unless cart

        authorize cart
        render json: cart, serializer: CartSerializer, status: :ok
      end

      # Добавить товар в корзину
      def add_item
        cart = find_or_initialize_cart
        return render_error(
          key: "cart.cart_not_exists",
          message: "Корзина не найдена",
          code: :not_found,
          status: :not_found
        ) unless cart

        authorize cart

        data = cart_params
        product = Product.find(data[:product_id])

        if product.shop_id != cart.shop_id
          return render_error(
            key: "cart.add_item_error",
            message: "Товар не принадлежит указанному магазину",
            code: :unprocessable_entity,
            status: :unprocessable_entity
          )
        end

        quantity_to_add = data[:quantity].to_i

        if quantity_to_add <= 0 || quantity_to_add > 100
          return render_error(
            key: "cart.invalid_quantity",
            message: "Количество товара должно быть от 1 до 100",
            code: :unprocessable_entity,
            status: :unprocessable_entity
          )
        end

        unless cart.persisted?
          return render_validation_errors(cart) unless cart.save
        end

        cart_item = cart.cart_items.find_or_initialize_by(product: product)
        cart_item.quantity ||= 0

        if cart_item.quantity + quantity_to_add > product.stock_quantity
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
          render json: cart, serializer: CartSerializer, status: :created
        else
          render_validation_errors(cart_item)
        end
      end

      # Удалить товар из корзины
      def remove_item
        cart = find_or_initialize_cart

        return render_error(
          key: "cart.cart_not_exists",
          message: "Корзина не найдена",
          code: :not_found,
          status: :not_found
        ) unless cart

        authorize cart

        data = cart_params
        product = Product.find(data[:product_id])
        cart_item = cart.cart_items.find_by(product_id: product.id)
        return render_error(
          key: "cart_item.cart_item_not_exists_in_cart",
          message: "Товар не найден в корзине",
          code: :not_found,
          status: :not_found
        ) unless cart_item

        quantity_to_remove = data[:quantity].to_i

        if quantity_to_remove <= 0 || quantity_to_remove > 100
          return render_error(
            key: "cart.invalid_quantity",
            message: "Количество для удаления должно быть от 1 до 100",
            code: :unprocessable_entity,
            status: :unprocessable_entity
          )
        end

        if cart_item.quantity <= quantity_to_remove
          cart_item.destroy
        else
          cart_item.quantity -= quantity_to_remove
          return render_validation_errors(cart_item) unless cart_item.save
        end

        render json: cart, serializer: CartSerializer, status: :ok
      end

      private

      def cart_params
        params.require(:cart).permit(:product_id, :quantity)
      end

      def find_or_initialize_cart
        user = current_user
        return render_unauthorized unless user

        Cart.find_or_initialize_by(user_id: user.id, shop_id: params[:shop_id]).tap do |cart|
          cart.expired_at ||= 30.days.from_now
        end
      end
    end
  end
end
