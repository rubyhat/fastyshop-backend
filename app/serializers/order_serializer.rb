# frozen_string_literal: true

class OrderSerializer < ActiveModel::Serializer
  attributes :id, :status, :delivery_method, :payment_method,
             :contact_name, :contact_phone, :delivery_address_text,
             :delivery_comment, :status_comment, :total_price, :created_at

  has_many :order_items, serializer: OrderItemSerializer
end
