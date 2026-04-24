# frozen_string_literal: true

module Orders
  class CreateFromCart
    class BusinessRuleError < StandardError
      attr_reader :key, :status

      def initialize(key:, message:, status:)
        super(message)
        @key = key
        @status = status
      end
    end

    Result = Struct.new(
      :order,
      :checkout_summary,
      :cart_payload,
      :error_key,
      :error_message,
      :error_status,
      :error_record,
      :replayed,
      keyword_init: true
    ) do
      def success?
        error_key.nil? && error_record.nil?
      end
    end

    # @param user [User]
    # @param shop [Shop]
    # @param cart [Cart, nil]
    # @param idempotency_key [String, nil]
    # @param contact_name [String, nil]
    # @param contact_phone [String, nil]
    # @param customer_comment [String, nil]
    def initialize(user:, shop:, cart:, idempotency_key:, contact_name:, contact_phone:, customer_comment:)
      @user = user
      @shop = shop
      @cart = cart
      @idempotency_key = idempotency_key.to_s.strip.presence
      @contact_name = contact_name
      @contact_phone = contact_phone
      @customer_comment = customer_comment.to_s.strip.presence
    end

    # @return [Result]
    def call
      return replay_result if replayable_order.present?
      return business_error("order.cart_not_found", "Корзина не найдена", :not_found) unless cart
      return business_error("order.shop_not_active", "Магазин временно не принимает заказы", :unprocessable_content) unless shop.active?
      return business_error("order.self_purchase_forbidden", "Нельзя оформить заказ в собственном магазине", :unprocessable_content) if self_purchase?
      return business_error("order.empty_cart", "Невозможно создать заказ с пустой корзиной", :unprocessable_content) if cart.cart_items.empty?

      result = nil

      ActiveRecord::Base.transaction do
        lock_shop!
        prepared_items = prepared_items_for_checkout
        valid_items = prepared_items.select { |item| item[:unavailable_reason].nil? }
        skipped_items = prepared_items.reject { |item| item[:unavailable_reason].nil? }

        if valid_items.empty?
          raise_business_error("order.no_valid_items", "В корзине нет доступных товаров для оформления", :unprocessable_content)
        end

        order = build_order(valid_items)
        order.save!
        decrement_inventory!(valid_items)
        remove_ordered_items!(valid_items)
        update_cart_status!

        checkout_summary = {
          ordered_items: build_ordered_items_summary(valid_items),
          skipped_items: build_skipped_items_summary(skipped_items),
          price_changed_items: build_price_changed_items_summary(prepared_items)
        }

        cart_payload = build_cart_payload

        order.record_event!(
          event_type: :created,
          actor_user: user,
          from_status: nil,
          to_status: :created,
          metadata: {
            checkout_summary: checkout_summary,
            cart: cart_payload
          }
        )

        result = Result.new(
          order: order,
          checkout_summary: checkout_summary,
          cart_payload: cart_payload,
          replayed: false
        )
      end

      result
    rescue ActiveRecord::RecordInvalid => e
      Result.new(error_record: e.record)
    rescue ActiveRecord::RecordNotUnique
      replay_result || business_error("order.idempotency_conflict", "Не удалось безопасно повторить оформление заказа", :conflict)
    rescue BusinessRuleError => e
      business_error(e.key, e.message, e.status)
    end

    private

    attr_reader :user, :shop, :cart, :idempotency_key, :contact_name, :contact_phone, :customer_comment

    def replay_result
      order = replayable_order
      return unless order

      created_event = order.order_events.created.order(:created_at).first
      metadata = created_event&.metadata || {}

      Result.new(
        order: order,
        checkout_summary: metadata["checkout_summary"] || {},
        cart_payload: metadata["cart"] || {},
        replayed: true
      )
    end

    def replayable_order
      return nil unless idempotency_key

      @replayable_order ||= user.orders.includes(:order_items, :order_events).find_by(
        shop_id: shop.id,
        checkout_idempotency_key: idempotency_key
      )
    end

    def self_purchase?
      shop.seller_profile.user_id == user.id
    end

    def lock_shop!
      shop.lock!
      raise_business_error("order.shop_not_active", "Магазин временно не принимает заказы", :unprocessable_content) unless shop.active?
    end

    def prepared_items_for_checkout
      cart_items = cart.cart_items.order(:created_at).to_a
      locked_products = Product.where(id: cart_items.map(&:product_id).uniq).order(:id).lock.index_by(&:id)

      cart_items.map do |cart_item|
        product = locked_products.fetch(cart_item.product_id)
        unavailable_reason = unavailable_reason_for(product: product, quantity: cart_item.quantity)

        {
          cart_item: cart_item,
          product: product,
          quantity: cart_item.quantity,
          old_price: cart_item.price_snapshot,
          current_price: product.price,
          price_changed: cart_item.price_snapshot != product.price,
          unavailable_reason: unavailable_reason
        }
      end
    end

    def unavailable_reason_for(product:, quantity:)
      return { key: "cart.item.product_unavailable", message: "Товар больше недоступен" } unless product.published? && shop.active?
      return nil unless product.physical?
      return nil if quantity <= product.stock_quantity

      { key: "cart.item.out_of_stock", message: "Недостаточно товара на складе" }
    end

    def build_order(valid_items)
      order = user.orders.new(
        shop: shop,
        status: :created,
        order_number: Orders::AllocateNumber.new(shop: shop).call,
        customer_snapshot: Orders::CustomerSnapshot.new(
          user: user,
          contact_name: contact_name,
          contact_phone: contact_phone
        ).call,
        customer_comment: customer_comment,
        checkout_idempotency_key: idempotency_key,
        total_price: 0
      )

      valid_items.each do |item|
        order.order_items.build(
          product: item[:product],
          quantity: item[:quantity],
          price: item[:current_price]
        )
      end

      order.total_price = order.order_items.sum(BigDecimal("0")) do |order_item|
        order_item.quantity.to_d * order_item.price
      end

      order
    end

    def decrement_inventory!(valid_items)
      valid_items.each do |item|
        next unless item[:product].physical?

        item[:product].decrement!(:stock_quantity, item[:quantity])
      end
    end

    def remove_ordered_items!(valid_items)
      cart.cart_items.where(id: valid_items.map { |item| item[:cart_item].id }).destroy_all
    end

    def update_cart_status!
      cart.reload
      return unless cart.empty?

      cart.mark_converted!
    end

    def build_ordered_items_summary(valid_items)
      valid_items.map do |item|
        {
          product_id: item[:product].id,
          quantity: item[:quantity]
        }
      end
    end

    def build_skipped_items_summary(skipped_items)
      skipped_items.map do |item|
        {
          product_id: item[:product].id,
          reason_key: item[:unavailable_reason][:key],
          message: item[:unavailable_reason][:message]
        }
      end
    end

    def build_price_changed_items_summary(prepared_items)
      prepared_items.select { |item| item[:price_changed] }.map do |item|
        {
          product_id: item[:product].id,
          old_price: item[:old_price].to_s,
          current_price: item[:current_price].to_s
        }
      end
    end

    def build_cart_payload
      cart.reload

      {
        id: cart.id,
        status: cart.status,
        items_count: cart.items_count
      }
    end

    def raise_business_error(key, message, status)
      raise BusinessRuleError.new(key: key, message: message, status: status)
    end

    def business_error(key, message, status)
      Result.new(
        error_key: key,
        error_message: message,
        error_status: status
      )
    end
  end
end
