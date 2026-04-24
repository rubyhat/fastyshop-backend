# frozen_string_literal: true

class CartSerializer < ActiveModel::Serializer
  attributes :id,
             :user_id,
             :shop_id,
             :status,
             :converted_at,
             :expires_at,
             :items_count,
             :items

  # @return [DateTime, nil]
  def expires_at
    object.expired_at
  end

  # @return [Array<Hash>]
  def items
    object.cart_items.map do |item|
      CartItemSerializer.new(item).as_json
    end
  end
end
