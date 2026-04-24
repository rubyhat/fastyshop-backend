# frozen_string_literal: true

module ShopCustomers
  class List
    CANCELED_STATUSES = [
      Order.statuses.fetch("rejected_by_seller"),
      Order.statuses.fetch("canceled_by_user"),
      Order.statuses.fetch("canceled_by_seller")
    ].freeze

    # @param shop [Shop]
    def initialize(shop:)
      @shop = shop
    end

    # @return [Array<Hash>]
    def call
      snapshots_by_user = latest_snapshot_orders.index_by(&:user_id)

      aggregates.map do |row|
        snapshot = snapshots_by_user[row.user_id]

        {
          user_id: row.user_id,
          full_name: snapshot&.customer_snapshot&.fetch("full_name", nil),
          phone: snapshot&.customer_snapshot&.fetch("phone", nil),
          email: snapshot&.customer_snapshot&.fetch("email", nil),
          orders_count: row.orders_count.to_i,
          total_spent: row.total_spent.to_s,
          last_order_at: row.last_order_at
        }
      end.sort_by { |row| row[:last_order_at] || Time.at(0) }.reverse
    end

    private

    AggregateRow = Struct.new(:user_id, :orders_count, :total_spent, :last_order_at, keyword_init: true)

    attr_reader :shop

    def orders_scope
      shop.orders
    end

    def latest_snapshot_orders
      orders_scope
        .select("DISTINCT ON (user_id) user_id, customer_snapshot, created_at")
        .order("user_id, created_at DESC")
    end

    def aggregates
      orders_scope
        .group(:user_id)
        .pluck(
          Arel.sql("user_id"),
          Arel.sql("COUNT(*)"),
          Arel.sql("SUM(CASE WHEN status IN (#{CANCELED_STATUSES.join(',')}) THEN 0 ELSE total_price END)"),
          Arel.sql("MAX(created_at)")
        )
        .map do |user_id, orders_count, total_spent, last_order_at|
          AggregateRow.new(
            user_id: user_id,
            orders_count: orders_count,
            total_spent: total_spent || 0,
            last_order_at: last_order_at
          )
        end
    end
  end
end
