# frozen_string_literal: true

class OrderItemSerializer < ActiveModel::Serializer
  attributes :product_id,
             :quantity,
             :price,
             :product_snapshot
end
