# frozen_string_literal: true

class OrderListSerializer < ActiveModel::Serializer
  attributes :id,
             :order_number,
             :shop_id,
             :status,
             :total_price,
             :last_public_comment,
             :created_at
end
