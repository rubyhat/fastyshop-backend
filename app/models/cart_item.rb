# frozen_string_literal: true

class CartItem < ApplicationRecord
  belongs_to :product
  belongs_to :cart

  validates :cart_id, :product_id, :quantity, :price_snapshot, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :product_id, uniqueness: { scope: :cart_id }

  validate :product_belongs_to_same_shop
  validate :not_exceed_stock_quantity, if: -> { product&.physical? && quantity.present? }

  # @return [String]
  def availability
    product.availability
  end

  # @return [BigDecimal]
  def current_price
    product.price
  end

  # @return [Boolean]
  def price_changed?
    price_snapshot != current_price
  end

  # @return [Boolean]
  def available_for_checkout?
    return false unless product.available_for_cart?
    return true unless product.physical?

    quantity <= product.stock_quantity
  end

  # @return [Hash, nil]
  def checkout_unavailable_reason
    return product.unavailable_reason unless product.available_for_cart?

    return nil unless product.physical? && quantity > product.stock_quantity

    {
      key: "cart.item.out_of_stock",
      message: "Недостаточно товара на складе"
    }
  end

  private

  def product_belongs_to_same_shop
    return unless cart && product

    if cart.shop_id != product.shop_id
      errors.add(:product_id, "Товар не принадлежит магазину корзины")
    end
  end

  def not_exceed_stock_quantity
    existing_item = CartItem.where(cart_id: cart_id, product_id: product_id).where.not(id: id).first
    total_quantity = quantity
    total_quantity += existing_item.quantity if existing_item.present?

    if total_quantity > product.stock_quantity
      errors.add(:quantity, "Недостаточно товара на складе. Доступно: #{product.stock_quantity}")
    end
  end
end
