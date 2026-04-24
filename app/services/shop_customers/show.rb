# frozen_string_literal: true

module ShopCustomers
  class Show
    # @param shop [Shop]
    # @param user_id [String]
    def initialize(shop:, user_id:)
      @shop = shop
      @user_id = user_id
    end

    # @return [Hash, nil]
    def call
      orders = shop.orders.where(user_id: user_id).order(created_at: :desc)
      return nil if orders.empty?

      latest_order = orders.first
      summary = ShopCustomers::List.new(shop: shop).call.find { |row| row[:user_id] == user_id }

      {
        user_id: user_id,
        full_name: latest_order.customer_snapshot["full_name"],
        phone: latest_order.customer_snapshot["phone"],
        email: latest_order.customer_snapshot["email"],
        orders_count: summary[:orders_count],
        total_spent: summary[:total_spent],
        last_order_at: summary[:last_order_at],
        orders: orders
      }
    end

    private

    attr_reader :shop, :user_id
  end
end
