# frozen_string_literal: true

class OrderSerializer < ActiveModel::Serializer
  attributes :id,
             :order_number,
             :shop_id,
             :status,
             :total_price,
             :customer_snapshot,
             :customer_comment,
             :shop_snapshot,
             :legal_profile_snapshot,
             :last_public_comment,
             :inventory_restored_at,
             :created_at,
             :updated_at

  has_many :order_items, serializer: OrderItemSerializer
end
