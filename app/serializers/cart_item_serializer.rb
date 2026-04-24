# frozen_string_literal: true

class CartItemSerializer < ActiveModel::Serializer
  attributes :id,
             :product_id,
             :quantity,
             :price_snapshot,
             :current_price,
             :price_changed,
             :availability,
             :unavailable_reason,
             :product

  # @return [String]
  def current_price
    object.current_price.to_s
  end

  # @return [Boolean]
  def price_changed
    object.price_changed?
  end

  # @return [String]
  def availability
    object.availability
  end

  # @return [Hash, nil]
  def unavailable_reason
    object.checkout_unavailable_reason
  end

  # @return [Hash]
  def product
    ProductCompactSerializer.new(object.product).as_json
  end
end
